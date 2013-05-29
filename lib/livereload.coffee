fs        = require 'fs'
path      = require 'path'
ws        = require 'websocket.io'
http      = require 'http'
express   = require 'express'
url       = require 'url'
watchr    = require 'watchr'
_         = require 'underscore'

DEFAULT_CONFIG =
  version:  '7'
  port:     35729
  delay:    50
  alias:
    'styl': 'css'
  exts: [
    'html', 'css', 'js', 'png', 'gif', 'jpg',
    'php', 'php5', 'py', 'rb', 'erb', 'jade'
  ]
  exclusions:   ['.git/', '.svn/', '.hg/']
  applyJSLive:  false
  applyCSSLive: true

class Server

  constructor: (@config) ->
    _.defaults @config, DEFAULT_CONFIG
    @sockets  = []
    @server   = null
    
  listen: ->
    @debug "LiveReload is waiting for browser to connect."
    
    @server = if @config.server
      @config.server.listen @config.port
      ws.attach @config.server
    else
      ws.listen @config.port

    @server.on 'connection', @onConnection
    @server.on 'close',      @onClose

    null


  onConnection: (socket) =>
    @debug "Browser connected."
    
    socket.send JSON.stringify 
      command: 'hello',
      protocols: [
        'http://livereload.com/protocols/official-7'
      ]
      serverName: 'node-livereload'

    socket.on 'message', (message) =>
      @debug "Browser URL: #{message}"

    @sockets.push socket

    null
    
  onClose: (socket) =>
    @debug "Browser disconnected."
    null
  
  _buildLisriner: (exts, exclusions) -> 
    (eventName, filePath, fileCurrentStat, filePreviousStat)=>
        
        for exclusion in exclusions
          return if filePath.match exclusion
        
        for ext in exts when filePath.match "\.#{ext}$"
          setTimeout =>
            @reloadFile(filePath)
          , @config.delay

  watch: (source) =>
    
    # Watch a directory or file
    exts       = @config.exts
    exclusions = @config.exclusions

    watchr.watch
      path:               source
      listener:           @_buildLisriner exts, exclusions
      ignoreHiddenFiles:  yes

    null
  
  _doSend: (data) ->
    for socket in @sockets
      socket.send data
      null
    null

  reloadFile: (filepath) ->
    @debug "Reload file: #{filepath}"
    ext       = path.extname(filepath).substr 1
    aliasExt  = @config.alias[ext]
    if aliasExt?
      @debug "and aliased to #{aliasExt}"
      filepath = filepath.replace ".#{ext}", ".#{aliasExt}"
      
    @_doSend JSON.stringify 
      command:  'reload'
      path:     filepath
      liveJS:   @config.applyJSLive
      liveCSS:  @config.applyCSSLive
    
  reloadAll: -> 
    @debug "Reload all"

    @_doSend JSON.stringify 
      command: 'reload'
      path:     '*'
      liveJS:   false
      liveCSS:  false

  debug: (str) ->
    if @config.debug
      console.log "#{str}\n"

exports.DEFAULT_CONFIG = DEFAULT_CONFIG
  
exports.createServer = (config = {}) ->
  server = new Server config

  unless config.server?
    app = express()
    app.use express.static "#{__dirname}/../ext"
    app.get '/livereload.js', (req, res) ->
      res.sendfile "#{__dirname}/../ext/livereload.js"
    app.post '/reload', (req, res) -> 
      setTimeout =>
        do server.reloadAll
      , server.config.delay
      res.send ""
    config.server = http.createServer app

  server.listen()
  server

