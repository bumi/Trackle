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
