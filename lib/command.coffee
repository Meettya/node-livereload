fs = require 'fs'
_ = require 'underscore'

runner = ->

  livereload = require './livereload'
  resolve    = require('path').resolve
  opts       = require 'opts'

  opts.parse [
    {
      short: "p"
      long:  "port"
      description: "Specify the port"
      value: true
      required: false
    },
    {
      short: "c"
      long:  "config"
      description: "Specify the JSON config file"
      value: true
      required: false
    },
    {
      short: "d"
      long:  "delay"
      description: "Specify the wait delay (before refresh)."
      value: true
      required: false
    },
    {
      short: "w"
      long:  "watch"
      description: "Specify wether to watch directories (default: true)."
      value: true
      required: false
    }
  ].reverse(), true

  config = {}
  if opts.get('config')?
    config = JSON.parse fs.readFileSync(opts.get('config'))

  config.port = opts.get('port') or config.port 
  config.delay = opts.get('delay') or config.delay
  config.watch = _.find [opts.get('watch'), config.watch, true], ( (el) -> el? )
  config.watch = config.watch is 'true' if typeof config.watch is 'string'

  config.debug ?= true

  server = livereload.createServer(config)

  path = resolve(opts.args()[0] or '.')

  console.log "Started LiveReload on port #{server.config.port}"
  
  if config.watch
    server.watch(path)
    console.log "LiveReload is watching #{path}"

module.exports =
  run: runner
