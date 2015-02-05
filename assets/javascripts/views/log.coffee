Lever.LogView = Ember.View.extend
  template: Ember.Handlebars.compile """
    <div id="log-container">
      {{#if view.loading}}
      <div class="spinner">
        <div class="rect1"></div>
        <div class="rect2"></div>
        <div class="rect3"></div>
        <div class="rect4"></div>
        <div class="rect5"></div>
      </div>
      {{/if}}
      <pre id="log" {{bind-attr class="view.loading:hidden"}}></pre>
    </div>"""
  log: null
  logEngine: null
  loading: false
  initialLoadComplete: false
  initialLoadInProgress: false

  setLogLoadingFalseForLongLoads: (->
    if @get('loading')
      setTimeout =>
        unless @get('initialLoadComplete')
          @set('loading', false)
          @get('notifications').newFlash
            message:'Hey, this log is taking a while to load, give it a hot minute to finish backfilling'
            duration: 20
      , 10000
  ).observes 'loading'

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
      parts = log.get('parts')
      @set 'loading', true
      parts.addArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
      parts = parts.slice(0)
      @partsDidChange(parts, 0, null, parts.length)

  partsDidChange: (parts, start, _, added)->
    return if @get('initialLoadInProgress')
    if @get('initialLoadComplete') is false
      @set 'initialLoadInProgress', true
      Lever.timedChunk parts.slice(start, start + added), (part)->
        @logEngine.set(part.index, part.content)
      , @, =>
        @set 'loading', false
        @set 'initialLoadComplete', true
        @set 'initialLoadInProgress', false
    else
      for part, i in parts.slice(start, start + added)
        @logEngine.set(part.index, part.content)

  noop: ->
