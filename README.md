Hookin
======

Hookin is a library that allows you to turn regular object literals into event
driven machines. The API allows you to intercept changes to property values
and calls to methods.

## Example

```coffee-script
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
```

Output:
```
PASSWORD FOR Geoff Goodman IS 7c28ece7bf8aa43735f94601ea6dbc50 OKTHX
```
