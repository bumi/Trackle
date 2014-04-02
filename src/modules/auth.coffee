
Mole.module "Authentication", (Module, App) ->
  @startWithParent = false

  class User extends Backbone.Model
    parse: (response) -> response.user

  # --------------------------------------------------------------------------------------------

  class Auth extends Backbone.Model
    defaults:
      subdomain: "railslove"
      token: "jagzeek0wsnfmnfhuntigxv3be6qqc3"
    schema:
        subdomain:
          type: "Text"
          validators: ['required']
        token:
          type: 'Select'
          options: ['jagzeek0wsnfmnfhuntigxv3be6qqc3', 'plopzlx1l1tvr5bqhi2j59lqe5q2v5u']
          validators: ['required']

    validate: ->
      return "Missing subdomain or token" unless @get("subdomain") and @get("token")

  # --------------------------------------------------------------------------------------------

  @addInitializer =>

    init = ->
      App.freckle = new Freckle
        subdomain: App.auth.get "subdomain"
        token: App.auth.get "token"

      App.freckle.users.self
        success: (data) =>
          App.freckle.projects.index success: (projects) ->
            App.projects = _.reduce projects, ((memo, item) -> memo[item.project.id] = { name: item.project.name, color_hex: item.project.color_hex, id: item.project.id }; return memo), {}
            App.user = new User data, parse: true
            App.vent.trigger "authentication:success"

    App.auth = new Auth

    if App.auth.isValid()
      init()
    else
      form = new Backbone.Form
        model: App.auth

      form.render()
      $(".modal-view").html(form.el)

      form.$el.on "submit", (e) ->
        e.preventDefault()
        if form.commit() is undefined and App.auth.isValid()
          init()
