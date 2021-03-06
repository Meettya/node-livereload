// Generated by CoffeeScript 1.6.2
(function() {
  var DEFAULT_CONFIG, Server, escape_regexp, express, fs, http, path, url, watchr, ws, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fs = require('fs');

  path = require('path');

  ws = require('websocket.io');

  http = require('http');

  express = require('express');

  url = require('url');

  watchr = require('watchr');

  _ = require('underscore');

  escape_regexp = require('escape-regexp');

  DEFAULT_CONFIG = {
    version: '7',
    port: 35729,
    delay: 50,
    alias: {
      'styl': 'css'
    },
    exts: ['html', 'css', 'js', 'png', 'gif', 'jpg', 'php', 'php5', 'py', 'rb', 'erb', 'jade'],
    exclusions: ['.git/', '.svn/', '.hg/'],
    applyJSLive: false,
    applyCSSLive: true
  };

  Server = (function() {
    function Server(config) {
      this.config = config;
      this.watch = __bind(this.watch, this);
      this.onClose = __bind(this.onClose, this);
      this.onConnection = __bind(this.onConnection, this);
      _.defaults(this.config, DEFAULT_CONFIG);
      this.sockets = [];
      this.server = null;
    }

    Server.prototype.listen = function() {
      this.debug("LiveReload is waiting for browser to connect.");
      this.server = this.config.server ? (this.config.server.listen(this.config.port), ws.attach(this.config.server)) : ws.listen(this.config.port);
      this.server.on('connection', this.onConnection);
      this.server.on('close', this.onClose);
      return this;
    };

    Server.prototype.onConnection = function(socket) {
      var _this = this;

      this.debug("Browser connected.");
      socket.send(JSON.stringify({
        command: 'hello',
        protocols: ['http://livereload.com/protocols/official-7'],
        serverName: 'node-livereload'
      }));
      socket.on('message', function(message) {
        return _this.debug("Browser URL: " + message);
      });
      this.sockets.push(socket);
      return null;
    };

    Server.prototype.onClose = function(socket) {
      this.debug("Browser disconnected.");
      return null;
    };

    Server.prototype._buildListiner = function(exts, re_exclusions) {
      var _this = this;

      return function(eventName, filePath) {
        var ext, re_exclusion, _i, _j, _len, _len1;

        for (_i = 0, _len = re_exclusions.length; _i < _len; _i++) {
          re_exclusion = re_exclusions[_i];
          if (re_exclusion.test(filePath)) {
            _this.debug("Filtered: |" + filePath + "| by |" + re_exclusion + "| pattern");
            return null;
          }
        }
        for (_j = 0, _len1 = exts.length; _j < _len1; _j++) {
          ext = exts[_j];
          if (!(filePath.match("\." + ext + "$"))) {
            continue;
          }
          setTimeout(function() {
            return _this.reloadFile(filePath);
          }, _this.config.delay);
          null;
        }
        return true;
      };
    };

    Server.prototype._buildExclusionsRe = function(raw_exclusions) {
      var raw_exclusion, _i, _len, _results;

      _results = [];
      for (_i = 0, _len = raw_exclusions.length; _i < _len; _i++) {
        raw_exclusion = raw_exclusions[_i];
        _results.push(new RegExp(escape_regexp(raw_exclusion)));
      }
      return _results;
    };

    Server.prototype.watch = function(source) {
      var exts, re_exclusions;

      exts = this.config.exts;
      re_exclusions = this._buildExclusionsRe(this.config.exclusions);
      watchr.watch({
        path: source,
        listener: this._buildListiner(exts, re_exclusions),
        ignoreHiddenFiles: true
      });
      return this;
    };

    Server.prototype._doSend = function(data) {
      var socket, _i, _len, _ref;

      _ref = this.sockets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        socket = _ref[_i];
        socket.send(data);
        null;
      }
      return null;
    };

    Server.prototype.reloadFile = function(filepath) {
      var aliasExt, ext;

      this.debug("Reload file: " + filepath);
      ext = path.extname(filepath).substr(1);
      aliasExt = this.config.alias[ext];
      if (aliasExt != null) {
        this.debug("and aliased to " + aliasExt);
        filepath = filepath.replace("." + ext, "." + aliasExt);
      }
      return this._doSend(JSON.stringify({
        command: 'reload',
        path: filepath,
        liveJS: this.config.applyJSLive,
        liveCSS: this.config.applyCSSLive
      }));
    };

    Server.prototype.reloadAll = function() {
      this.debug("Reload all");
      return this._doSend(JSON.stringify({
        command: 'reload',
        path: '*',
        liveJS: false,
        liveCSS: false
      }));
    };

    Server.prototype.debug = function(str) {
      if (this.config.debug) {
        return console.log("" + str + "\n");
      }
    };

    return Server;

  })();

  exports.DEFAULT_CONFIG = DEFAULT_CONFIG;

  exports.createServer = function(config) {
    var app, server;

    if (config == null) {
      config = {};
    }
    server = new Server(config);
    if (config.server == null) {
      app = express();
      app.use(express["static"]("" + __dirname + "/../ext"));
      app.get('/livereload.js', function(req, res) {
        return res.sendfile("" + __dirname + "/../ext/livereload.js");
      });
      app.post('/reload', function(req, res) {
        var _this = this;

        setTimeout(function() {
          return server.reloadAll();
        }, server.config.delay);
        return res.send("");
      });
      config.server = http.createServer(app);
    }
    server.listen();
    return server;
  };

}).call(this);
