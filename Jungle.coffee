makeGrid = (rows, columns, fill) ->
  grid = []
  for r in [1 .. rows]
    row = []
    for c in [1 .. columns]
      row.push fill
    grid.push row
  grid

class Body
  constructor: (@sprite, @x, @y, misc = {}) ->
    @width  = misc.width  ? 2 # in squares
    @height = misc.height ? 2 # in squares
  
  occupying: (jungle) ->
    top_y    = @y
    bottom_y = top_y + @height * jungle.square_height
    left_x   = @x
    right_x  = left_x + @width * jungle.square_width
    top_row      = Math.floor(top_y / jungle.square_height)
    bottom_row   = Math.ceil(bottom_y / jungle.square_height) - 1
    left_column  = Math.floor(left_x / jungle.square_width)
    right_column = Math.ceil(right_x / jungle.square_width) - 1
    squares = []
    for r in [top_row .. bottom_row]
      for c in [left_column .. right_column]
        squares.push [r, c]
    squares

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
    @pickups = makeGrid(r, c, [])
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
    # TODO
  
  draw_bodies: ->
    # TODO
  
  set_scenery: (r, c, val) ->
    @scenery[r][c] = val
    null

# export the Jungle class
this.Jungle = Jungle
