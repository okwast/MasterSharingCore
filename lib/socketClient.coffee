socketio = require 'socket.io-client'
events = require 'events'
types = require './types'

# This class creates an Socket.IO client and connects to the server.
module.exports =
  class Client extends events.EventEmitter
    socket:     undefined
    active:     false
    host:       undefined
    port:       undefined
    netData:    ""

    # Creates a Socket.IO-Client and connects to the
    # server at the given address
    # Also emits the following events
    # 1. connected
    # 2. end
    # 3. transform
    # 4. serverDown
    # 5. error
    constructor: (@host) ->
      @socket = socketio @host, {reconnection: false}

      @socket.on 'connect', =>
        @emit types.connected

      @socket.on 'data', (transform) =>
        if transform.type is 'end'
          @emit 'end'
        else
          @emit 'transform', transform

      @socket.on 'error', (err) =>
        @socket.disconnect()
        @active = false
        @emit 'error', err

      @socket.on 'end', =>
        @socket.disconnect()
        @active = false
        @emit 'serverDown'

    disconnect: ->
      @socket.disconnect()
      @active = false

    send: (obj) ->
      @socket.emit 'data', obj