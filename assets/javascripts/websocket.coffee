Lever.Websocket = Ember.Object.extend
  socket: null
  state: null

  connected: (->
    return true if @get('state') is 1
    false
  ).property 'state'

  init: ->
    @connectSocket()

  connectSocket: ->
    console.log 'connecting to websocket'
    try
      connection = new WebSocket("ws://#{window.location.host}/ws")
    catch
      console.error 'can\'t connect to web socket server'

    @set 'socket', connection

    @get('socket').onopen = (event)=>
      @set 'state', @get('socket.readyState')

    @get('socket').onmessage = (event)=>
      @set 'state', @get('socket.readyState')
      @handleMessage(event)

    @get('socket').onerror = (error)=>
      @set 'state', @get('socket.readyState')
      @handleError(error)

    @get('socket').onclose = (event)=>
      console.log 'socket closed, reconnecting'
      @set 'state', @get('socket.readyState')
      setTimeout =>
        @connectSocket()
      , 1000


  handleMessage: (message)->
    if message.data == 'ping'
      console.log('received server ping')
      return

    try
      data = humps.camelizeKeys JSON.parse message.data
    catch
      console.error 'Failed to parse message'

    # component:action
    switch /\w+(?=:)/g.exec(data["type"])[0]
      when "log"
        @handleLogMessage(data)
      when "model"
        @handleModelMessage(data)

  handleError: (error)->
    console.log error

  handleLogMessage: (data)->
    switch /(?:\:)\w+/g.exec(data["type"])[0].slice(1)
      when "addpart"
        # {"type":"log:addpart", "part":{"logId":1234, "number":1234, "line":"skladfjlhfsd"}}
        @get('store').find('log', data.part.logId).then (log)->
          if log
            log.addPart
              index: data.part.index
              content: data.part.content

  handleModelMessage: (data)->
    store = @get 'store'
    switch /(?:\:)\w+/g.exec(data["type"])[0].slice(1)
      when "update"
        # {"type":"model:update", "data":{"modelName":"job", "modelId":1234, "data":{"param":"value"}}}
        store.push data.data.modelName, store.normalize data.data.modelName, data.data.data
      when "create"
        store.push data.data.modelName, store.normalize data.data.modelName, data.data.data
      when "destroy"
        store.find(data.data.modelName, data.data.modelId).then (model)->
          if model
            model.deleteRecord();
      when "reload"
        store.find(data.data.modelName, data.data.modelId).then (model)->
          if model
            model.reload();

  sub: (key)->
    console.log key

  unsub: (key)->
    console.log key


Lever.register "socket:main", Lever.Websocket
Lever.inject "socket", "store", "store:main"
Lever.inject "application", "socket", "socket:main"
Lever.inject "controller", "socket", "socket:main"
