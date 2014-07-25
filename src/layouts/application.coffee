class AppLayout extends Backbone.Marionette.Layout
  el: "body"
  template: "layouts/application"

  regions:
    header:   "#header-region"
    calendar: "#calendar-region"
    dialog:   "#dialog-region"
    popover: PopoverRegion.extend el: "#popover-region"
