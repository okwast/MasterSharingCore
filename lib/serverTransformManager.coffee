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

    # Constructs a transform manager for the server
    # It gets the port and creates an socket server for that port
    # Also registers for events of the socket server
    constructor: (port) ->
      @server           = new netServer port
      @conflictManager  = new conflictManager()
      @state            = new State()

      @server.on    'initial',                  @clientConnected
      @server.on    'clientConnected',          @clientConnected
      @server.on    types.clientDisconnected,   @clientDisconnected
      @server.on    'transform',                @transformRecieved
      @server.on    'error',                    console.log

    # Gets called, when a clients connects
    # Inserts the client into the current state vector
    # Sends the client his id, the current state and the history
    # If it is not a simple client, the other clients get notified
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

    # Removes the client from the state vector
    # and notifies other clients
    clientDisconnected: (client) =>
      console.log 'clientDisconnected - serverTransformManager'
      @server.sendToAllClients @clients,
        type:     types.userLeft
        clientId: client

    # Handles incomming transforms
    # Creates a state of the state list
    # Checks for conflicts and solves them
    # Notifies other clients
    # Sends an acknowledge to the client
    transformRecieved: (client, transform) =>
      transform.state = new State transform.state

      if transform.type is types.textChange
        conflicts = @conflictManager.getConflictingTransforms @history,
        client, transform
        if conflicts? and conflicts.length > 0
          @conflictManager.handleConflicts conflicts, transform

        transform.state = transform.state.list
        @history.push transform

        @server.sendToClient client,
          type:  types.acknowledge
          state: transform.state

      @server.sendToOtherClients @clients, client, transform