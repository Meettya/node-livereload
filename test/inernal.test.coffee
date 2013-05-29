###
Yes, we are testing internal realization and private methods
but it need to be tested and its looks simplest do it like this way.
###

livereload = require '../lib/livereload'
fs = require 'fs'

describe 'livereload internal', ->

  describe 'file processing filter', ->

    raw_server = listener_fn = exl_builder_fn = fired_fn = null
    exclusions    = ['.git/', '.svn/', '.hg/']

    fake_obj =
      config :
        delay : 50
      reloadFile  : -> 
      debug       : ->

    beforeEach ->
      raw_server      = livereload.createServer()
      listener_fn     = raw_server._buildListiner
      exl_builder_fn  = raw_server._buildExclusionsRe
      fired_fn        = listener_fn.call fake_obj, ['coffee'], exl_builder_fn exclusions

    afterEach ->
      raw_server.config.server.close()

    it 'should create escaped RegExp from string', ->
      expect(exl_builder_fn exclusions).to.be.eql [ /\.git\//, /\.svn\//, /\.hg\// ]

    it 'should process non-like exclusions', ->
      expect(fired_fn 'some data', 'Some_name/sub_dir/filename.coffee').to.be.true

    it 'should process path-like exclusions', ->
      expect(fired_fn 'some data', 'Some_name/git/filename.coffee').to.be.true

    it 'should non-process exclusions ', ->
      expect(fired_fn 'some data', 'Some_name/.git/filename.coffee').to.be.null


