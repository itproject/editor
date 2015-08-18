React = require 'react/addons'
flatten = require('flat')
_ = require 'lodash'
$ = window.jQuery = window.$ = require 'jquery'
request = require 'request'
Promise = require 'bluebird'
require('./materialize')

Router = require 'react-router'
RouteHandler = Router.RouteHandler
Navigation = Router.Navigation

Header = require './header'
Filesystem = require './filesystem'

module.exports =
React.createClass
  getInitialState: ->
    @bindKeys()
    track('loaded')

    {
      clean_files: _.cloneDeep(Filesystem.ls()),
      action_in_progress: false,
      first_build_done: false
    }

  bindKeys: ->
    $(window).bind 'keydown', (event) =>
      return unless event.ctrlKey or event.metaKey

      switch String.fromCharCode(event.which).toLowerCase()
        when 's'
          event.preventDefault()
          @previewClick()
        when 'e'
          event.preventDefault()
          @codeClick()

  mixins: [Navigation],
  editorChange: (path, new_content) ->
    Filesystem.write(path, new_content)

    # @goToStep(2) if @state.loaded
    # @setState(loaded: true) if new_content == @state.editor_content

  codeClick: ->
    track('code_clicked')
    @transitionWithCodeModeHistory('code', '/code/*?')
  previewClick: ->
    track('preview_clicked')
    return if @state.action_in_progress

    if @context.router.getCurrentPath().match(/^\/preview/)
      @buildOrRefresh()
    else
      @transitionWithCodeModeHistory('preview', 'preview-with-history')

  transitionWithCodeModeHistory: (route, with_history_route) ->
    track('transitioned_to', route: route)

    if _.isEmpty(@context.router.getCurrentParams())
      @transitionTo(route)
    else
      @transitionTo(with_history_route, @context.router.getCurrentParams())

  publishClick: ->
    track('publish_clicked')
    return if @state.action_in_progress
    @transitionWithCodeModeHistory('publish', '/publish/*?')

  handleError: (msg) ->
    track('error_happened', message: msg)
    @setState(error: msg)
    @transitionWithCodeModeHistory('error', '/error/*?')

  changedFiles: ->
    _.reject Filesystem.ls(), (new_file) =>
      clean_file = _.detect @state.clean_files, (file) ->
        file.path == new_file.path

      clean_file.content == new_file.content

  build: ->
    @buildOrRefresh()

  buildOrRefresh: ->
    if @filesChanged() or !@state.first_build_done
      @execBuild()
    else
      @refreshBrowser()

  refreshBrowser: ->
    new Promise (resolve, reject) =>
      browser_ref = @refs.appRouteHandler.refs.__routeHandler__?.refs.browser
      return resolve() unless browser_ref

      # same route, refresh manually
      browser_ref.refresh()
      resolve()

  execBuild: ->
    track('build_started')
    @actionStarted()

    new Promise (resolve, reject) =>
      request.post
        json: true
        body:
          files: @changedFiles()
        url: "#{window.location.origin}/apps/#{APP_SLUG}/live_edit/preview"
      , (err, status, resp) =>

        return reject(err) if err
        return reject(resp.error) unless resp.success

        @setState(clean_files: _.cloneDeep(Filesystem.ls()), first_build_done: true)
        @actionStopped()
        track('build_finished')
        resolve()

  filesChanged: ->
    !_.isEmpty(@changedFiles())

  publishToGithub: ->
    track('publish_started')

    if @filesChanged()
      @build().then(@publishToGithub).catch (err) =>
        @handleError(err)
    else
      @actionStarted()
      @execPublish().then( (resp) =>
        return @handleError(resp.error) unless resp.success

        track('publish_to_github_finished')
      ).catch (err) =>
        @handleError(err)

  waitForPublishToServer: ->
    new Promise (resolve, reject) =>
      pusher_user_channel.bind 'app.build', =>
        track('publish_to_server_finished')
        @actionStopped()
        resolve()

  execPublish: ->
    new Promise (resolve, reject) =>
      request.post json: true, url: "#{window.location.origin}/apps/#{APP_SLUG}/live_edit/publish", (err, status, resp) ->
        return reject(err) if err

        # published to GitHub
        resolve(resp)

  activeMode: ->
    routes = @context.router.getCurrentRoutes()

    # in this setup second route is the important route
    _.first(routes[1].name.split('-'))

  actionStarted: ->
    @setState(action_in_progress: true)

  actionStopped: ->
    @setState(action_in_progress: false)

  render: ->
    <main className='editor-wrapper'>
      <Header
        action_in_progress={@state.action_in_progress}
        website_url={@props.website_url}
        active_mode={@activeMode()}
        onCodeClick={@codeClick}
        onPreviewClick={@previewClick}
        onPublishClick={@publishClick}
        avatar={@props.avatar}
        />

      <RouteHandler
        browser_url={@props.browser_url}
        website_url={@props.website_url}
        editorChange={@editorChange}
        build={@build}
        handleError={@handleError}
        error={@state.error}
        transitionWithCodeModeHistory={@transitionWithCodeModeHistory}
        files_changed={@filesChanged()}
        publishToGithub={@publishToGithub}
        waitForPublishToServer={@waitForPublishToServer}
        actionStopped={@actionStopped}
        ref='appRouteHandler'/>
    </main>
