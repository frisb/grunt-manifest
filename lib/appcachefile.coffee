#
# grunt-manifest
# https://github.com/gunta/grunt-manifest
#
# Copyright (c) 2014 Gunther Brunner, Ashley Brener, contributors
# Licensed under the MIT license.
# https://github.com/gunta/grunt-manifest/blob/master/LICENSE-MIT
#

module.exports = (grunt) ->
  path = require('path')
  crypto = require('crypto')
  md5 = null

  updateHash = (filePath) ->
    grunt.verbose.writeln('Hashing ' + filePath)
    data = grunt.file.read(filePath)
    md5.update(data, 'binary')

  class AppCacheFile
    constructor: (filePair, options) ->
      @cwd = filePair.cwd || ''
      @src = filePair.src
      @dest = filePair.dest || 'manifest.appcache'
      @cwd = filePair.orig.cwd

      # check to see if src has been set
      if (typeof @src is 'undefined')
        grunt.fatal('Must specify which files to include in the manifest.', 2)

      @output = 'CACHE MANIFEST'
      @verbose = options.verbose
      @timestamp = options.timestamp
      @revision = options.revision
      @cache = options.cache
      @process = options.process
      @hash = options.hash
      @master = options.master

      # if hash options is specified it will be used to calculate
      # a hash of local files that are included in the manifest
      md5 = crypto.createHash('md5') if options.hash

      # Metadata section
      @renderMetadata()

      # Cache section
      @renderCache()

      # Network section
      @renderNetwork()

      # Fallback section
      @renderFallback()

      # Settings section
      @renderSettings()

      # output hash to cache manifest
      @renderHash()

    writeln: (str) ->
      @output += (str || '') + '\n'

    renderMetadata: ->
      @writeln()
      @writeln('# Generated by grunt-manifest HTML5 Cache Manifest Generator') if @verbose
      @writeln('# Time: ' + new Date()) if @timestamp
      @writeln('# Revision: ' + @revision) if @revision

    renderCache: () ->
      @writeln()
      @writeln('CACHE:')

      # add files to explicit cache manually
      if (@cache)
        for item in @cache
          @writeln(encodeURI(item))

      # add files to explicit cache
      if (@src)
        for item in @src
          if (@process)
            @writeln(encodeURI(@process(item)))
          else
            @writeln(encodeURI(item))

          # hash file contents
          if (@hash)
            updateHash(path.join(@cwd, item))

    renderNetwork: ->
      @writeln()
      @writeln('NETWORK:')

      if (@network)
        for item in @network
          @writeln(encodeURI(item))
      else
        # If there's no network section, add a default '*' wildcard
        @writeln('*')

    renderFallback: ->
      if (@fallback)
        @writeln()
        @writeln('FALLBACK:')

        for item in @fallback
          @writeln(encodeURI(item))

    renderSettings: ->
      if (@preferOnline)
        @writeln()
        @writeln('SETTINGS:')
        @writeln('prefer-online')

    renderHash: ->
      if (@hash)
        # hash masters as well
        if (@master)
          # convert from string to array
          @master = [@master] if typeof @master is 'string'

          for item in @master
            item = path.join(@cwd, item) if @cwd
            updateHash(path.join(@cwd, item))

        @writeln()
        @writeln('# hash: ' + md5.digest("hex"))

    createFile: ->
      grunt.file.write(@dest, @output)
      grunt.log.writeln('File "' + @dest + '" created.')
