Lever.LogView = Ember.View.extend
  templateName: 'job/log'
  logEngine: null

  didInsertElement: ->
    @_super


  setupLogEngine: ->
    console.log 'setting up log engine'
