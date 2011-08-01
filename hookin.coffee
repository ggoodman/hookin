class Hookin
  @augmentFunction: (obj, prop) ->
    api = this
    
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
        
        decorators = obj._hookin.decorators[prop] or []
        # This is the closure that will be added to the bottom of the decorator stack
        # and will be called last (innermost)
        final = ->
          # Call the stashed, original function
          obj._hookin.properties[prop].apply(obj, opts.arguments)
          
          # Remove the mutable api since the call has already been made
          delete opts.cancelled
          delete opts.cancel
          delete opts.change
          delete opts.execute
          
          # Trigger the normal callbacks that do not allow rejection and/or changes
          api.trigger "call:#{prop}", opts
        
        # Build the decorator stack adding the decorators on top of the final closure
        stack = [final].concat(decorators)
        
        # The next function that will pop off the stack
        opts.next = ->
          stack.pop().call(obj, opts)
        opts.next()
          
        
  
  @augmentLiteral: (obj, prop) ->
    api = this
    
    Object.defineProperty obj, prop,
      get: ->
        opts =
          property: prop
          value: obj._hookin.properties[prop]
          change: (newValue) -> opts.value = newValue
        
        # Trigger the callbacks for the read event
        api.trigger "read:#{prop}", opts
        
        # Return the final value
        opts.value
      
      set: (value) ->
        opts =
          property: prop
          value: value
          oldValue: obj._hookin.properties[prop]
          cancelled: false
          change: (newValue) -> opts.value = newValue
          cancel: (cancel) -> opts.cancelled = cancel != false
        
        # TBD: Do we prevent the event from firing if the old value is the new value?
        if opts.value != opts.oldValue
          api.trigger "before:change:#{prop}", opts
          
          # The before:change callbacks can cancel the change by calling opts.cancel()
          unless opts.cancelled
            obj._hookin.properties[prop] = opts.value
            
            # Remove the mutable part of the change api
            delete opts.cancelled
            delete opts.change
            delete opts.cancel
            
            # Trigger the normal change callbacks
            api.trigger "change:#{prop}", opts

  constructor: (target) ->
    self = @

    target._hookin ||=
      hooks: {}
      properties: {}
      decorators: {}
    
    self.hooks = target._hookin.hooks
    self.properties = target._hookin.properties
    self.decorators = target._hookin.decorators
    
    # Loop through own keys (ignoring those beginning with '_') and augment them
    for own key, value of target when key[0] != "_"
      do (key, value) ->
        # Stash the old value in the properties hash
        self.properties[key] = value
        
        switch typeof value
          when 'function' then Hookin.augmentFunction.call(self, target, key)
          when 'string', 'int', 'float' then Hookin.augmentLiteral.call(self, target, key)
          
  before: (query, cb) => @on("before:#{query}", cb)
  #after: (query, cb) => @on("after:#{query}", cb)
  decorate: (query, cb) =>
    @decorators[query] ||= []
    @decorators[query].push(cb)
    @ 
  on: (query, cb) =>
    @hooks[query] ||= []
    @hooks[query].push(cb)
    @
  trigger: (query, opts) =>
    cb(opts) for cb in @hooks[query] when not opts.cancelled if @hooks[query]
    @

 
module.exports = (target) -> new Hookin(target)