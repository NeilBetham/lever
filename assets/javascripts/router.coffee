Lever.Router.map ->
  @route 'restart'
  @route 'shutdown'

  @resource 'jobs', ->
    @resource ':job_id', ->
      @route 'restart'
      @route 'stop'
      @route 'log'

  @route 'catchall', { path: '*fourohfour' }
