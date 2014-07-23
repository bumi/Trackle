
Mole.module "Authentication", (Module, App) ->
  @startWithParent = false

# -----------------------------------------------------------------------

  class LoginPromptView extends Marionette.ItemView
    tagName: "div"
    className: "dialog"

    template: _.template """
      <form id="login-dialog-view">
        <h1>Hi there!</h1>
        <p>Log in with your Freckle Account to start using Mole.</p>
        <ul class="form-list">
          <li><input id="dialog-email" placeholder="email" type="text"></li>
          <li><input id="dialog-password" placeholder="password" type="password"></li>
          <li><input id="dialog-subdomain" placeholder="subdomain" type="text"></li>
          <li><button>Log In</button></li>
        </ul>
      </form>
    """
    ui:
      email: "#dialog-email"
      password: "#dialog-password"
      subdomain: "#dialog-subdomain"

    onBeforeRender: ->
      @$el.css
        scale: 0.5
        opacity: 0

    onRender: ->
      setTimeout =>
        @$el.transit
          scale: 1
          opacity: 1
      , 100

    onClose: ->
      @$el.transit opacity: 0

    events:
      "change #dialog-email": ->
        host = @ui.email.val().match /@(\w+)\.?/
        host = "#{host[1]}.letsfreckle.com"
        @ui.subdomain.val host if host?

      "submit form": (e) ->
        e.preventDefault()
        email = @ui.email.val()
        password = @ui.password.val()
        subdomain = @ui.subdomain.val().replace ".letsfreckle.com", ""
        if email and password and subdomain
          @trigger "can:authenticate", email: email, password: password, subdomain: subdomain
          @$el.transit
            scale: 0.5
            opacity: 0
        else
          console.error "form invalid"

# -----------------------------------------------------------------------

  @addInitializer =>
    @freckle = new Freckle

    @freckle.on "ready", =>
      App.layout.dialog.close()
      App.vent.trigger "api:ready"

    @freckle.on "authentication:success", (auth) =>
      @auth = App.storage.set "auth", auth

    if App.storage.exist "auth"
      @auth = App.storage.get "auth"
      {token, subdomain} = @auth
      @freckle.initialize
        storage: App.storage
        subdomain: subdomain
        token: token

    else
      @loginPromptView = new LoginPromptView

      @loginPromptView.on "can:authenticate", (auth) =>
        { subdomain, email, password } = auth
        @freckle.initialize
          subdomain: subdomain
          storage: App.storage
        @freckle.authenticate email, password

      App.layout.dialog.show @loginPromptView
