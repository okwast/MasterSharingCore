netClient = require './socketClient'
events = require 'events'
types = require './types'
State = require './state'

# This is the client version of the transform manager.
# It creates an socket connection to the server and
# registers callbacks for events.
#
module.exports =
  class ClientTransformManager extends events.EventEmitter
    initialized:  false
    net:          undefined
    id:           undefined
    clients:      undefined
    notAcked:     []
    history:      undefined
    state:        undefined
    username:     undefined
    color:        undefined

    # Registers callbacks for events
    constructor: (@host, @username, @color) ->
      @net = new netClient @host

      @net.on types.connected,        @connectedToServer
      @net.on types.transform,        @handleTransform
      @net.on types.acknowledge,      @acknowledge
      @net.on types.error,            @handleError
      @net.on types.end,              @handleEnd
      @net.on types.serverDown,       @handleServerDown

    # Logically register as sharing client
    connectedToServer: =>
      @sendToServer
        type:     types.connecting
        username: @username
        color:    @color

    # Send a message to the server and manage the state.
    # If the connection is initialized, there is no state to update.
    sendToServer: (transform) =>
      @state.inc @id if @state? and transform.type isnt types.connect
      transform.id = @id
      @notAcked.push transform if @state? and transform.type isnt types.connect
      transform.state = @state.list if @state?
      @net.send transform

    # Handles an incoming transform
    # For each type there is an individual function
    handleTransform: (transform) =>
      transform.state = new State transform.state
      switch transform.type
        when types.updateCursor
          @updateCursor transform
        when types.textChange
          @changeText transform
        when types.selectionChanged
          @changeSelection transform
        when types.clientConnected
          @newClient transform
        when types.userLeft
          @clientLeft transform
        when types.initialize
          @initialize transform
        when types.acknowledge
          @acknowledge transform

    handleError: (err) =>
      @emit 'error', err

    handleEnd: =>
      @emit 'end'

    handleServerDown: =>
      @emit 'error', 'Server down'

    # The server has send information for initialization.
    # The state and the client id have been send and will be set.
    # For each client already sharing a new cursor is created.
    # Emit an event for signaling the connection is established.
    initialize: (transform) =>
      @emit types.clear
      @id       = transform.clientId
      @clients  = transform.clients
      @state    = transform.state
      @history  = transform.history
      @handleTransform t for t in @history
      for client in @clients
        @emit types.newUser,
          clientId: client.id
          username: client.username
          color:    client.color
      initialized = true
      @emit types.initialized

    # Manage acknowledges
    acknowledge: (ack) =>
      for i in [0...@notAcked.length]
        if @notAcked[i].state[@id] is ack[@id]
          index = i
          break

      if index? and index isnt -1
        t = @notAcked.splice(index, 1)
        t = t[0]
        t.state = ack
        @history.push t

    textChanged: (transform) ->
      @sendToServer transform

    cursorChanged: (transform) ->
      @sendToServer transform

    selectionChanged: (transform) ->
      @sendToServer transform

    # An textChange event has been sent by the server.
    # The text needs to be changed now.
    changeText: (transform) ->
      @state.set transform.id, transform.state.get transform.id
      @emit types.textChange, transform

    # Update the cursor of a client.
    updateCursor: (transform) ->
      @emit types.updateCursor, transform

    # Update the selection of a client.
    changeSelection: (transform) ->
      @emit types.selectionChanged, transform

    # A new client has connected
    newClient: (transform) ->
      @clients.push transform.client
      @state.add transform.client.id
      @emit types.newUser,
        clientId:   transform.client.id
        username:   transform.client.username
        color:      transform.client.color

    # A client left the session
    clientLeft: (transform) ->
      @emit types.userLeft,
        clientId: transform.client.id