class Storage
  store: window.localStorage

  log: (action, key) ->
    # console.log "storage:#{action}:#{key}"

  clear: ->
    @store.clear()

  set: (key, value) ->
    value = if typeof value isnt String
      JSON.stringify value

    @log "set", key
    @store.setItem key, value

  get: (key) ->
    @log "get", key
    JSON.parse @store.getItem key

  remove: (key) ->
    @store.removeItem key

  exist: (key) ->
    @store.hasOwnProperty key

  list: ->
    _.keys @store
