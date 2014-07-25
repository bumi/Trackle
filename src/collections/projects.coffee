class ProjectCollection extends Backbone.Collection
  model: Project
  comparator: "name"
  sync: (method, model, options) ->
    Mole.Authentication.freckle.projects.list (err, response) ->
      callback.error(model, options) if err
      options.success.call this, response
