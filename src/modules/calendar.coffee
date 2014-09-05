
Mole.module "Calendar", (Module, App) ->
  @startWithParent = false

  # -----------------------------------------------------------------------

  class EntryItemEditView extends Marionette.ItemView
    tagName: "div"
    className: "popover"

    behaviors:
      KeyEvents:
        escape: ->
          App.layout.popover.closeDialog()
          App.tracker.event "entry:close:via-key"

    template: "entry/edit-view"

    modelEvents:
      destroy: -> App.layout.popover.closeDialog()
      change: -> @model.needsSave = true

    events:
      "click .remove": (e) ->
        e.preventDefault()
        @model.destroy()
        App.tracker.event "entry:remove:via-click"

    bindings:
      "#popover-minutes": "minutes"
      "#popover-minutes-formatted":
        observe: 'minutes'
        onGet: (value, options) ->
          value = parseInt value, 10
          prettyValue = if value >= 60 then (value / 60) else value
          unit = switch
            when value < 60 then "Minutes"
            when value is 60 then "Hour"
            when value > 60 then "Hours"
          "#{prettyValue} #{unit}"

      "#popover-description": "description"
      "#popover-project":
        observe: "project_id"
        initialize: ($el) ->
          format = (project) ->
            return project.text unless project.id
            _.template """
              <div class="jeez" style="background-color: ##{App.projects.get(project.id).get("color_hex")};"></div>
              <span class="<% if(!#{App.projects.get(project.id).get("billable")}){ %> unbillable <% } %>"> #{project.text} </span>
            """

          $el.select2
            formatResult: format
            formatSelection: format
            escapeMarkup: (m) -> m

        destroy: ($el) ->
          $el.select2("destroy")

        selectOptions:
          collection: ->
            opt_labels: ["Recent Projects", "Other Projects"]
            "Recent Projects": App.projects.recents.toJSON()
            "Other Projects": App.projects.other.toJSON()

          labelPath: "name"
          valuePath: "id"

    onRender: ->
      @stickit()

    initialize: ->
      @model.needsSave = false

    onClose: ->
      if @model.needsSave
        @model.save()
      else if @model.isNew()
        @model.destroy()
        App.tracker.event "entry:remove:was-empty"

  # -----------------------------------------------------------------------

  class Entry extends Backbone.Model
    defaults:
      allow_hashtags: false
      billable: true

    select: ->
      @set selected: true
    deselect: ->
      @set selected: false

    parse: (item) -> item.entry

    sync: (method, model, options) ->
      payload = entry: model.toJSON()
      payload.id = payload.entry.id if method is "update" or method is "delete"

      model.trigger 'request', model, options
      App.Authentication.freckle.entries[method] payload, (err, response, fullResponse) ->
        if err
          options.error.call this, response
          Module.weekCollection.fetch cache: false
        else
          if method is "create"
            model.set id: fullResponse.headers.location.match(/\d+/).pop()
          options.success.call this, response

    initialize: ->
      @on @events
      @set date: @collection.date

    events:
      "change:project_id": (model, project_id) ->
        project = App.projects.get(project_id).toJSON()
        @set
          project: project
          unbillable: !project.billable

  class EntryCollection extends Backbone.Collection
    model: Entry
    events:
      remove: (model) ->
        model.once "sync", -> Module.weekCollection.fetch cache: false

    addEntry: ->
      randomProjectId = _.sample @pluck "project_id"
      randomProjectId or= _.sample(App.projects.recents.models).id

      model = @add
        minutes: 60
        project_id: randomProjectId
        project: App.projects.get(randomProjectId).toJSON()
        allow_hashtags: false

      model.trigger "edit"
      App.tracker.event "entry:add"

    minutes: ->
      @pluck("minutes").reduce ((a, b) -> a + b), 0

    initialize: -> @on @events

  class EntryItemView extends Marionette.ItemView
    tagName: "li"
    className: ->
      name = "entry"
      name += " unbillable" unless @model.get("billable")
      name += " unsaved" if @model.isNew()
      name += " minutes-#{@model.get("minutes")}"
      name

    template: "entry/item-view"
    templateHelpers: =>
      projectColor: =>
        "##{App.projects.get(@model.get("project_id"))?.get("color_hex")}"
      tags: =>
        if @model.get("description")
          _.uniq(@model.get("description").toLowerCase().replace(/[!#]/g, "").split(", "))

    attributes: ->
      style: "height: #{@calcHeight()};"

    calcHeight: ->
      "#{(@model.get('minutes') / (60 * 10)) * 100}%"

    modelEvents:
      change: "render"
      edit: "showEditView"

      "change:unbillable": (model, unbillable) ->
        @$el.toggleClass "unbillable", unbillable

      "change:id": (model, id) ->
        @$el.removeClass "unsaved"

      "change:selected": (model, selected) ->
        @$el.toggleClass "selected", selected

      "change:minutes": ->
        @$el.css height: @calcHeight()
        @el.className = @className()

    events:
      previewFromDrag: (_, previewFromDrag) ->
        @model.set minutes: previewFromDrag.minutes

      updateFromDrag: (_, updateFromDrag) ->
        @model.set minutes: updateFromDrag.minutes
        @model.save()
        App.tracker.event "entry:resized"

      dblclick: "showEditView"

      click: ->
        @model.set selected: true

    showEditView: (e) ->
      e?.stopPropagation()

      App.tracker.event "entry:edit" unless @model.isNew()

      if App.layout.popover.currentView
        App.layout.popover.closeDialog()
      else
        popoverView = new EntryItemEditView
          model: @model
          target: @$el

        App.layout.popover.show popoverView
        $(document).on "click", "#calendar-region, #header-region", ->
          App.layout.popover.closeDialog()
          $(document).off "click", "#calendar-region, #header-region"

  class EntryCompositeView extends Marionette.CompositeView
    tagName: "li"
    className: ->
      className = "day"
      className += " today" if @model.get("date") is moment().format("YYYY-MM-DD")
      className

    itemView: EntryItemView
    itemViewContainer: ".entries-list"
    template: _.template """
      <ul class="entries-list"></ul>
      <div class="summed-hours">
        <%= minutes() / 60 %> Hours
      </div>
    """
    templateHelpers: =>
      minutes: => @collection.minutes()

    initialize: (attributes) ->
      @collection = attributes.model.get "entries"

    events:
      dblclick: "addEntry"

    addEntry: ->
      @collection.addEntry()

  class Day extends Backbone.Model
    initialize: (attributes) ->
      entries        = new EntryCollection attributes.entries, parse: true
      entries.date   = @get "date"
      entries.moment = @get "moment"
      entries.on "change:selected", (entry, selected) =>
        @trigger "entry:change:selected", entry, selected

      @set entries: entries

  class DayCollection extends Backbone.Collection
    model: Day
    today: -> @findWhere date: moment().format("YYYY-MM-DD")

  class DayCompositeView extends Marionette.CompositeView
    tagName: "li"
    className: "week"
    itemView: EntryCompositeView
    itemViewContainer: ".days-list"
    template: _.template """
      <ul class="days-list"></ul>
    """
    initialize: (attributes) ->
      @collection = attributes.model.get "days"

  class Week extends Backbone.Model
    initialize: (attributes) ->
      days = new DayCollection attributes.days
      days.on "entry:change:selected", (entry, selected) =>
        @trigger "entry:change:selected", entry, selected

      @set days: days

  class WeekCollection extends Backbone.Collection
    model: Week
    sync: (method, model, options) ->
      App.Authentication.freckle.entries.list {
        "search[people]": App.user.id
      }, options, (err, response) ->
        options.success.call this, response

    events:
      "entry:change:selected": (entry, selected) ->
        switch selected
          when true  then @select entry
          when false then @deselect()

    initialize: ->
      @selected = null
      @on @events

    deselect: ->
      return unless @selected
      @selected.set selected: false
      @selected = null

    select: (model) ->
      return if model is @selected

      if @selected?
        @selected.set selected: false

      model.set selected: true
      @selected = model

    parse: (response) ->
      moment.lang('de')
      groupedEntries = _.groupBy response, (item) -> item.entry.date
      dates          = Object.keys groupedEntries

      entriesStart = moment(dates[dates.length-1]).startOf('week')
      entriesEnd   = moment().endOf "week"
      entriesRange = moment().range entriesStart, entriesEnd
      weeks        = []

      entriesRange.by "weeks", (weekStart) ->
        weekEnd   = weekStart.clone().endOf "week"
        weekRange = moment().range weekStart, weekEnd
        days      = []

        weekRange.by "days", (day) ->
          formattedMoment = day.format "YYYY-MM-DD"
          days.push
            moment: day
            date: formattedMoment
            entries: groupedEntries[formattedMoment] || []

        weeks.unshift
          isoWeek: weekStart.isoWeek()
          days: days

      return weeks

  class WeekCollectionView extends Marionette.CollectionView
    tagName: "ul"
    className: "weeks-list"
    itemView: DayCompositeView
    behaviors:
      KeyEvents:
        backspace: ->
          selected = @collection.selected
          if selected?
            selected.destroy()
            selected.deselect()
            App.tracker.event "entry:remove:via-key"

    currentWeek: ->
      @collection.at(@weekIndex) || null

    collectionEvents:
      sync: ->

        _.delay =>
          @drawLines()
          @scrollWeekTo 0, false
        , 100

        App.options.nwWindow.on "resize", _.throttle =>
          @drawLines()
        , 10

        App.options.nwWindow.on "resize", => @scrollWeekTo @weekIndex, false

    events:
      click: (e) ->
        unless $(e.target).hasClass "entry"
          @collection.selected?.deselect()

    initialize: ->
      @weekIndex = 0
      App.vent.on "calendar-navigation:prev",  => @scrollWeekBy 1
      App.vent.on "calendar-navigation:today", => @scrollWeekTo 0
      App.vent.on "calendar-navigation:next",  => @scrollWeekBy -1

    scrollWeekBy: (amount) -> @scrollWeekTo @weekIndex + amount

    scrollWeekTo: (index = 0, animate = true) ->
      if index < 0
        $('.weeks-list').animate { paddingRight: '50px'}, 100, ->
          $('.weeks-list').animate { paddingRight: '0px'}, 200
      else
        index = if index >= @collection.length then @collection.length-1 else index
        
        weekWidth = @$el.width()
        fullWidth = weekWidth * @collection.length
        scrollPosition = fullWidth - (weekWidth * (index + 1))
        console.log index, weekWidth, fullWidth, scrollPosition
          
        if animate
          @$el.stop(false, true).animate {scrollLeft: scrollPosition}, =>
            @weekIndex = index
            App.vent.trigger "weekCollection:change:index", @collection.at @weekIndex
        else
          @$el.prop "scrollLeft", scrollPosition
          App.vent.trigger "weekCollection:change:index", @collection.at @weekIndex

    cyclicRedraw: =>
      @drawLines()
      setTimeout @cyclicRedraw, (60 - (new Date()).getSeconds()) * 1000 + 5

    drawLines: ->
      [elWidth, elHeight] = [@$el.width(), @$el.height()]
      day   = document.getCSSCanvasContext  '2d', 'day' , elWidth, elHeight
      week  = document.getCSSCanvasContext  '2d', 'week', elWidth, elHeight
      today = document.getCSSCanvasContext  '2d', 'now' , elWidth, elHeight

      day.clearRect   0, 0, elWidth, elHeight
      week.clearRect  0, 0, elWidth, elHeight
      today.clearRect 0, 0, elWidth, elHeight
      index = 10

      minutesSinceMidnight = (new Date() - new Date().setHours(0, 0, 0, 0)) / 1000 / 60
      # minus nine hours
      minutesSinceMidnight -= (9 * 60)
      # calculate height per minute
      minuteHeight = elHeight / (10 * 60)

      hourNumberingCenter = window.innerWidth / 10 / 2

      now = minuteHeight * minutesSinceMidnight
      now = Math.round now
      now += 0.5

      today.beginPath()
      today.strokeStyle = "#FB1500"
      today.moveTo 0, now
      today.lineTo elWidth, now
      today.stroke()

      today.beginPath()
      today.fillStyle = "#FB1500"
      today.moveTo 3, now
      today.arc $(".day").width() + 2, now, 2, 0, Math.PI * 2, true
      today.arc 2, now, 2, 0, Math.PI * 2, true
      today.fill()

      for y in [0..elHeight] by (elHeight / 10)

        y += (elHeight / 10)
        y = Math.round y
        y += 0.5

        # strong line
        day.beginPath()
        day.strokeStyle = "#d7dde8"
        day.moveTo 0, y
        day.lineTo elWidth - 1, y
        day.stroke()

        # dashed line
        day.beginPath()
        day.setLineDash [1, 2]
        day.strokeStyle = "#d7dde8"
        day.moveTo 0, Math.round(y - (elHeight / 10) / 2) + 0.5
        day.lineTo elWidth - 1, Math.round(y - (elHeight / 10) / 2) + 0.5
        day.stroke()

        day.setLineDash [0, 0]

        if index < 19
          week.font = '10px sans-serif'
          week.textAlign = 'center'
          week.textBaseline = 'middle'
          week.fillStyle = "#858a92"
          week.fillText "#{index}:00", hourNumberingCenter, y

        index++

      week.fillStyle = "#FFFFFF"
      # cheap outline above and below
      week.fillText moment().format("HH:mm"), hourNumberingCenter, now - 1
      week.fillText moment().format("HH:mm"), hourNumberingCenter, now + 1

      week.fillStyle = "#FB1500"
      week.fillText moment().format("HH:mm"), hourNumberingCenter, now

  @addInitializer =>
    @weekCollection     = new WeekCollection()
    @weekCollectionView = new WeekCollectionView
      collection: @weekCollection
    App.layout.calendar.show @weekCollectionView

    collectionArray =
      App.storage.get("request:entries:list:response") ||
      [{ days: [{}, {}, {}, {}, {}, {}, {}] }]

    @weekCollection.set collectionArray,
      parse: App.storage.exist("request:entries:list:response")

    @weekCollection.trigger "sync"

    callback = _.after 2, =>
      @weekCollection.fetch cache: false
      @weekCollectionView.cyclicRedraw()

    App.user.once     'sync', callback
    App.projects.once 'sync', callback

    App.vent.on "menu:new-entry", =>
      currentWeek = @weekCollectionView.currentWeek()
      if currentWeek?
        today = currentWeek.get("days").today()
        entries = today.get "entries"
        entries.addEntry()

    App.vent.on "menu:edit-entry", =>
      selected = @weekCollectionView.collection.selected
      if selected?
        selected.trigger "edit"
