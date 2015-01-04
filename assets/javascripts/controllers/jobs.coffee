Lever.JobsIndexController = Ember.ArrayController.extend
  actions:
    restartJob: (job)->
      Ember.$.ajax(
        url: "/api/jobs/#{job.get 'id'}/restart"
        type: 'PUT'
      ).then (response)->
        console.log 'job restart triggered'

    stopJob: (job)->
      Ember.$.ajax(
        url: "/api/jobs/#{job.get 'id'}/stop"
        type: 'PUT'
      ).then (response)->
        console.log 'job restart triggered'
