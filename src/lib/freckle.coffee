class Freckle

  on: (event, handler) ->
    @_events ?= {}
    (@_events[event] ?= []).push handler
    this

  off: (event, handler) ->
    @_events ?= {}
    for suspect, index in @_events[event] when suspect is handler
      @_events[event].splice index, 1
    this

  do: (event, args...) ->
    @_events ?= {}
    return this unless @_events[event]?
    handler.apply this, args for handler in @_events[event]
    this

  class Resource
    constructor: (options) ->
      { parent, name, methods } = options

      for method, methodOptions of methods
        do (methodOptions, name, method) =>

          @[method] = (args..., callback) ->
            [payload, options] = args

            options or= {}
            if options.cache is false
              methodOptions.cache = false

            throw "token required" unless parent.options.token?
            throw "callback required" unless callback?

            storage = parent.options.storage
            storageKey = "request:#{name}:#{method}"
            timestamp = storage.get "#{storageKey}:timestamp"
            timeDelta = (Date.now() - timestamp)
            timeDeltaFriendly = Math.round (timeDelta / 1000 / 60)
            maxCacheAge = (1000 * 60 * 10) # 10mins

            if methodOptions.cache and timestamp? and !(timeDelta > maxCacheAge)
              # console.log "#{storageKey}:cache:hit", "aged #{timeDeltaFriendly}m"
              callback.call this, false, storage.get "#{storageKey}:response"

            else
              # console.log "#{storageKey}:cache:miss", "aged #{timeDeltaFriendly}m"
              console.log "#{storageKey}:force" if options.cache is false


              if methodOptions.required? and !payload[methodOptions.required]?
                throw "ArgumentError: #{methodOptions.required} is required"

              url = if methodOptions.required?
                _url = "#{parent.urlRoot()}/#{name}/#{payload[methodOptions.required]}#{if methodOptions.fragment? then "/#{methodOptions.fragment}" else ""}.json"
                payload = _.omit payload, methodOptions.required
                _url
              else
                "#{parent.urlRoot()}/#{name}#{if methodOptions.fragment? then "/#{methodOptions.fragment}" else ""}.json"

              requestMethod = (methodOptions.method || "GET").toLowerCase()
              requestCargo = if requestMethod is "get" then "qs" else "send"
              parent.do "before:sync"

              request = parent.api[requestMethod] url

              request.headers
                "Content-Type": "application/json"
                "X-FreckleToken": parent.options.token

              request[requestCargo] payload

              request.end (response) ->
                console.log requestMethod, payload, url
                storage.set "#{storageKey}:response", response.body
                storage.set "#{storageKey}:timestamp", Date.now()

                if response.error
                  console.error response.error, response, payload

                callback.call this, response.error, response.body, response
                parent.do "sync"

  urlRoot: -> "https://#{@options.subdomain}.letsfreckle.com/api"

  setupResources: ->
    @users = new Resource
      parent: @
      name: "users"
      methods:
        list:     { cache: true,                                     }
        show:     { cache: true, required: "id"                      }
        self:     { cache: true,                 fragment: "self"    }
        avatar:   { cache: true, required: "id", fragment: "avatar"  }

    @projects = new Resource
      parent: @
      name: "projects"
      methods:
        list:     { cache: true,                                     }
        show:     { cache: true, required: "id"                      }

    @entries = new Resource
      parent: @
      name: "entries"
      methods:
        list:     { cache: true,                                     }
        create:   { cache: false,                 method: "POST"     }
        update:   { cache: false, required: "id", method: "PUT"      }
        delete:   { cache: false, required: "id", method: "DELETE"   }

    @do "ready"

  authenticate: (user, pass) ->
    @api.get("#{@urlRoot()}/user/api_auth_token.json")
      .auth
        user: user
        pass: pass
      .end (response) =>
        if response.error
          @do "authentication:error", response.error
        else
          @options.token = response.body.user.api_auth_token
          @setupResources()
          @do "authentication:success", token: @options.token, subdomain: @options.subdomain

  constructor: ->
    @api = require "unirest"
    @options = {}

  initialize: (@options = {}) ->
    if @options.subdomain and @options.token
      @setupResources()

# freckle = new Freckle
#   subdomain: "railslove"
#   token: "jagzeek0wsnfmnfhuntigxv3be6qqc3"

# freckle.authenticate "philipp@railslove.com", "denkdichfrei", (err, data) ->

# freckle.users.list              (err, data) -> console.log arguments

# freckle.users.show   id: 13896, (err, data) -> console.log arguments
# freckle.users.self              (err, data) -> console.log arguments
# freckle.users.avatar id: 13896, (err, data) -> console.log arguments

# freckle.projects.list             (err, data) -> console.log arguments
# freckle.projects.show id: 146954, (err, data) -> console.log arguments

# freckle.entries.list             (err, data) -> console.log arguments

# freckle.entries.list
#   "search[people]": "13896"
# , (err, data) -> console.log arguments

# freckle.entries.create
#   entry:
#     date: "2014-04-04"
#     allow_hashtags: "false"
#     minutes: "60"
#     description: "test"
#     project_id: "146954"
# , (err, data) -> console.log arguments

# freckle.entries.update
#   id: 5831332
#   entry:
#     description: "test updated"
# , (err, data) -> console.log arguments

# freckle.entries.delete
#   id: 5831332
# , (err, data) -> console.log arguments

