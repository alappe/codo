fs      = require 'fs'
path    = require 'path'
mkdirp  = require 'mkdirp'
_       = require 'underscore'
walkdir = require 'walkdir'
hamlc   = require 'haml-coffee'

# Haml Coffee template compiler.
#
module.exports = class Templater

  # Construct the templater. Reads all templates and constructs
  # the global template context.
  #
  # @param [Object] options the options
  # @param [Referencer] referencer the link type referencer
  #
  constructor: (@options, @referencer) ->
    @JST = []

    @globalContext =
      codoVersion: 'v' + JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'package.json'), 'utf-8'))['version']
      generationDate: new Date().toString()
      JST: @JST
      underscore: _
      title: @options.title
      referencer: @referencer
      analytics: @options.analytics

    for filename in walkdir.sync path.join(__dirname, '..', '..', 'theme', 'default', 'templates')
      if match = /theme[/\\]default[/\\]templates[/\\](.+).hamlc$/.exec filename
        @JST[match[1]] = hamlc.compile(fs.readFileSync(filename, 'utf-8'))

  # Redirect template generation to a callback.
  #
  # @param [Function] file the file callback function
  #
  redirect: (file) -> @file = file

  # Render the given template with the context and the
  # global context object merged as template data. Writes
  # the file as the output filename.
  #
  # @param [String] template the template name
  # @param [Object] context the context object
  # @param [String] filename the output file name
  #
  render: (template, context = {}, filename = '') ->
    html = @JST[template](_.extend(@globalContext, context))

    unless _.isEmpty filename

      # Callback generated content
      if @file
        @file(filename, html)

      # Write to file system
      else
        file = path.join @options.output, filename
        dir  = path.dirname(file)
        mkdirp dir, (err) ->
          if err
            console.error "[ERROR] Cannot create directory #{ dir }: #{ err }"
          else
            fs.writeFile file, html

    html
