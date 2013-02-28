canvas = null
ctx    = null

frame         = 0
anim_frame    = 0 # 0 -> 1 -> 2 -> 3 -> 0, every 5th frame
anim_subframe = 0 # 0 -> 1 -> 2 -> 3 -> 4 -> 0, every frame
canvas_width  = 640
canvas_height = 480

num_rows      = 24
num_columns   = 30
square_width  = 16
square_height = 16

makeGrid = () ->
  rows = []
  for i in [1 .. num_rows]
    row = []
    for j in [1 .. num_columns]
      row.push null
    rows.push row
  rows

scenery = makeGrid()
bodies  = makeGrid()
pickups = makeGrid()

body_list   = []
pickup_list = []

word    = 'FIRST'
letters = ''
apples  = 0
bridges = 0

addPickup = (sprite, r, c, misc = {}) ->
  obj =
    sprite: sprite
    x: c * square_width
    y: r * square_height
    r: r
    c: c
    width: 2
    height: 2
    toString: ->
      "[pickup #{@sprite} x:#{@x} y:#{@y} r:#{@r} c:#{@c}]"
  for k, v of misc
    obj[k] = v
  for [r, c] in occupying obj
    pickups[r][c] = obj
  pickup_list.push obj
  null

addTile = (letter, r, c) ->
  addPickup 'tile', r, c, letter: letter
  null

addBody = (sprite, r, c, misc = {}) ->
  obj =
    sprite: sprite
    x: c * square_width
    y: r * square_height
    r: r
    c: c
    width: 2 # in squares
    height: 2 # in squares
    facing: 'down'
    state: 'stopped'
    speed: 2
    was_moving: false # true if was moving last frame
    toString: ->
      "[body #{@sprite} x:#{@x} y:#{@y} r:#{@r} c:#{@c}]"
  for k, v of misc
    obj[k] = v
  for [r, c] in occupying obj
    bodies[r][c] = obj
  body_list.push obj
  null

makeImage = (src) ->
  img = new Image()
  img.src = src
  img

images = {}

imageURL = (entity) ->
  switch entity.sprite
    when 'tile' then "img/floor/tile/#{entity.letter}.png"
    when 'apple' then 'img/floor/apple.png'
    when 'bridge' then 'img/floor/bridge.png'
    when 'dartdemon' then "img/dartdemon/#{entity.facing}.png"
    else # moving body entities
      switch (if entity.was_moving then 'moving' else entity.state)
        when 'stopped'
          "img/#{entity.sprite}/stopped/#{entity.facing}.png"
        when 'moving'
          "img/#{entity.sprite}/moving/#{entity.facing}/#{anim_frame}.png"

getImage = (entity) ->
  url = imageURL(entity)
  if img = images[url] then img
  else
    img = makeImage url
    images[url] = img
    img

keys_down = {}

# 'playing', 'dead', 'complete'
status = 'playing'

draw_scenery = ->
  ctx.fillStyle = 'black'
  ctx.fillRect 0, 0, canvas_width, canvas_height
  for r in [0 .. num_rows - 1]
    for c in [0 .. num_columns - 1]
      ctx.fillStyle = switch scenery[r][c]
        when 'bare'  then '#ffffcc'
        when 'grass' then '#00ff00'
        when 'water' then '#0033ff'
        when 'tree'  then '#006600'
      ctx.fillRect( c * square_width + 10
                  , r * square_height + 10
                  , square_width
                  , square_height
                  )
  null

draw_debug = ->
  ctx.fillStyle = 'white'
  ctx.fillText "#{Math.floor(frame / 60)} | #{(frame % 60)}", 10, 410
  ctx.fillText "Letters: #{letters}", 10, 425
  ctx.fillText "#{apples} apples, #{bridges} bridges", 10, 440
  ctx.fillText "Target word: #{word}", 10, 455
  status_text =
    if status is 'dead' then 'Dead...'
    else if letters is word then 'Victory!'
    else if word.indexOf(letters) is 0 then 'Playing'
    else 'Failure...'
  ctx.fillText status_text, 10, 470
  null

draw_entities = ->
  for entity in pickup_list
    ctx.drawImage getImage(entity), entity.x + 10, entity.y + 10
  for entity in body_list
    ctx.drawImage getImage(entity), entity.x + 10, entity.y + 10
  null

walkable_bg = (r, c) ->
  scene = scenery[r][c]
  scene is 'bare' or scene is 'grass'

is_occupied = (r, c, entity_to_move) ->
  return true unless bodies[r][c] in [null, entity_to_move]
  return true if (entity_to_move.sprite isnt 'player') && pickups[r][c]
  not walkable_bg r, c

bump = (entity) ->
  switch entity.facing
    when 'left'  then entity.x -= entity.speed
    when 'right' then entity.x += entity.speed
    when 'up'    then entity.y -= entity.speed
    when 'down'  then entity.y += entity.speed
  null

start_moving = (entity, dir) ->
  entity.facing = dir
  entity.state = 'moving'
  bump entity
  for [r, c] in occupying entity
    bodies[r][c] = entity
  null

check_pickup = (r, c) ->
  if pickup = pickups[r][c]
    return unless pickup.r is r and pickup.c is c
    for [r, c] in occupying pickup
      pickups[r][c] = null
    pickup_list = (p for p in pickup_list when p isnt pickup)
    switch pickup.sprite
      when 'tile'
        letters += pickup.letter
        status = 'complete' if letters is word
      when 'apple'  then apples++
      when 'bridge' then bridges++
  null

clockwise_table =
  up:    'right'
  right: 'down'
  down:  'left'
  left:  'up'
clockwise = (dir) -> clockwise_table[dir]

occupying = (entity) ->
  top = entity.y
  bottom = top + entity.height * square_height
  left = entity.x
  right = left + entity.width * square_width
  top_row = Math.floor(top / square_height)
  bottom_row = Math.ceil(bottom / square_height) - 1
  left_column = Math.floor(left / square_width)
  right_column = Math.ceil(right / square_width) - 1
  squares = []
  for r in [top_row .. bottom_row]
    for c in [left_column .. right_column]
      squares.push [r, c]
  squares

copy = (entity) ->
  speed: entity.speed
  x: entity.x
  y: entity.y
  height: entity.height
  width: entity.width

can_move = (entity, dir) ->
  entity_copy = copy entity
  entity_copy.facing = dir
  bump entity_copy
  for [r, c] in occupying entity_copy
    return false if is_occupied r, c, entity
  true

move_player = (entity) ->
  # smooth movement: if you're going one dir towards a wall, you can
  # make an instant turn by holding the turn direction before you hit
  # the wall.
  cw0 = entity.facing
  cw1 = clockwise cw0
  cw2 = clockwise cw1
  cw3 = clockwise cw2
  no_keys = true
  for dir in [cw0, cw1, cw2, cw3]
    if keys_down[dir]
      no_keys = false
      entity.facing = dir
      if can_move entity, dir
        start_moving entity, dir
        return
  entity.facing = cw0 if no_keys || keys_down[cw0]
  null

move_gazelle = (entity) ->
  cw0 = entity.facing
  cw1 = clockwise cw0
  cw2 = clockwise cw1
  cw3 = clockwise cw2
  walls = {}
  walled_now = false
  for dir in ['up', 'down', 'left', 'right']
    if not can_move entity, dir
      walls[dir] = walled_now = true
  if entity.walled
    # gazelle was touching an obstacle when last moved
    for dir in [cw1, cw0, cw3, cw2]
      unless walls[dir]
        start_moving entity, dir
        break
  else
    for dir in [cw0, cw3, cw2, cw1]
      unless walls[dir]
        start_moving entity, dir
        break
  entity.walled = walled_now
  null

move_rhino = (entity) ->
  dir = entity.facing
  opp = clockwise clockwise dir
  if can_move entity, dir
    start_moving entity, dir
  else if can_move entity, opp
    start_moving entity, opp
  null

try_align = (entity) ->
  if entity.x % square_width is 0 and entity.y % square_height is 0
    entity.c = Math.floor(entity.x / square_width)
    entity.r = Math.floor(entity.y / square_height)
    return true
  false

# Handles updating the moving/stopped state, and applying movement to
# position.
check_movement = (entity) ->
  switch entity.state
    when 'moving'
      entity.was_moving = true
      was_occupying = occupying entity
      bump entity
      if try_align entity
        entity.state = 'stopped'
        bodies[r][c] = null for [r, c] in was_occupying
        bodies[r][c] = entity for [r, c] in occupying entity
        check_pickup entity.r, entity.c if entity.sprite is 'player'
    when 'stopped'
      entity.was_moving = false
      switch entity.sprite
        when 'player'  then move_player  entity
        when 'gazelle' then move_gazelle entity
        when 'rhino'   then move_rhino   entity
  null

update_entities = ->
  for entity in body_list
    check_movement entity
  null

elem = (x, ys) ->
  for y in ys
    return true if x is y
  false

keys =
  37: 'left'
  38: 'up'
  39: 'right'
  40: 'down'
  87: 'up'    # W
  65: 'left'  # A
  83: 'down'  # S
  68: 'right' # D

$(document).ready () ->

  canvas = $('#canvas')[0]
  ctx = canvas.getContext '2d'

  $(document).keydown (evt) ->
    if key = keys[evt.which]
      keys_down[key] = true
    null

  $(document).keyup (evt) ->
    if key = keys[evt.which]
      delete keys_down[key]
    null

  window.requestAnimFrame = (->
    window.requestAnimationFrame       or
    window.webkitRequestAnimationFrame or
    window.mozRequestAnimationFrame    or
    window.oRequestAnimationFrame      or
    window.msRequestAnimationFrame     or
    (callback) ->
      window.setTimeout callback, 1000 / 60
  )()
  
  # load level
  
  level_table =
    0: 'bare'
    1: 'grass'
    2: 'water'
    3: 'tree'
  level =
    [ [ 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3 ]
    , [ 3, 3, 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 3, 3, 3 ]
    , [ 3, 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 3, 3 ]
    , [ 3, 3, 3, 3, 2, 2, 0, 0, 0, 0, 0, 3, 3, 3, 3 ]
    , [ 3, 3, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3 ]
    , [ 3, 3, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3 ]
    , [ 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 3 ]
    , [ 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 3 ]
    , [ 3, 3, 3, 3, 3, 2, 2, 0, 0, 3, 3, 3, 0, 3, 3 ]
    , [ 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3 ]
    , [ 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3 ]
    , [ 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3 ]
    ]
  for row, r in level
    for val, c in row
      r2 = r * 2
      c2 = c * 2
      str = level_table[val]
      scenery[r2][c2] = scenery[r2][c2 + 1] =
      scenery[r2 + 1][c2] = scenery[r2 + 1][c2 + 1] = level_table[val]

  addTile 'F', 6, 12
  addTile 'I', 4, 16
  addTile 'R', 4, 24
  addTile 'S', 12, 26
  addTile 'T', 16, 24
  addPickup 'apple', 10, 16

  addBody 'player', 10, 14
  addBody 'gazelle', 12, 14, speed: 4, walled: false
  
  # game loop

  (animloop = ->
    requestAnimFrame animloop
    if $('#running')[0].checked
      frame++
      anim_subframe++
      if anim_subframe is 5
        anim_subframe = 0
        anim_frame = (anim_frame + 1) % 4
      draw_scenery()
      draw_debug()
      draw_entities()
      update_entities()
      $('#debug')[0].innerHTML = "#{body_list}<br />#{pickup_list}"
    null
  )()
