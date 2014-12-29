#
#= require ../../vendor/assets/bower_components/jquery/dist/jquery.js
#= require ../../vendor/assets/bower_components/handlebars/handlebars.js
#= require ../../vendor/assets/bower_components/ember/ember.js
#= require ../../vendor/assets/bower_components/ember-data/ember-data.min.js
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
