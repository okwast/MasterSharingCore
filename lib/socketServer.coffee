events = require 'events'
http = require 'http'
fs = require 'fs'
socketio = require 'socket.io'
types = require './types'

# This class represents the network connection
# and some low level logic.
module.exports =
  class Server extends events.EventEmitter
    initial:    false
    server:     undefined
    io:         undefined
    clientId:   0
    port:       undefined
    sockets:    []

    # Creates an HTTP-Server and creates an Socket.IO-Server with it
    # A static HTML file is send, when a browser sends a request
    # Also the scripts of codemirror are send, when requested
    constructor: (@port) ->

      # Create a HTTP server that can deliver files to a browser.
      # The files are neccessary for the codemirror client.
      @server = http.createServer (req, res) ->
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

      # Starting server
      @server.listen @port

      # Creating Socket.IO-Server
      @io = socketio @server
      @io.on 'connection', (socket) =>
        @sockets.push socket

        socket.on 'error', (err) ->
          console.log err

        socket.on 'disconnect', ->
          @emit types.clientDisconnected, socket.id

        # When a new transform arrives and its type is checked.
        # When it is a new connection a new ID is created for the client.
        # Afterwards an event is emitted.
        # When it is another type of transform an event is emitted.
        socket.on 'data', (transform) =>
          switch transform.type
            when types.connecting
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
              @emit 'transform', socket, transform

    # Sends a message to the client of the socket.
    # It also sets the state to the list of the state,
    # to allow standard serialization
    sendToClient: (socket, data) ->
      if data.state? and data.state.list?
        data.state = data.state.list
      socket.emit 'data', data

    # Sends a message to all the clients
    sendToAllClients: (sockets, data) =>
      @sendToClient socket, data for socket in sockets

    # Sends data to all clients, but the client of the given socket
    sendToOtherClients: (sockets, socket, data) =>
      @sendToClient s, data for s in sockets when s isnt socket