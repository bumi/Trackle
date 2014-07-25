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
