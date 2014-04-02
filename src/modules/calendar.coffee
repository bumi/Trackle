
Mole.module "Calendar", (Module, App) ->
  @startWithParent = false

  # -----------------------------------------------------------------------

  class Entry extends Backbone.Model
    defaults: ->
      formatted_description: ""

    parse: (item) -> item.entry

    sync: (method, model, options) ->
      console.log arguments
      App.freckle.entries[method] _.extend model.toJSON(), options.success

  # -----------------------------------------------------------------------

  class EntryCollection extends Backbone.Collection
    model: Entry
    minutes: ->
      @pluck("minutes").reduce ((a, b) -> a + b), 0

  # -----------------------------------------------------------------------

  class EntryItemView extends Marionette.ItemView
    template: "entry/item-view"
    tagName: "li"
    className: ->
      className = "entry"
      className += if @model.get("billable") then "" else " unbillable"
      className += if @model.get("minutes") <= 60 then " small" else ""
      className += if @model.get("minutes") <= 30 then " tiny" else ""
      className

    events:
      click: ->
        console.log @model
        # @model.destroy wait: true

    attributes: ->
      style: "height: #{(@model.get('minutes') / (60 * 8)) * 100}%;"
    templateHelpers: =>
      projectColor: => "##{App.projects[@model.get("project_id")].color_hex}"
      tags: =>
        if @model.get("description")
          _.uniq(@model.get("description").toLowerCase().replace(/[!#]/g, "").split(", "))


  # -----------------------------------------------------------------------

  class Day extends Backbone.Model
    initialize: (options) ->
      { entries } = options
      @set entries: new EntryCollection entries, parse: true

  # -----------------------------------------------------------------------

  class DayCollection extends Backbone.Collection
    model: Day
    parse: (entries) ->
      groupedEntries = _.groupBy entries, (item) -> item.entry.date
      dates = Object.keys groupedEntries

      start = moment(dates[dates.length-1]).startOf('week')
      end   = moment().endOf('week')
      range = moment().range start, end

      days = []

      range.by 'days', (moment) ->
        formattedMoment = moment.format "YYYY-MM-DD"
        days.unshift
          moment: moment
          date: formattedMoment
          entries: groupedEntries[formattedMoment] || []

      return days

    sync: (method, model, options) ->
      App.freckle.entries.search
        people: [App.user.get("id")]
        success: options.success

  # -----------------------------------------------------------------------

  class DayCompositeView extends Marionette.CompositeView
    template: "day/composite-view"
    tagName: "li"
    className: -> "day #{if @model.get("date") is @options.today then "today" else "" }"
    itemView: EntryItemView
    itemViewContainer: ".entry-list-view"
    templateHelpers: =>
      minutes: => @collection.minutes()
      isToday: => @model.get("date") is @options.today

    events:
      click: ->
        entryCollection = @model.get("entries")

        entry = new entryCollection.model
          date: @model.get "date"
          allow_hashtags: false

        entry.schema =
          minutes:
            type: "Text"
            validators: ['required']
          description:
            type: "Text"
            validators: ['required']
          project_id:
            type: 'Select'
            options: _.reduce App.projects, ((memo, item) -> memo[item.id] = item.name; return memo), {}
            validators: ['required']

        form = new Backbone.Form model: entry

        form.render()

        $(document).on "keyup", (e) ->
          if e.which is 27
            form.$el.remove()

        form.$el.on "submit", (e) ->
          e.preventDefault()
          if form.commit() is undefined
            $(document).off "keyup"
            entryCollection.create entry
            setTimeout ->
              Module.refresh()
            , 1000
            form.$el.parent().transit opacity: 0, -> form.$el.remove()

        $(".modal-view")
          .css(opacity: 1)
          .html(form.el)

    initialize: (@options) ->
      @collection = @options.model.get "entries"

  # -----------------------------------------------------------------------

  class DayListView extends Marionette.CollectionView
    itemView: DayCompositeView
    el: ".day-list-view"
    itemViewOptions:
      today: moment().format "YYYY-MM-DD"
    collectionEvents:
      sync: ->
        Module.timeline()

        setInterval ->
          Module.timeline()
        , 1000 * 60

  # -----------------------------------------------------------------------

  @timeline = =>
    console.log "timeline:draw"
    $el      = $(".entry-list-view")
    elWidth  = $el.outerWidth(true)
    elHeight = $el.height()

    ruler       = document.getCSSCanvasContext '2d', 'ruler'  , elWidth, elHeight
    numbers     = document.getCSSCanvasContext '2d', 'numbers', elWidth, elHeight
    currentTime = document.getCSSCanvasContext '2d', 'now'    , elWidth, elHeight
    index       = 10

    ruler.clearRect       0, 0, elWidth, elHeight
    numbers.clearRect     0, 0, elWidth, elHeight
    currentTime.clearRect 0, 0, elWidth, elHeight

    minutesSinceMidnight = (new Date() - new Date().setHours(0, 0, 0, 0)) / 1000 / 60
    # minus ten hours
    minutesSinceMidnight -= (10 * 60)
    # calculate height per minute
    minuteHeight = elHeight / (8 * 60)

    now = minuteHeight * minutesSinceMidnight
    now = Math.round now
    now += 0.5

    currentTime.beginPath()
    currentTime.strokeStyle = "#CD6B69"
    currentTime.moveTo 40, now
    currentTime.lineTo elWidth - 1, now
    currentTime.stroke()

    currentTime.beginPath()
    currentTime.fillStyle = "#CD6B69"
    currentTime.moveTo 0, now
    currentTime.arc 40, now, 4, 0, Math.PI * 2, true
    currentTime.fill()

    currentTime.font = '10px Droid Sans'
    currentTime.textAlign = 'left'
    currentTime.textBaseline = 'middle'
    currentTime.fillStyle = "#CD6B69"
    currentTime.fillText moment().format("HH:mm"), 5, now

    for y in [5..elHeight] by (elHeight / 8) when y isnt 5
      index++
      continue if index is 18

      # round down and add a half-pixel
      # for sharp lines (fuck canvas)
      y = Math.round y
      y += 0.5

      ruler.beginPath()
      ruler.strokeStyle = "#e0e0e0"
      ruler.moveTo 0, y
      ruler.lineTo elWidth - 1, y
      ruler.stroke()

      numbers.beginPath()
      numbers.fillStyle = "#CD6B69"
      numbers.arc 10, y + 0.5, 8, 0, Math.PI * 2, true
      numbers.fill()

      numbers.font = '8px Droid Sans'
      numbers.textAlign = 'center'
      numbers.textBaseline = 'middle'
      numbers.fillStyle = "white"
      numbers.fillText index, 9.5, y + 1

  @refresh = =>
    App.freckle._cache.store.clear()
    @dayCollection.fetch()

  @addInitializer =>
    moment.lang('de')

    @dayCollection = new DayCollection
    @dayListView = new DayListView collection: @dayCollection

    $(window).resize _.debounce ->
      Module.timeline()
    , 300

    @dayCollection.fetch()
