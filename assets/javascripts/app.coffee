#
#= require ../../vendor/assets/bower_components/jquery/dist/jquery.js
#= require ../../vendor/assets/bower_components/handlebars/handlebars.js
#= require ../../vendor/assets/bower_components/ember/ember.js
#= require ../../vendor/assets/bower_components/ember-data/ember-data.min.js
#= require ../../vendor/assets/bower_components/humps/humps.js
#= require_tree ../../vendor/assets/javascripts
#= require_tree ./templates
#= require_self
#= require_tree .
#

$(document).ready ->
  console.log 'loaded'

Lever = window.Lever = Ember.Application.create
  LOG_TRANSITIONS_INTERNAL: true
  LOG_TRANSITIONS: true

Ember.Application.initializer
  name: "webSocketInit"

  initialize: (container, application)->
    # Lookup the websocket handler to get the connection started
    container.lookup 'socket:main'

Lever.timedChunk = (items, process, context, callback) ->
  todo = items.concat() #create a clone of the original
  setTimeout (->
    start = +new Date()
    loop
      console.log 'batch'
      process.call context, todo.shift()
      break unless todo.length > 0 and (+new Date() - start < 50)
    if todo.length > 0
      setTimeout arguments.callee, 25
    else
      callback items
    return
  ), 25
  return
