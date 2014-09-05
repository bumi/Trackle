
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

    ui:
      prev: ".calendar-navigation .prev"
      today: ".calendar-navigation .today"
      next: ".calendar-navigation .next"

    events:
      "click @ui.prev":  -> App.vent.trigger "calendar-navigation:prev"
      "click @ui.today": -> App.vent.trigger "calendar-navigation:today"
      "click @ui.next":  -> App.vent.trigger "calendar-navigation:next"

    modelEvents:
      sync: "render"

  @addInitializer =>
    @headerView = new HeaderView
      model: App.user
      collection: new Backbone.Collection

    App.layout.header.show @headerView

    App.vent.on "weekCollection:change:index", (week) =>
      @headerView.collection.reset week.get("days").toJSON()