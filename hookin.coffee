module.exports = (target) ->
  target._hookin ||=
    hooks: {}
    properties: {}
  
  # This will be our local shortcut to the hookin cache
  h = target._hookin
  
  # Fluid API that will be returned by the hookin method
  api =
    before: (query, cb) -> @on("before:#{query}", cb)
    after: (query, cb) -> @on("after:#{query}", cb)
    on: (query, cb) ->
      h.hooks[query] ||= []
      h.hooks[query].push(cb)
      @
    trigger: (query, opts) ->
      cb(opts) for cb in h.hooks[query] when not opts.cancelled if h.hooks[query]
      @
  
  augmentFunction = (obj, prop) ->
    obj[prop] = (args...) ->
      opts = 
        arguments: args
        property: prop
        cancelled: false
        cancel: (cancel) -> opts.cancelled = cancel != false
        change: (newArgs...) -> opts.args = newArgs
        
      # Trigger the before callbacks allowing rejection and/or changes
      api.trigger "before:call:#{prop}", opts

      # The before:call callbacks can cancel the ultimate call by calling opts.cancel()
      unless opts.cancelled
        # Call the stashed, original function
        h.properties[prop].apply(obj, opts.arguments)
        
        # Remove the mutable api since the call has already been made
        delete opts.cancelled
        delete opts.cancel
        delete opts.change
        
        # Trigger the normal callbacks that do not allow rejection and/or changes
        api.trigger "call:#{prop}", opts
  
  augmentLiteral = (obj, prop) ->
    Object.defineProperty obj, prop,
      get: ->
        opts =
          property: prop
          value: h.properties[prop]
          change: (newValue) -> opts.value = newValue
        
        # Trigger the callbacks for the read event
        api.trigger "read:#{prop}", opts
        
        # Return the final value
        opts.value
      
      set: (value) ->
        opts =
          property: prop
          value: value
          oldValue: h.properties[prop]
          cancelled: false
          change: (newValue) -> opts.value = newValue
          cancel: (cancel) -> opts.cancelled = cancel != false
        
        # TBD: Do we prevent the event from firing if the old value is the new value?
        if opts.value != opts.oldValue
          api.trigger "before:change:#{prop}", opts
          
          # The before:change callbacks can cancel the change by calling opts.cancel()
          unless opts.cancelled
            h.properties[prop] = opts.value
            
            # Remove the mutable part of the change api
            delete opts.cancelled
            delete opts.change
            delete opts.cancel
            
            # Trigger the normal change callbacks
            api.trigger "change:#{prop}", opts
          
  
  # Loop through own keys (ignoring those beginning with '_') and augment them
  for own key, value of target when key[0] != "_"
    do (key, value) ->
      # Stash the old value in the properties hash
      h.properties[key] = value
      
      switch typeof value
        when 'function' then augmentFunction(target, key)
        when 'string', 'int', 'float' then augmentLiteral(target, key)
        
  # Return the generated api to work with
  return api