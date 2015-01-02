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
    console.log message

  handleError: (error)->
    console.log error

Lever.register "socket:main", Lever.Websocket
Lever.inject "socket", "store", "store:main"
Lever.inject "application", "socket", "socket:main"
