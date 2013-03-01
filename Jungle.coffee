makeGrid = (rows, columns, fill) ->
  grid = []
  for r in [1 .. rows]
    row = []
    for c in [1 .. columns]
      row.push fill
    grid.push row
  grid

dirs = ['up', 'down', 'left', 'right']

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
    sprite = @sprite
    switch sprite
      when 'dartdemon'
        "img/dartdemon/#{dir}.png" for dir in dirs
      else
        urls = []
        for dir in dirs
          urls.push "img/#{sprite}/stopped/#{dir}.png"
          for i in [0..3]
            urls.push "img/#{sprite}/moving/#{dir}/#{i}.png"
        urls
  
  loadImages: () ->
    loadImages @imageURLs()
  
  # The current image for this body.
  imageURL: () ->
    sprite = @sprite
    switch sprite
      when 'dartdemon'
        "img/dartdemon/#{@facing}.png"
      else switch (if @was_moving then 'moving' else @state)
        when 'stopped'
          "img/#{sprite}/stopped/#{@facing}.png"
        when 'moving'
          "img/#{sprite}/moving/#{@facing}/#{@jungle.anim_frame}.png"
  
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
      bodies[r][c] = body for body in bodies[r][c] where body isnt this

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
    
    @scenery = makeGrid(r, c, 'bare')
    @pickups = makeGrid(r, c, null)
    @bodies  = makeGrid(r, c, [])
    
    @pickup_list = []
    @body_list   = []
    
    null
  
  # Advances the game state by one frame. Does not draw anything.
  advance: ->
    @frame++
    @anim_subframe++
    if @anim_subframe is 5
      @anim_subframe = 0
      @anim_frame = (@anim_frame + 1) % 4
    # TODO
    null
  
  draw: ->
    @draw_scenery()
    @draw_pickups()
    @draw_bodies()
    null
  
  draw_scenery: ->
    for r in [0 .. @num_rows - 1]
      for c in [0 .. @num_columns - 1]
        @ctx.fillStyle = switch @scenery[r][c]
          when 'bare'  then '#ffffcc'
          when 'grass' then '#00ff00'
          when 'water' then '#0033ff'
          when 'tree'  then '#006600'
        @ctx.fillRect( c * @square_width + @x_offset
                     , r * @square_height + @y_offset
                     , @square_width
                     , @square_height
                     )
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
  
  new_body: (r, c, sprite) ->
    body = new Body(this, sprite, c * @square_width, r * @square_height)
    @body_list.push body
    body.mark
    null
  
  loadImages: () ->
    body.loadImages() for body in @body_list
    pickup.loadImages() for pickup in @pickup_list
    null

# export the Jungle class
this.Jungle = Jungle
