
Backbone.Marionette.Renderer.render = (template, data) ->
  throw "Template #{template} not found!" unless JST[template]
  JST[template](data)

# -----------------------------------------------------------------------

window.Mole = new Backbone.Marionette.Application()

Mole.addInitializer ->

  @vent.on "authentication:success", =>
    @Calendar.start()

    $(".modal-view").transit
      opacity: 0
    , -> $(".modal-view").empty()

  @Authentication.start()
