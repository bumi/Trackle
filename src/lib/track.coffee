class Track
  _send: (resource, data) ->
    data["timestamp"] = moment().format()
    data["user"] = @user

    console.log "track#{resource}"

    @unirest.post @serviceUrl + resource
      .headers "Content-Type": 'application/json'
      .send data
      .end (response) ->
        console.error response.error if response.error

  constructor: (@serviceUrl) ->
    @unirest = require "unirest"

  setUser: (@user) ->

  event: (key, payload = {}) ->
    @_send "/events", { key, payload }
