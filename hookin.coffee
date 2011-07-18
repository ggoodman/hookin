module.exports = (object) ->
  hooks = {}
  props = {}
  
  api =
    before: (query, cb) -> @on("before:#{query}", cb)
    after: (query, cb) -> @on("after:#{query}", cb)
    on: (query, cb) ->
      hooks[query] = [] unless hooks[query]
      hooks[query].push(cb)
      
      @

  trigger = (query, args...) ->
    if hooks[query]
      for cb in hooks[query]
        ret = cb.apply(object, args)
    ret
      
  augment = (object, prefix) ->  
    prefix ||= ''
    
    # Cache the 'real' object properties
    for own key of object
      do (key) ->
        descriptor = Object.getOwnPropertyDescriptor(object, key)
        props[key] = descriptor.value
        
        #console.log "Type of", descriptor, typeof descriptor.value
        
        switch typeof descriptor.value
          when "function"
            object[key] = (args...) ->
              trigger "before:call:#{key}", args
              props[key].apply(object, args)
              trigger "call:#{key}", args
              
          when "string", "int", "float"
            Object.defineProperty object, key,
              get: ->
                trigger "read:#{key}", props[key]
                props[key]
              set: (value) ->
                oldValue = props[key]
                rejected = false
                if value != oldValue
                  trigger "before:change:#{key}",
                    value: value
                    oldValue: oldValue
                    change: (newValue) -> value = newValue
                    reject: (yesNo) -> rejected = yesNo != false
                  unless rejected
                    props[key] = value
                    trigger "change:#{key}",
                      value: value
                      oldValue: oldValue

          
      #    console.log "Function"
      
      #console.log "Property:", key, descriptor
  
  augment(object)
  api
