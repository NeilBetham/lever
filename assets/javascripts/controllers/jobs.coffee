Lever.JobsIndexController = Ember.ArrayController.extend

  actions:
    restart: ->
      console.log 'Triggering restart'

    shutdown: ->
      console.log 'Shuttding down'
