Lever.FlashMessageComponent = Ember.Component.extend
  visible: false

  flashObserver: (->
    flash = @get 'flash'
    return @set 'visible', false if flash is undefined
    @set 'visible', true
    Ember.run.later @, =>
      @set 'flash.removeMe', true
    , flash.duration * 1000
  ).observes 'flash'





  actions:
    dismiss: ->
      @set 'flash.removeMe', true
