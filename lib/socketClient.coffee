socketio = require 'socket.io-client'
events = require 'events'
types = require './types'

module.exports =
  class Client extends events.EventEmitter
    socket:     undefined
    active:     false
    host:       undefined
    port:       undefined
    netData:    ""

    constructor: (@host) ->
      @socket = socketio @host

      @socket.on 'connect', =>
        console.log "connect"
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