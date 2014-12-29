Lever.Log = DS.Model.extend
  parts: DS.attr 'raw'
  complete: DS.attr 'boolean'
  created_at: DS.attr 'date'
  updated_at: DS.attr 'date'

  job: DS.belongsTo 'job'
