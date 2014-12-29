Lever.Router.map ->
  @route 'restart'
  @route 'shutdown'

  @resource 'jobs', ->
    @route 'log'
    @route 'restart'
    @route 'stop'

  @route 'catchall', { path: '*fourohfour' }
