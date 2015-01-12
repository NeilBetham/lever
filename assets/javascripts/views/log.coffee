Lever.LogView = Ember.View.extend
  templateName: 'job/log'
  log: null
  logEngine: null

  didInsertElement: ->
    @_super()
    @setupLogEngine()

  willDestroyElement: ->
    @teardownLogEngine()

  setupLogEngine: ->
    console.log 'setting up log engine'
    @set 'logEngine', window.Log.create()
    @handleLogUpdates()

  logWillChange: (->
    console.log 'log changing...'
    @teardownLogEngine()
  ).observesBefore 'log'

  logDidChange: (->
    console.log 'log changed'
    if @get 'log'
      @setupLogEngine()
      @rerender() if @get('_state') == 'inDOM'
    else
      console.log 'log is null'
  ).observes 'log'

  teardownLogEngine: ->
    if log = @get('log')
      parts = log.get 'parts'
      parts.removeArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
    else
      console.log 'log is null'

  handleLogUpdates: ->
    if log = @get('log')
      parts = log.get 'parts'
      parts.addArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
      parts = parts.slice(0)
      @partsDidChange(parts, 0, null, parts.length)
    else
      console.log 'log is null'

  partsDidChange: (parts, start, _, added)->
    for part, i in parts.slice(start, start + added)
      # console.log "limit in log view: #{@get('limited')}"
      @logEngine.set(part.index, part.content)

  noop: ->
