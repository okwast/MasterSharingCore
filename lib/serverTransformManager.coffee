netServer = require './socketServer'
events = require 'events'
types = require './types'
conflictManager = require './conflictManager'
State = require './state'

module.exports =
  class ServerTransformManager extends events.EventEmitter
    standalone:       undefined
    server:           undefined
    conflictManager:  undefined
    initialClient:    undefined
    clients:          []
    state:            undefined
    history:          []

    constructor: (@standalone, port) ->
      @server           = new netServer port
      @conflictManager  = new conflictManager()
      @state            = new State()

      if @standalone
        @server.on  'initial',              @initial
      else
        @server.on  'initial',              @clientConnected
      @server.on    'clientConnected',      @clientConnected
      @server.on    'clientDisconnected',   @clientDisconnected
      @server.on    'transform',            @transformRecieved
      @server.on    'error',                console.log

    initial: (client) ->
      # console.log "Initial"

    clientConnected: (client) =>
      tmpClients = []
      for c in @clients
        tmpClients.push
          id:     c.id
          color:  c.color
          cursor:
            pos:  c.cursor.pos
      @state.add client.id
      @server.sendToClient client,
        type:       types.initialize
        clientId:   client.id
        state:      @state.list
        history:    @history
        clients:    tmpClients

      console.log 'client'
      console.log client
      if client.clientType isnt 'simple' and client.username isnt 'browser'
        @server.sendToOtherClients @clients, client,
          type:     types.clientConnected
          client: {id: client.id, color: client.color}
      @clients.push client

    clientDisconnected: (client) =>
      i = @clients.indexOf(client)
      @clients.splice i, 1 unless i is -1
      @state.remove client.id
      @server.sendToAllClients @clients,
        type:     types.clientDisconnected
        clientId: client.id

    # # TODO: check wether the state is really allowed
    # checkState: (state, client, clientState) ->
    #   # return false if state.length != clientState.length
    #
    #   for i in [0..(clientState.length)]
    #     if state[i] > clientState[i]
    #       # if !(i == client.id && state[i] + 1 == clientState[i])
    #       return false
    #   return true

    getConflictingTransforms: (client, transform) =>
      # console.log 1
      return [] if @history.length <= 0
      # console.log 2
      newTranforms = []
      for i in [@history.length - 1..0]
        # console.log 3
        t = @history[i]
        # console.log 4
        st = new State t.state
        # console.log 5
        if transform.state.happendBefore st
          console.log "transform.state happendBefore st"
          console.log transform.state
          console.log st
          newTranforms.push t
        # console.log 6
      # console.log 7
      return newTranforms

    transformRecieved: (client, transform) =>
      transform.state = new State transform.state
      # console.log "transformRecieved"
      # console.log transform
      if transform.type is types.textChange
        conflicts = @getConflictingTransforms client, transform
        if conflicts? and conflicts.length > 0
          console.log "Conflicts"
          console.log conflicts
          console.log transform
          console.log @history
          @conflictManager.handleConflicts conflicts, transform

        transform.state = transform.state.list
        @history.push transform

        @server.sendToClient client,
          type:  types.acknowledge
          state: transform

      @server.sendToOtherClients @clients, client, transform