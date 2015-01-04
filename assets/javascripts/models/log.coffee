Lever.Log = DS.Model.extend
  parts: DS.attr 'raw'
  complete: DS.attr 'boolean'
  created_at: DS.attr 'date'
  updated_at: DS.attr 'date'

  job: DS.belongsTo 'job'

  addPart: (part)->
    @set('parts', [])if !(@get('parts') instanceof Array)
    @get('parts').pushObject part
