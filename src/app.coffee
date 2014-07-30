
window.Mole = new Backbone.Marionette.Application()

# -----------------------------------------------------------------------

Backbone.Marionette.Renderer.render = (template, data) ->
  if _.isFunction template
    template(data)
  else
    throw "Template #{template} not found!" unless JST[template]
    JST[template](data)

# -----------------------------------------------------------------------

Mole.addInitializer (@options) ->
  @storage  = new Storage()
  @user     = new User()
  @projects = new ProjectCollection()
  @tracker = new Track "http://5.101.105.15/api"


  @user.on "sync", =>
    userEmail = @user.get("email")
    Raygun.setUser userEmail

    if userEmail is "philipp@railslove.com"
      @options.dtWindow = @options.nwWindow.showDevTools()

      @options.dtWindow.on "move", _.debounce (args...) =>
        @storage.set "window:devTools:position", args
      , 300

      @options.dtWindow.on "resize", _.debounce (args...) =>
        @storage.set "window:devTools:dimensions", args
      , 300

      if @storage.exist("window:devTools:dimensions")
        @options.dtWindow.resizeTo.apply @options.dtWindow, @storage.get("window:devTools:dimensions")

      if @storage.exist("window:devTools:position")
        @options.dtWindow.moveTo.apply @options.dtWindow, @storage.get("window:devTools:position")

    else
      unless @storage.exist("app:uuid")
        @storage.set "app:uuid", require('crypto').createHash('md5').update(userEmail).digest("hex")

      @tracker.setUser @storage.get("app:uuid")
      @tracker.event "application:startup"

  @options.nwWindow.on "move", _.debounce (args...) =>
    @storage.set "window:position", args
  , 300

  @options.nwWindow.on "resize", _.debounce (args...) =>
    @storage.set "window:dimensions", args
  , 300

  if @storage.exist "window:dimensions"
    @options.nwWindow.resizeTo.apply @options.nwWindow, @storage.get "window:dimensions"

  if @storage.exist "window:position"
    @options.nwWindow.moveTo.apply @options.nwWindow, @storage.get "window:position"

  @vent.on "api:ready", =>
    @user.fetch()
    @projects.fetch()

  @layout = new AppLayout()
  @layout.render()

  @Header.start()
  @Calendar.start()

  @Calendar.weekCollection.on "sync", =>
    entries = @storage.get "request:entries:list:response"
    recentIds = _.chain(entries).pluck("entry").pluck("project_id").uniq().value()

    [other, recents] = _.partition @projects.models, (project) -> !~recentIds.indexOf(project.id)

    @projects.recents = new ProjectCollection recents
    @projects.other   = new ProjectCollection other

  @Authentication.start()
