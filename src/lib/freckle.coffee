
class Freckle

  # ------------------------------------------------------------------------------------------------

  class Cache
    store: window.localStorage

    clear: ->
      @store.clear()

    set: (key, value) ->
      value = if typeof value isnt String
        JSON.stringify value
      @store.setItem key, value

    get: (key) ->
      JSON.parse @store.getItem key

    initialize: (@options) ->

  # ------------------------------------------------------------------------------------------------

  class Project
    constructor: (@parent, @resource) ->
    index: (params) ->
      @parent.api
        method: "GET"
        url: @parent.url() + "/#{@resource}.json"
        resource: @resource
        callback: params.success

  # ------------------------------------------------------------------------------------------------

  class Entry
    constructor: (@parent, @resource) ->
    search: (params) ->
      @parent.api
        method: "GET"
        url: @parent.url() + "/#{@resource}.json"
        resource: @resource
        data:
          "search[projects]": params.projects?.join ","
          "search[tags]": params.tags?.join ","
          "search[billable]": params.billable
          "search[to]": params.to
          "search[from]": params.from
          "search[people]": params.people?.join ","
        callback: params.success

    create: (params) ->
      @parent.api
        method: "POST"
        resource: @resource
        url: @parent.url() + "/#{@resource}.json"
        data: entry: _.omit params, "success"
        callback: params.success

    delete: (params) ->
      @parent.api
        method: "DELETE"
        resource: @resource
        url: @parent.url() + "/#{@resource}/#{params.id}"
        callback: params.success


  # ------------------------------------------------------------------------------------------------

  class User
    constructor: (@parent, @resource) ->
    self: (params) ->
      @parent.api
        url: @parent.url() + "/#{@resource}/self"
        resource: @resource
        method: "GET"
        callback: params.success

  # ------------------------------------------------------------------------------------------------

  url: -> "https://#{@options.subdomain}.letsfreckle.com/api"

  api: (options) ->
    requestIdentifier = "#{@options.token}.#{options.resource}#{if options.data? then ('.' + $.param options.data) else ''}"
    timestamp = @_cache.get "#{requestIdentifier}.timestamp"
    timeDelta = (Date.now() - timestamp)
    maxCacheAge = (1000 * 60 * 10)

    if timestamp? and !(timeDelta > maxCacheAge)
      console.log "#{options.resource}:cache:hit", "aged #{timeDelta / 1000}s"
      options.callback.call @, @_cache.get "#{requestIdentifier}.response"
    else
      console.log "#{options.resource}:cache:miss", "aged #{timeDelta / 1000}s"

      $.ajax
        url: options.url
        data: $.extend {}, options.data, token: @options.token
        method: options.method
        success: (response, status, xhr) =>
          @_cache.set "#{requestIdentifier}.response", response
          @_cache.set "#{requestIdentifier}.timestamp", Date.now()
          options.callback.apply @, arguments

  # ------------------------------------------------------------------------------------------------

  constructor: (@options) ->
    @projects = new Project @, "projects"
    @entries = new Entry @, "entries"
    @users = new User @, "users"
    @_cache = new Cache
