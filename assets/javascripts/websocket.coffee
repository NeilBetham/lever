Lever.Websocket = Ember.Object.extend
  socket: null

  init: ->
    console.log 'connecting to websocket'
    try
      connection = new WebSocket("ws://#{window.location.host}/ws")
    catch
      console.error 'can\'t connect to web socket server'

    @set 'socket', connection

    @get('socket').onmessage = (event)=>
      @handleMessage(event)
    @get('socket').onerror = (error)=>
      @handleError(error)

  handleMessage: (message)->
    if message.data == 'ping'
      console.log('received server ping')
      return

    try
      data = JSON.parse message.data
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
              index: data.part.number
              line: data.part.line


  handleModelMessage: (data)->
    switch /(?:\:)\w+/g.exec(data["type"])[0].slice(1)
      when "update"
        # {"type":"model:update", "data":{"modelName":"job", "modelId":1234, "data":{"param":"value"}}}
        @get('store').find(data.data.modelName, data.data.modelId).then (model)->
          if model
            delete(data.data.data.id)
            model.setProperties(data.data.data)


Lever.register "socket:main", Lever.Websocket
Lever.inject "socket", "store", "store:main"
Lever.inject "application", "socket", "socket:main"
Lever.inject "controller", "socket", "socket:main"
