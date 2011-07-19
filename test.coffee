vows = require 'vows'
assert = require 'assert'
hookin = require './hookin'

suite = vows.describe("Hookin").addBatch
  "Accessors":
    topic: ->
      user = { name: "John Doe", password: "password" }
      hookin(user)
      user
    
    "Name is John Doe": (result) ->
      assert.equal result.name, "John Doe"
    
    "Read callback":
      topic: ->
        user = { name: "John Doe", password: "password" }
        hookin(user).on 'read:name', this.callback
        #console.log "User", user, user.name
        bar = user.name
        return
      "Called the read callback": (topic) ->
        console.log "Topic", topic
        #assert.equal topic.value, "John Doe"

suite.run()
