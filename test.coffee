###
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
###
crypto = require 'crypto'
hookin = require './hookin'

test = 
  name: 'Geoff Goodman'
  site: 'http://github.com/ggoodman/'
  password: "Its a secret"
  failSecurity: ->
    console.log "PASSWORD FOR #{@name} IS #{@password} OKTHX"

hookin(test)
  # Prevent the mis-use of one-name wonders.
  .before 'change:name', (event) ->
    event.cancel() unless event.value.split(' ').length > 1
  # Log name changes
  .on 'change:name', (event) ->
    console.log "Changed name from #{event.oldValue} to #{event.value}."
  .on 'read:password', (event) ->
    hash = crypto.createHash('md5')
      .update("SALT" + event.value)
      .digest('hex')
    event.change(hash)

test.name = "Madonna" # No good; cancelled by the before:change event
test.failSecurity()