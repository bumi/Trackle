
Mole.module "Header", (Module, App) ->
  @startWithParent = false

  class DateItemView extends Marionette.ItemView
    template: "header/calendar-item"
    tagName: "li"
    className: -> "today" if @model.get("date") is moment().format("YYYY-MM-DD")

  class HeaderView extends Marionette.CompositeView
    tagName: "div"
    className: "header"
    itemView: DateItemView
    itemViewContainer: ".calendar-header"
    template: "header/header-view"
    modelEvents:
      sync: "render"

  @addInitializer =>
    @headerView = new HeaderView
      model: App.user
      collection: new Backbone.Collection

    App.layout.header.show @headerView

    App.vent.on "weekCollection:change:index", (week) =>
      @headerView.collection.reset week.get("days").toJSON()

