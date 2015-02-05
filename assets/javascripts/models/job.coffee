Lever.Job = DS.Model.extend
  name: DS.attr 'string'
  inputFolder: DS.attr 'string'
  inputFileName: DS.attr 'string'
  outputFileName: DS.attr 'string'
  state: DS.attr 'string'
  iso: DS.attr 'boolean'
  progress: DS.attr 'number'
  created_at: DS.attr 'date'
  updated_at: DS.attr 'date'

  logs: DS.hasMany 'log',
    async: true

  currentLogUpdater: (->
    @get('logs').then (data)=>
      return unless data.get('lastObject.isLoaded')
      @set 'currentLog', data.get('lastObject')
  ).observes 'logs.@each'

  currentLog: null

  encoding: (->
    @get('state') is 'encoding'
  ).property 'state'
