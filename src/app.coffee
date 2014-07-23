
async = require "async"
window.Mole = new Backbone.Marionette.Application()

# -----------------------------------------------------------------------

Mole.module "Behaviors", (Behaviors, App, Backbone, Marionette) ->
  Marionette.Behaviors.behaviorsLookup = Behaviors

  class Behaviors.KeyEvents extends Marionette.Behavior
    keyMap:
      18: "alt"
      8: "backspace"
      20: "caps_lock"
      188: "comma"
      91: "command"
      91: "command_left"
      93: "command_right"
      17: "control"
      46: "delete"
      40: "down"
      35: "end"
      13: "enter"
      27: "escape"
      36: "home"
      45: "insert"
      37: "left"
      93: "menu"
      107: "numpad_add"
      110: "numpad_decimal"
      111: "numpad_divide"
      108: "numpad_enter"
      106: "numpad_multiply"
      109: "numpad_subtract"
      34: "page_down"
      33: "page_up"
      190: "period"
      39: "right"
      16: "shift"
      32: "space"
      9: "tab"
      38: "up"
      91: "windows"

    defaults:
      preventDefault: []

    onShow: ->
      $(window).on 'keydown', @checkKey

    onClose: ->
      $(window).off 'keydown', @checkKey

    shouldIgnore: ->
      a = document.activeElement.tagName
      return true if a is "INPUT" or a is "TEXTAREA"

    checkKey: (event) =>
      unless ~[16, 18, 91, 93, 17].indexOf event.which
        modifier = []
        modifier.push "ctrl"  if event.ctrlKey
        modifier.push "cmd"   if event.metaKey
        modifier.push "shift" if event.shiftKey
        modifier.push "alt"   if event.altKey

        key = @keyMap[event.which] || String.fromCharCode(event.which).toLowerCase()

        keyString = modifier
          .concat key
          .filter (e) -> e != null
          .join "+"

        if modifier.length or @keyMap[event.which]
          toInvoke = @options[keyString]
          toInvoke?.call @view, event

        if ~@options.preventDefault.indexOf(event.keyCode)
          event.preventDefault()
          return false

# -----------------------------------------------------------------------

Backbone.Marionette.Renderer.render = (template, data) ->
  if _.isFunction template
    template(data)
  else
    throw "Template #{template} not found!" unless JST[template]
    JST[template](data)

# -----------------------------------------------------------------------

class User extends Backbone.Model
  defaults: avatar: avatar: "images/mole.png"
  sync: (method, model, options) ->
    Mole.Authentication.freckle.users.self (err, response) ->
      callback.error(model, options) if err
      { user } = response
      Mole.Authentication.freckle.users.avatar id: user.id, (err, response) ->
        callback.error(model, options) if err
        user.avatar = response
        options.success.call this, user

# -----------------------------------------------------------------------

class Project extends Backbone.Model
  parse: (response) -> response.project

class ProjectCollection extends Backbone.Collection
  model: Project
  comparator: "name"
  sync: (method, model, options) ->
    Mole.Authentication.freckle.projects.list (err, response) ->
      callback.error(model, options) if err
      options.success.call this, response

# -----------------------------------------------------------------------

class PopoverRegion extends Marionette.Region

  onShow: (@view) ->
    @drop = new Drop
      target: @view.options.target[0]
      content: @view.$el[0]
      position: 'right middle'
      openOn: 'always'
      classes: "drop-theme-arrows"
      tetherOptions:
        offset: '0 -5px'

    @drop.on "open", =>
      @trigger "dialog:open"

  closeDialog: ->
    @view.trigger "dialog:close"
    @drop.destroy() if @drop.target?

    @close()

# -----------------------------------------------------------------------

class Mole.AppLayout extends Backbone.Marionette.Layout
  el: "body"
  template: _.template """
    <div id="header-region"   class="region"></div>
    <div id="calendar-region" class="region"></div>
    <div id="dialog-region"   class="region"></div>
    <div id="popover-region"  class="region"></div>
  """

  regions:
    header:   "#header-region"
    calendar: "#calendar-region"
    dialog:   "#dialog-region"
    popover: PopoverRegion.extend el: "#popover-region"

# -----------------------------------------------------------------------

Mole.addInitializer (@options) ->
  @storage  = new Storage()
  @user     = new User()
  @projects = new ProjectCollection()

  @user.on "sync", =>
    Raygun.setUser @user.get("email")
    if @user.get("email") is "philipp@railslove.com"
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


  @options.nwWindow.on "move", _.debounce (args...) =>
    @storage.set "window:position", args
  , 300

  @options.nwWindow.on "resize", _.debounce (args...) =>
    @storage.set "window:dimensions", args
  , 300

  if @storage.exist("window:dimensions")
    @options.nwWindow.resizeTo.apply @options.nwWindow, @storage.get("window:dimensions")

  if @storage.exist("window:position")
    @options.nwWindow.moveTo.apply @options.nwWindow, @storage.get("window:position")

  @vent.on "api:ready", =>
    @user.fetch()
    @projects.fetch()

  @layout = new @AppLayout()
  @layout.render()

  @Header.start()
  @Calendar.start()

  @Calendar.weekCollection.on "sync", =>
    entries = @storage.get("request:entries:list:response")
    recentIds = _.chain(entries).pluck("entry").pluck("project_id").uniq().value()

    [other, recents] = _.partition @projects.models, (project) -> !~recentIds.indexOf(project.id)

    @projects.recents = new ProjectCollection recents
    @projects.other   = new ProjectCollection other

  @Authentication.start()
