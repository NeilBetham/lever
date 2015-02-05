Lever.Notifications = Ember.Object.extend
  flashMessages: []

  newFlash: (flash)->
    flashObj = Ember.Object.create()
    flashObj.setProperties flash
    flashObj.set 'removeMe', false
    @get('flashMessages').pushObject flashObj

  currentFlashMessage: (->
    @get 'flashMessages.firstObject'
  ).property 'flashMessages.@each'


  removeFlashes: (->
    @get('flashMessages').map (obj)=>
      if obj.get('removeMe')
        @get('flashMessages').removeObject obj
  ).observes 'flashMessages.@each.removeMe'




Lever.register "notifications:main", Lever.Notifications
Lever.inject "application", "notifications", "notifications:main"
Lever.inject "socket", "notifications", "notifications:main"
Lever.inject "controller", "notifications", "notifications:main"
Lever.inject "view", "notifications", "notifications:main"
