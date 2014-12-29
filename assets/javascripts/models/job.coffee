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
