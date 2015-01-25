Lever.LogView = Ember.View.extend
  template: Ember.Handlebars.compile '<div id="log-container"><pre id="log"></pre></div>'
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
  ).observes 'log'

  teardownLogEngine: ->
    if log = @get('log')
      parts = log.get 'parts'
      parts.removeArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')

  handleLogUpdates: ->
    if log = @get('log')
      parts = log.get 'parts'
      parts.addArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
      parts = parts.slice(0)
      @partsDidChange(parts, 0, null, parts.length)

  partsDidChange: (parts, start, _, added)->
    for part, i in parts.slice(start, start + added)
      # console.log "limit in log view: #{@get('limited')}"
      @logEngine.set(part.index, part.content)

  noop: ->
