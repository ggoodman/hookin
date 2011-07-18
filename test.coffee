vows = require 'vows'
hookin = require './hookin'

test = 
  name: 'ggoodman'
  site: 'http://github.com/ggoodman/'
  exclaim: ->
    console.log "WHY NOT?! MY NAME IS #{@name.toUpperCase()}"

hookin(test)
  .before 'change:name', (event) ->
    if event.value != 'pgoodman'
      console.log "Wrong name sucka!"
      event.reject()
  .on 'change:name', (event) ->
    console.log "Changed name from #{event.oldValue} to #{event.value}."
  .on 'change:site', (event) ->
    console.log "Changed name from #{event.oldValue} to #{event.value}."
  .before 'call:exclaim', ->
    console.log "No shouting!"


test.name = "agoodman"
test.name = "pgoodman"
test.exclaim()
