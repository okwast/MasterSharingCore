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

    constructor: (port) ->
      @server           = new netServer port
      @conflictManager  = new conflictManager()
      @state            = new State()

      @server.on    'initial',              @clientConnected
      @server.on    'clientConnected',      @clientConnected
      @server.on    'clientDisconnected',   @clientDisconnected
      @server.on    'transform',            @transformRecieved
      @server.on    'error',                console.log

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