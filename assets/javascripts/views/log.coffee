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
    @set 'logEngine', window.Log.create()
    @handleLogUpdates()

  logWillChange: (->
    @teardownLogEngine()
  ).observesBefore 'log'

  logDidChange: (->
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
