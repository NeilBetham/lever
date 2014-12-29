Lever.RawTransform = DS.Transform.extend
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized

Lever.ApplicationAdapter = DS.ActiveModelAdapter.extend
  namespace: "api"
