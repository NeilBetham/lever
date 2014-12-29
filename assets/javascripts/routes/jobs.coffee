Lever.JobsIndexRoute = Ember.Route.extend
  model: ->
    @get('store').find 'job'
