Lever.Router.map ->
  @resource 'jobs', ->
    @resource 'job', {path: ':job_id'}, ->
      @route 'log'

  @route 'catchall', { path: '*fourohfour' }
