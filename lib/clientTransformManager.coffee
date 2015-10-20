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

    constructor: (@host, @username, @color) ->
      @net = new netClient @host

      # TODO outsource this to types
      @net.on types.connected,    @connectedToServer
      @net.on 'transform',        @handleTransform
      @net.on types.acknowledge,  @acknowledge
      @net.on 'error',            @handleError
      @net.on 'end',              @handleEnd
      @net.on 'serverDown',       @handleServerDown

    connectedToServer: =>
      @sendToServer
        type:     types.connecting
        username: @username
        color:    @color

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
        when types.clientDisconnected
          @clientLeft transform
        when types.initialize
          @initialize transform
        when types.acknowledge
          @acknowledge transform

    handleError: (err) =>
      @emit 'error', err

    handleEnd: =>
      @emit 'end'

    handleServerDown: ->
      #TODO implement + fat arrow

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
          color:    client.color
      initialized = true
      @emit types.initialized

    acknowledge: (ack) =>
      for i in [0...@notAcked.length]
        if @notAcked[i].state[@id] is ack[@id]
          index = i
          break

      if index isnt -1
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

    changeText: (transform) ->
      @state.set transform.id, transform.state.get transform.id
      @emit types.textChange, transform

    updateCursor: (transform) ->
      @emit types.updateCursor, transform

    changeSelection: (transform) ->
      @emit types.selectionChanged, transform

    newClient: (transform) ->
      @clients.push transform.client
      @state.add transform.client.id
      @emit types.newUser,
        clientId:   transform.client.id
        color:      transform.client.color

    clientLeft: (transform) ->
      console.log "Client left"
      @emit types.userLeft,
        clientId: transform.client.id