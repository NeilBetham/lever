# Props to travis ci for the awesome log renderer
Log = window.Log = ->
  @autoCloseFold = true
  @listeners = []
  @renderer = new Log.Renderer
  @children = new Log.Nodes(@)
  @parts = {}
  @folds = new Log.Folds(@)
  @times = new Log.Times(@)
  @

Log.extend = (one, other) ->
  one[name] = other[name] for name of other
  one

Log.extend Log,
  DEBUG: false
  SLICE: 500
  TIMEOUT: 5
  FOLD: /fold:(start|end):([\w_\-\.]+)/
  TIME: /time:(start|end):([\w_\-\.]+):?([\w_\-\.\=\,]*)/

  create: (options) ->
    options ||= {}
    log = new Log()
    log.listeners.push(log.limit = new Log.Limit(options.limit)) if options.limit
    log.listeners.push(listener) for listener in options.listeners || []
    log

#### Start nodes.coffee
Log.Node = (id, num) ->
  @id = id
  @num = num
  @key = Log.Node.key(@id)
  @children = new Log.Nodes(@)
  @
Log.extend Log.Node,
  key: (id) ->
    id.split('-').map((i) -> '000000'.concat(i).slice(-6)).join('') if id
Log.extend Log.Node.prototype,
  addChild: (node) ->
    @children.add(node)
  remove: () ->
    @log.remove(@element)
    @parent.children.remove(@)
Object.defineProperty Log.Node::, 'log',
  get: () -> @_log ||= @parent?.log || @parent

Object.defineProperty Log.Node::, 'firstChild',
  get: () -> @children.first

Object.defineProperty Log.Node::, 'lastChild',
  get: () -> @children.last



Log.Nodes = (parent) ->
  @parent = parent if parent
  @items  = []
  @index  = {}
  @
Log.extend Log.Nodes.prototype,
  add: (item) ->
    ix = @position(item) || 0
    @items.splice(ix, 0, item)
    item.parent = @parent if @parent
    prev = (item) -> item = item.prev while item && !item.children.last; item?.children.last
    next = (item) -> item = item.next while item && !item.children.first; item?.children.first
    item.prev.next = item if item.prev = @items[ix - 1] || prev(@parent?.prev)
    item.next.prev = item if item.next = @items[ix + 1] || next(@parent?.next)
    item
  remove: (item) ->
    @items.splice(@items.indexOf(item), 1)
    item.next.prev = item.prev if item.next
    item.prev.next = item.next if item.prev
    @parent.remove() if @items.length == 0
  position: (item) ->
    for ix in [@items.length - 1..0] by -1
      return ix + 1 if @items[ix].key < item.key
  indexOf: ->
    @items.indexOf.apply(@items, arguments)
  slice: ->
    @items.slice.apply(@items, arguments)
  each: (func) ->
    @items.slice().forEach(func)
  map: (func) ->
    @items.map(func)

Object.defineProperty Log.Nodes::, 'first',
  get: () -> @items[0]

Object.defineProperty Log.Nodes::, 'last',
  get: () -> @items[@length - 1]

Object.defineProperty Log.Nodes::, 'length',
  get: () -> @items.length


Log.Part = (id, num, string) ->
  Log.Node.apply(@, arguments)
  @string = string || ''
  @string = @string.replace(/\x33\[1000D/gm, '\r')
  @string = @string.replace(/\r+\n/gm, '\n')
  @strings = @string.split(/^/gm) || []
  @slices = (@strings.splice(0, Log.SLICE) while @strings.length > 0)
  @
Log.extend Log.Part,
  create: (log, num, string) ->
    part = new Log.Part(num.toString(), num, string)
    log.addChild(part)
    part.process(0, -1)
Log.Part.prototype = Log.extend new Log.Node,
  remove: ->
    # don't remove parts
  process: (slice, num) -> # TODO Lots of CPU usage here too
    for string in (@slices[slice] || [])
      return if @log.limit?.limited
      # console.log "P processing: #{JSON.stringify(string)}"
      spans = []
      for node in Log.Deansi.apply(string)
        span = Log.Span.create(@, "#{@id}-#{num += 1}", num, node.text, node.class)
        span.render()
        spans.push(span)
      spans[0].line.clear() if spans[0]?.line?.cr
    setTimeout((=> @process(slice + 1, num)), Log.TIMEOUT) unless slice >= @slices.length - 1

newLineAtTheEndRegexp = new RegExp("\n$")
newLineRegexp = new RegExp("\n")
rRegexp = new RegExp("\r")

removeCarriageReturns = (string) ->
  index = string.lastIndexOf("\r")
  return string if index == -1
  string.substr(index + 1)

Log.Span = (id, num, text, classes) ->
  Log.Node.apply(@, arguments)
  if fold = text.match(Log.FOLD)
    @fold  = true
    @event = fold[1]
    @text  = @name = fold[2]
  else if time = text.match(Log.TIME)
    @time  = true
    @event = time[1]
    @name  = time[2]
    @stats = time[3]
  else
    @text  = text
    @text  = removeCarriageReturns(@text)
    @text  = @text.replace(newLineAtTheEndRegexp, '')
    @nl    = !!text[text.length - 1]?.match(newLineRegexp)
    @cr    = !!text.match(rRegexp)
    @class = @cr && ['clears'] || classes
  @
Log.extend Log.Span,
  create: (parent, id, num, text, classes) ->
    span = new Log.Span(id, num, text, classes)
    parent.addChild(span)
    span
  render: (parent, id, num, text, classes) ->
    span = @create(parent, id, num, text, classes)
    span.render()
Log.Span.prototype = Log.extend new Log.Node,
  render: ->
    # if !@fold && !@nl && @next?.cr && @isSequence(@next)
    #   console.log "S.0 skip #{@id}" if Log.DEBUG
    #   @line = @next.line
    #   @remove()
    if @time && @event == 'end' && @prev
      console.log "S.0 insert #{@id} after prev #{@prev.id}" if Log.DEBUG
      @nl = @prev.nl
      @log.insert(@data, after: @prev.element)
      @line = @prev.line
    else if !@fold && @prev && !@prev.fold && !@prev.nl
      console.log "S.1 insert #{@id} after prev #{@prev.id}" if Log.DEBUG
      @log.insert(@data, after: @prev.element)
      @line = @prev.line
    else if !@fold && @next && !@next.fold && !@next.time # && !@nl
      console.log "S.2 insert #{@id} before next #{@next.id}" if Log.DEBUG
      @log.insert(@data, before: @next.element)
      @line = @next.line
    else
      @line = Log.Line.create(@log, [@])
      @line.render()

    # console.log format document.firstChild.innerHTML + '\n'
    @split(tail) if @nl && (tail = @tail).length > 0
    @log.times.add(@) if @time

  remove: ->
    Log.Node::remove.apply(@)
    @line.remove(@) if @line
  split: (spans) ->
    console.log "S.4 split [#{spans.map((span) -> span.id).join(', ')}]" if Log.DEBUG
    @log.remove(span.element) for span in spans
    # console.log format document.firstChild.innerHTML + '\n'
    line = Log.Line.create(@log, spans)
    line.render()
    line.clear() if line.cr
  clear: -> # TODO Lots of CPU usage here
    if @prev && @isSibling(@prev) && @isSequence(@prev)
      @prev.clear()
      @prev.remove()
  isSequence: (other) ->
    @parent.num - other.parent.num == @log.children.indexOf(@parent) - @log.children.indexOf(other.parent)
  isSibling: (other) ->
    @element?.parentNode == other.element?.parentNode
  siblings: (type) ->
    siblings = []
    siblings.push(span) while (span = (span || @)[type]) && @isSibling(span)
    siblings

Object.defineProperty Log.Span::, 'data',
  get: () -> { id: @id, type: 'span', text: @text, class: @class, time: @time }

Object.defineProperty Log.Span::, 'line',
  get: () -> @_line
  set: (line) ->
    @line.remove(@) if @line
    @_line = line
    @line.add(@) if @line

Object.defineProperty Log.Span::, 'element',
  get: () -> document.getElementById(@id)

Object.defineProperty Log.Span::, 'head',
  get: () -> @siblings('prev').reverse()

Object.defineProperty Log.Span::, 'tail',
  get: () -> @siblings('next')



Log.Line = (log) ->
  @log = log
  @spans = []
  @
Log.extend Log.Line,
  create: (log, spans) ->
    if (span = spans[0]) && span.fold
      line = new Log.Fold(log, span.event, span.name)
    # else if (span = spans[0]) && span.time
    #   line = new Log.Time(log, span.event, span.name)
    else
      line = new Log.Line(log)
    span.line = line for span in spans
    line
Log.extend Log.Line.prototype,
  add: (span) ->
    @cr = true if span.cr
    if @spans.indexOf(span) > -1
      return
    else if (ix = @spans.indexOf(span.prev)) > -1
      @spans.splice(ix + 1, 0, span)
    else if (ix = @spans.indexOf(span.next)) > -1
      @spans.splice(ix, 0, span)
    else
      @spans.push(span)
  remove: (span) ->
    @spans.splice(ix, 1) if (ix = @spans.indexOf(span)) > -1
  render: ->
    if (fold = @prev) && fold.event == 'start' && fold.active
      if @next && !@next.fold
        console.log "L.0 insert #{@id} before next #{@next.id}" if Log.DEBUG
        @element = @log.insert(@data, before: @next.element)
      else
        console.log "L.0 insert #{@id} into fold #{fold.id}" if Log.DEBUG
        fold = @log.folds.folds[fold.name].fold
        @element = @log.insert(@data, into: fold)
    else if @prev
      console.log "L.1 insert #{@spans[0].id} after prev #{@prev.id}" if Log.DEBUG
      @element = @log.insert(@data, after: @prev.element)
    else if @next
      console.log "L.2 insert #{@spans[0].id} before next #{@next.id}" if Log.DEBUG
      @element = @log.insert(@data, before: @next.element)
    else
      console.log "L.3 insert #{@spans[0].id} into #log" if Log.DEBUG
      @element = @log.insert(@data)
    # console.log format document.firstChild.innerHTML + '\n'
  clear: ->
    # cr.clear() if cr = @crs.pop()
    cr.clear() for cr in @crs

Object.defineProperty Log.Line::, 'id',
  get: () -> @spans[0]?.id

Object.defineProperty Log.Line::, 'data',
  get: () -> { type: 'paragraph', nodes: @nodes }

Object.defineProperty Log.Line::, 'nodes',
  get: () -> @spans.map (span) -> span.data

Object.defineProperty Log.Line::, 'prev',
  get: () -> @spans[0].prev?.line

Object.defineProperty Log.Line::, 'next',
  get: () -> @spans[@spans.length - 1].next?.line

Object.defineProperty Log.Line::, 'crs',
  get: () -> @spans.filter (span) -> span.cr


Log.Fold = (log, event, name) ->
  Log.Line.apply(@, arguments)
  @fold  = true
  @event = event
  @name  = name
  @
Log.Fold.prototype = Log.extend new Log.Line,
  render: ->
    # console.log "fold #{@id} prev: #{@prev?.id} next: #{@next?.id}"
    if @prev && @prev.element
      console.log "F.1 insert #{@id} after prev #{@prev.id}" if Log.DEBUG
      element = @prev.element
      @element = @log.insert(@data, after: element)
    else if @next
      console.log "F.2 insert #{@id} before next #{@next.id}" if Log.DEBUG
      element = @next.element || @next.element.parentNode
      @element = @log.insert(@data, before: element)
    else
      console.log "F.3 insert #{@id}" if Log.DEBUG
      @element = @log.insert(@data)

    @span.prev.split([@span.next].concat(@span.next.tail)) if @span.next && @span.prev?.isSibling(@span.next)
    # console.log format document.firstChild.innerHTML + '\n'
    @active = @log.folds.add(@data)

Object.defineProperty Log.Fold::, 'id',
  get: () -> "fold-#{@event}-#{@name}"

Object.defineProperty Log.Fold::, 'span',
  get: () -> @spans[0]

Object.defineProperty Log.Fold::, 'data',
  get: () -> { type: 'fold', id: @id, event: @event, name: @name }

#### End nodes.coffee

Log.prototype = Log.extend new Log.Node,
  set: (num, string) ->
    if @parts[num]
      console.log "part #{num} exists"
    else
      @parts[num] = true
      Log.Part.create(@, num, string)
  insert: (data, pos) ->
    @trigger 'insert', data, pos
    @renderer.insert(data, pos)
  remove: (node) ->
    @trigger 'remove', node
    @renderer.remove(node)
  hide: (node) ->
    @trigger 'hide', node
    @renderer.hide(node)
  trigger: ->
    args = [@].concat(Array::slice.apply(arguments))
    listener.notify.apply(listener, args) for listener, ix in @listeners

Log.Listener = ->
Log.extend Log.Listener.prototype,
  notify: (log, event) ->
    @[event].apply(@, [log].concat(Array::slice.call(arguments, 2))) if @[event]

#### Start folds.coffee
Log.Folds = (log) ->
  @log = log
  @folds = {}
  @
Log.extend Log.Folds.prototype,
  add: (data) ->
    fold = @folds[data.name] ||= new Log.Folds.Fold
    fold.receive(data, autoCloseFold: @log.autoCloseFold)
    fold.active

Log.Folds.Fold = ->
  @
Log.extend Log.Folds.Fold.prototype,
  receive: (data, options) ->
    @[data.event] = data.id
    @activate(options) if @start && @end && !@active
  activate: (options) ->
    options ||= {}
    console.log "F.n - activate #{@start}" if Log.DEBUG
    toRemove = @fold.parentNode
    parentNode = toRemove.parentNode
    nextSibling = toRemove.nextSibling
    parentNode.removeChild(toRemove)
    fragment = document.createDocumentFragment();
    fragment.appendChild(node) for node in @nodes
    @fold.appendChild(fragment)
    parentNode.insertBefore(toRemove, nextSibling)
    @fold.setAttribute('class', @classes(options['autoCloseFold']))
    @active = true
  classes: (autoCloseFold) ->
    classes = @fold.getAttribute('class').split(' ')
    classes.push('fold')
    classes.push('open') unless autoCloseFold
    classes.push('active') if @fold.childNodes.length > 2
    classes.join(' ')

Object.defineProperty Log.Folds.Fold::, 'fold',
  get: () -> @_fold ||= document.getElementById(@start)

Object.defineProperty Log.Folds.Fold::, 'nodes',
  get: () ->
    node = @fold
    nodes = []
    nodes.push(node) while (node = node.nextSibling) && node.id != @end
    nodes

#### End folds.coffee

#### Start times.coffee
Log.Times = (log) ->
  @log = log
  @times = {}
  @
Log.extend Log.Times.prototype,
  add: (node) ->
    time = @times[node.name] ||= new Log.Times.Time
    time.receive(node)
    # time.active
  duration: (name) ->
    @times[name].duration if @times[name]

Log.Times.Time = ->
  @
Log.extend Log.Times.Time.prototype,
  receive: (node) ->
    @[node.event] = node
    console.log "T.0 - #{node.event} #{node.name}" if Log.DEBUG
    @finish() if @start && @end
  finish: ->
    console.log "T.1 - finish #{@start.name}" if Log.DEBUG
    element = document.getElementById(@start.id)
    @update(element) if element
  update: (element) ->
    element.setAttribute('class', 'duration')
    element.setAttribute('title', "This command finished after #{@duration} seconds.")
    # console.log(element.nodeName)
    element.lastChild.nodeValue = "#{@duration}s"
    # element.appendChild document.createTextNode(@duration)

Object.defineProperty Log.Times.Time::, 'duration',
  get: ->
    duration = @stats.duration / 1000 / 1000 / 1000 # nanoseconds
    duration.toFixed(2)

Object.defineProperty Log.Times.Time::, 'stats',
  get: ->
    return {} unless @end && @end.stats
    stats = {}
    for stat in @end.stats.split(',')
      stat = stat.split('=')
      stats[stat[0]] = stat[1]
    stats

#### End times.coffee

#### Start deansi.coffee
Log.Deansi =
  CLEAR_ANSI: ///
(?:\x33) # leader
(?:
    \[0?c                 # query device code
  | \[[0356]n             # device-related
  | \[7[lh]               # disable/enable line wrapping
  | \[\?25[lh]            # not sure what this is, but we've seen it happen
  | \(B                   # set default font to 'B'
  | H                     # set tab at current position
  | \[(?:\d+(;\d+){,2})?G # tab control
  | \[(?:[12])?[JK]       # erase line, screen, etc.
  | [DM]                  # scroll up/down
  | \[0K                  # clear line, handled by \r in our case
)
///gm # See http://ispltd.org/mini_howto:ansi_terminal_codes


  apply: (string) ->
    return [] unless string
    string = string.replace(@CLEAR_ANSI, '')
    nodes = ansiparse(string).map (part) => @node(part)
    nodes

  node: (part) ->
    node = { type: 'span', text: part.text }
    node.class = classes.join(' ') if classes = @classes(part)
    # node.hidden = true   if @hidden(part)
    node

  classes: (part) ->
    result = []
    result = result.concat(@colors(part))
    result if result.length > 0

  colors: (part) ->
    colors = []
    colors.push(part.foreground)         if part.foreground
    colors.push("bg-#{part.background}") if part.background
    colors.push('bold')                  if part.bold
    colors.push('italic')                if part.italic
    colors.push('underline')             if part.underline
    colors

  hidden: (part) ->
    if part.text.match(/\r/)
      part.text = part.text.replace(/^.*\r/gm, '')
      true
#### End deansi.coffee

#### Start limit.coffee
Log.Limit = (max_lines) ->
  @max_lines = max_lines || 1000
  @
Log.Limit.prototype = Log.extend new Log.Listener,
  count: 0
  insert: (log, node, pos) ->
    @count += 1 if node.type == 'paragraph' && !node.hidden
Object.defineProperty Log.Limit::, 'limited',
  get: () -> @count >= @max_lines

#### End limit.coffee

#### Start renderer.coffee
Log.Renderer = ->
  @frag = document.createDocumentFragment()
  @para = @createParagraph()
  @span = @createSpan()
  @text = document.createTextNode('')
  @fold = @createFold()
  @

Log.extend Log.Renderer.prototype,
  insert: (data, pos) ->
    node = @render(data)
    if into = pos?.into
      into = document.getElementById(pos?.into) if typeof into == 'String'
      if pos?.prepend
        @prependTo(node, into)
      else
        @appendTo(node, into)
    else if after = pos?.after
      after = document.getElementById(pos) if typeof after == 'String'
      @insertAfter(node, after)
    else if before = pos?.before
      before = document.getElementById(pos?.before) if typeof before == 'String'
      @insertBefore(node, before)
    else
      @insertBefore(node)
    node

  hide: (node) ->
    node.setAttribute('class', @addClass(node.getAttribute('class'), 'hidden'))
    node

  remove: (node) ->
    node.parentNode.removeChild(node) if node
    node

  render: (data) ->
    if data instanceof Array
      frag = @frag.cloneNode(true)
      for node in data
        node = @render(node)
        frag.appendChild(node) if node
      frag
    # else if data.type == 'paragraph' && data.nodes[0]?.time
    else
      data.type ||= 'paragraph'
      type = data.type[0].toUpperCase() + data.type.slice(1)
      @["render#{type}"](data)

  renderParagraph: (data) ->
    para = @para.cloneNode(true)
    para.setAttribute('id', data.id) if data.id
    para.setAttribute('style', 'display: none;') if data.hidden
    for node in (data.nodes || [])
      type = node.type[0].toUpperCase() + node.type.slice(1)
      node = @["render#{type}"](node)
      para.appendChild(node)
    para

  renderFold: (data) ->
    # return if document.getElementById(data.id)
    fold = @fold.cloneNode(true)
    fold.setAttribute('id', data.id || "fold-#{data.event}-#{data.name}")
    fold.setAttribute('class', "fold-#{data.event}")
    if data.event == 'start'
      fold.lastChild.lastChild.nodeValue = data.name
    else
      fold.removeChild(fold.lastChild)
    fold

  renderSpan: (data) ->
    span = @span.cloneNode(true)
    span.setAttribute('id', data.id) if data.id
    span.setAttribute('class', data.class) if data.class
    span.lastChild.nodeValue = data.text || ''
    span

  renderText: (data) ->
    text = @text.cloneNode(true)
    text.nodeValue = data.text
    text

  createParagraph: ->
    para = document.createElement('p')
    para.appendChild(document.createElement('a'))
    para

  createFold: ->
    fold = document.createElement('div')
    fold.appendChild(@createSpan())
    fold.lastChild.setAttribute('class', 'fold-name')
    fold

  createSpan: ->
    span = document.createElement('span')
    span.appendChild(document.createTextNode(' '))
    span

  insertBefore: (node, other) ->
    if other
      other.parentNode.insertBefore(node, other)
    else
      log = document.getElementById('log')
      log.insertBefore(node, log.firstChild)

  insertAfter: (node, other) ->
    if other.nextSibling
      @insertBefore(node, other.nextSibling)
    else
      @appendTo(node, other.parentNode)

  prependTo: (node, other) ->
    if other.firstChild
      other.insertBefore(node, other.firstChild)
    else
      appendTo(node, other)

  appendTo: (node, other) ->
    other.appendChild(node)

  addClass: (classes, string) ->
    return if classes?.indexOf(string)
    if classes then "#{classes} #{string}" else string
#### End renderer.coffee
