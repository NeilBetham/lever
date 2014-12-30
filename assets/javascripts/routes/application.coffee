Lever.ApplicationRoute = Ember.Route.extend
  actions:
    restartServer: ->
      Ember.$.ajax(
        url: '/restart'
        type: 'GET'
      ).then (data)->
        setTimeout ->
          location.reload true
        , 1500

      console.log 'restarting'

    shutdownServer: ->
      Ember.$.ajax(
        url: '/shutdown'
        type: 'GET'
      ).then (data)->
        setTimeout ->
          location.reload true
        , 1500
      
      console.log 'shutting down'
