events = require 'events'
http = require 'http'
fs = require 'fs'
socketio = require 'socket.io'
types = require './types'

module.exports =
  class Server extends events.EventEmitter
    initial:    false
    server:     undefined
    io:         undefined
    clientId:   0
    port:       undefined
    netData:    ""
    sockets:    []

    constructor: (@port) ->

      @server = http.createServer (req, res) ->
        console.log 'Connection'
        res.writeHead 200, {'Content-Type': 'text/html'}
        if req.url is '/'
          fs.readFile "#{__dirname}/../browser/index.html", (err, data) ->
            res.write data, 'utf8'
            res.end()
        if req.url is '/codemirror.css'
          path =
            "#{__dirname}/../bower_components/codemirror/lib/codemirror.css"
          fs.readFile path, (err, data) ->
            res.write data, 'utf8'
            res.end()
        if req.url is '/codemirror.js'
          path =
            "#{__dirname}/../bower_components/codemirror/lib/codemirror.js"
          fs.readFile path, (err, data) ->
            res.write data, 'utf8'
            res.end()

      @server.listen @port

      @io = socketio @server
      @io.on 'connection', (socket) =>
        console.log "a ws connection"
        @sockets.push socket
        console.log @sockets

        socket.on 'error', (err) ->
          console.log err

        socket.on 'data', (transform) =>
          switch transform.type
            when types.connecting
              console.log "connecting"
              socket.id         = @clientId++
              socket.username   = transform.username
              socket.color      = transform.color
              socket.cursor     = {}
              socket.cursor.pos = {row: 0, column: 0}
              if !@initial
                @emit 'initial', socket
                @initial = true
              else
                @emit 'clientConnected', socket
            else
              console.log "transform"
              @emit('transform', socket, transform)

    sendToClient: (socket, data) ->
      if data.state? and data.state.list?
        data.state = data.state.list
      socket.emit 'data', data

    sendToAllClients: (sockets, data) =>
      @sendToClient socket, data for socket in sockets
      # console.log "sendToAllClients"
      # console.log @sockets
      # for s in @sockets
      #   console.log "Jetzt wird gesendet"
      #   console.log s
      #   console.log data
      #   s.emit data.type, data

    sendToOtherClients: (sockets, socket, data) =>
      @sendToClient s, data for s in sockets when s isnt socket
      # console.log "sendToOtherClients"
      # console.log @sockets
      # for s in @sockets
      #   console.log "Jetzt wird gesendet"
      #   console.log s
      #   console.log data
      #   s.emit data.type, data

