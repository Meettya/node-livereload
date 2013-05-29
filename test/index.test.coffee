livereload = require '../lib/livereload'
request = require 'request'
http = require 'http'
url = require 'url'
fs = require 'fs'
WebSocket = require 'ws'

describe 'livereload http file serving', ->

  it 'should serve up livereload.js', (done) ->
    server = livereload.createServer({port: 35729})

    fileContents = fs.readFileSync('./ext/livereload.js').toString()

    request 'http://localhost:35729/livereload.js?snipver=1', (error, response, body) ->
      should.not.exist error
      response.statusCode.should.equal 200
      fileContents.should.equal body

      server.config.server.close()

      done()

  it 'should connect to the websocket server', (done) ->
    server = livereload.createServer({port: 35729})

    ws = new WebSocket('ws://localhost:35729/livereload')
    ws.on 'message', (data, flags) ->
      data = JSON.parse(data)
      data.protocols[0].should.include 'official-7'

      server.config.server.close()

      done()

  it 'should allow you to override the internal http server', (done) ->
    app = http.createServer (req, res) ->
      if url.parse(req.url).pathname is '/livereload.js'
        res.writeHead(200, {'Content-Type': 'text/javascript'})
        res.end '// nothing to see here'

    server = livereload.createServer({port: 35729, server: app})

    request 'http://localhost:35729/livereload.js?snipver=1', (error, response, body) ->
      should.not.exist error
      response.statusCode.should.equal 200
      body.should.equal '// nothing to see here'

      server.config.server.close()

      done()
     

  it 'should proxy the request request', (done) ->
    server = livereload.createServer()
    request
      method: 'POST',
      uri: 'http://localhost:35729/reload' 
      body: "" 
    , (error, response, body) ->
        should.not.exist error
        response.statusCode.should.equal 200

        server.config.server.close()

        done()
