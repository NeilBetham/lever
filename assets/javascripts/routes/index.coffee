Lever.IndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo 'jobs'
