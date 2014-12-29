Lever.Router.map ->
  @route 'restart'
  @route 'shutdown'

  @route 'catchall', { path: '*fourohfour' }
