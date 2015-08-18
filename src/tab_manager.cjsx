React = require 'react/addons'
_ = require 'lodash'

Editor = require('./editor')
FileManager = require('./file_manager')
Filesystem = require('./filesystem')

module.exports =
React.createClass
  renderEditor: (file) ->
    <Editor value={file.content} path={@props.active_tab_path} onChange={@props.editorChange} />
  renderFileManager: (dir) ->
    <FileManager dir={dir} path={@props.active_tab_path} reuseTabHref={@props.reuseTabHref} newTabHref={@props.newTabHref}/>
  render: ->
    file_or_dir = Filesystem.read(@props.active_tab_path)

    if file_or_dir.type == 'dir'
      @renderFileManager(file_or_dir)
    else
      @renderEditor(file_or_dir)
