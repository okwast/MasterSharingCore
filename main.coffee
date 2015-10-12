clientTM = require './lib/clientTransformManager'
serverTM = require './lib/serverTransformManager'

module.exports =

  createServer: (port) ->
    new serverTM false, port

  createClient: (url, name, color) ->
    new clientTM url, name, color