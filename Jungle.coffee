makeGrid = (rows, columns, fill) ->
  grid = []
  for r in [1 .. rows]
    row = []
    for c in [1 .. columns]
      row.push fill()
    grid.push row
  grid

dirs = ['up', 'down', 'left', 'right']

clockwise_table =
  up:    'right'
  right: 'down'
  down:  'left'
  left:  'up'
clockwise = (dir) -> clockwise_table[dir]

images = {}

# Loads a set of images, and waits until they are all loaded.
loadImages = (urls) ->
  new_urls = (url for url in urls when not images[url])
  todo = new_urls.length
  for url in new_urls
    img = new Image()
    img.src = url
    images[url] = img
    img.onload = () ->
      todo--
  #null until todo is 0
  null

class Body
  constructor: (@jungle, @sprite, @x, @y, misc = {}) ->
    @width  = misc.width  ? 2 # in squares
    @height = misc.height ? 2 # in squares
    @facing = misc.facing ? 'down'
    @state  = misc.state  ? 'stopped'
    @was_moving = misc.was_moving ? false
    @speed = misc.speed ? 2
  
  # An array of [r, c] that this body is currently occupying.
  occupying: () ->
    sq_height = @jungle.square_height
    sq_width  = @jungle.square_width
    top_y    = @y
    bottom_y = top_y + @height * sq_height
    left_x   = @x
    right_x  = left_x + @width * sq_width
    top_row      = Math.floor(top_y / sq_height)
    bottom_row   = Math.ceil(bottom_y / sq_height) - 1
    left_column  = Math.floor(left_x / sq_width)
    right_column = Math.ceil(right_x / sq_width) - 1
    squares = []
    for r in [top_row .. bottom_row]
      for c in [left_column .. right_column]
        squares.push [r, c]
    squares
  
  # An array of all the possible URLs imageURL() could return for this body.
  imageURLs: () ->
    urls = []
    for dir in dirs
      urls.push "img/#{@sprite}/stopped/#{dir}.png"
      for i in [0..3]
        urls.push "img/#{@sprite}/moving/#{dir}/#{i}.png"
    urls
  
  loadImages: () ->
    loadImages @imageURLs()
  
  # The current image for this body.
  imageURL: () ->
    switch (if @was_moving then 'moving' else @state)
      when 'stopped'
        "img/#{@sprite}/stopped/#{@facing}.png"
      when 'moving'
        "img/#{@sprite}/moving/#{@facing}/#{@jungle.anim_frame}.png"
  
  draw: () ->
    j = @jungle
    j.ctx.drawImage(images[@imageURL()], @x + j.x_offset, @y + j.y_offset)
  
  # Adds this body to each cell it is currently occupying.
  mark: () ->
    bodies = @jungle.bodies
    for [r, c] in @occupying()
      cell = bodies[r][c]
      cell.push this unless this in cell
  
  # Removes this body from every cell it is currently occupying.
  unmark: () ->
    bodies = @jungle.bodies
    for [r, c] in @occupying()
      bodies[r][c] = (body for body in bodies[r][c] when body isnt this)
  
  advance: () ->
    @unmark()
    switch @state
      when 'moving'
        @was_moving = true
        @bump()
        if @aligned()
          @state = 'stopped'
          # TODO: @check_pickup() if @sprite is 'player'
      when 'stopped'
        @was_moving = false
        @move()
    @mark()
    null
  
  move: () ->
    null # default movement does nothing
  
  bump: () ->
    switch @facing
      when 'left'  then @x -= @speed
      when 'right' then @x += @speed
      when 'up'    then @y -= @speed
      when 'down'  then @y += @speed
    null
  
  aligned: () ->
    @x % @jungle.square_width is 0 and @y % @jungle.square_height is 0
  
  can_move: (dir) ->
    copy =
      x: @x
      y: @y
      speed: @speed
      facing: dir
      jungle: @jungle
      height: @height
      width: @width
      bump: @bump
      occupying: @occupying
    copy.bump()
    for [r, c] in copy.occupying()
      unless @jungle.bodies[r][c].length is 0
        return false
      if @sprite isnt 'player'
        return false unless @jungle.pickups[r][c].length is 0
    true
  
  start_moving: (dir) ->
    @facing = dir
    @state = 'moving'
    @bump()
    null

class Player extends Body
  constructor: (jungle, x, y, misc = {}) ->
    super jungle, 'player', x, y, misc
  
  move: () ->
    cw0 = @facing
    cw1 = clockwise cw0
    cw2 = clockwise cw1
    cw3 = clockwise cw2
    no_keys = true
    for dir in [cw0, cw1, cw2, cw3]
      if @jungle.keys[dir]
        no_keys = false
        @facing = dir
        if @can_move dir
          @start_moving dir
          return
    @facing = cw0 if no_keys || @jungle.keys[cw0]
    null

class Gazelle extends Body
  constructor: (jungle, x, y, misc = {}) ->
    super jungle, 'gazelle', x, y, misc
  
  move: () ->
    null # TODO

class Jungle
  constructor: (@canvas, misc = {}) ->
    @x_offset        = misc.x_offset       ? 0
    @y_offset        = misc.y_offset       ? 0
    @num_rows    = r = misc.num_rows       ? 24
    @num_columns = c = misc.num_columns    ? 30
    @square_width    = misc.square_width   ? 16
    @square_height   = misc.square_height  ? 16
    
    @ctx = canvas.getContext '2d'
    
    @frame         = 0
    @anim_frame    = 0 # 0 -> 1 -> 2 -> 3 -> 0, every 5th frame
    @anim_subframe = 0 # 0 -> 1 -> 2 -> 3 -> 4 -> 0, every frame
    
    @scenery = makeGrid r, c, () -> 'bare'
    @pickups = makeGrid r, c, () -> null
    @bodies  = makeGrid r, c, () -> []
    
    @pickup_list = []
    @body_list   = []
    
    @keys = {}
    
    null
  
  # Advances the game state by one frame. Does not draw anything.
  advance: ->
    @frame++
    @anim_subframe++
    if @anim_subframe is 5
      @anim_subframe = 0
      @anim_frame = (@anim_frame + 1) % 4
    body.advance() for body in @body_list
    null
  
  draw: ->
    @draw_scenery()
    @draw_pickups()
    @draw_bodies()
    null
  
  draw_scenery: ->
    for r in [0 .. @num_rows - 1]
      for c in [0 .. @num_columns - 1]
        x = c * @square_width + @x_offset
        y = r * @square_height + @y_offset
        @ctx.fillStyle = switch @scenery[r][c]
          when 'bare'  then '#ffffcc'
          when 'grass' then '#00ff00'
          when 'water' then '#0033ff'
          when 'tree'  then '#006600'
        @ctx.fillRect( x
                     , y
                     , @square_width
                     , @square_height
                     )
        @ctx.fillStyle = 'black'
        @ctx.fillText( @bodies[r][c].length, x, y + 10 )
    null
  
  draw_pickups: ->
    pickup.draw() for pickup in @pickup_list
    null
  
  draw_bodies: ->
    body.draw() for body in @body_list
    null
  
  set_scenery: (r, c, val) ->
    @scenery[r][c] = val
    null
  
  new_body: (r, c, cons) ->
    body = new cons(this, c * @square_width, r * @square_height)
    @body_list.push body
    body.mark()
    null
  
  loadImages: () ->
    body.loadImages() for body in @body_list
    pickup.loadImages() for pickup in @pickup_list
    null
  
  press_key: (key) ->
    @keys[key] = true
  
  release_key: (key) ->
    delete @keys[key]

this.Jungle = Jungle
this.Player = Player
this.Gazelle = Gazelle
