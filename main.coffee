clientTM = require './lib/clientTransformManager'
serverTM = require './lib/serverTransformManager'

# This is the interface of this module for usage in other projects.
# So the client and the server need to be exported.
module.exports =

  createServer: (port) ->
    new serverTM port

  createClient: (url, name, color) ->
    new clientTM url, name, color