crypto = require 'crypto'
hookin = require './hookin'

test = 
  name: 'Geoff Goodman'
  site: 'http://github.com/ggoodman/'
  password: "Its a secret"
  failSecurity: ->
    console.log "PASSWORD FOR #{@name} IS #{@password} OKTHX"

hook = hookin(test)
  # Prevent the mis-use of one-name wonders.
  .before 'change:name', (event) ->
    event.cancel() unless event.value.split(' ').length > 1
  .decorate 'failSecurity', (event) ->
    console.log "> Layer 1"
    event.next()
    console.log "< Layer 1"
  .decorate 'failSecurity', (event) ->
    console.log "> Layer 2"
    event.next()
    console.log "< Layer 2"
  .decorate 'failSecurity', (event) ->
    console.log "> Layer 3"
    event.next()
    console.log "< Layer 3"
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