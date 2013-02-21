$(document).ready () ->

  frame         = 0
  anim_frame    = 0 # 0 -> 1 -> 2 -> 3 -> 0, every 5th frame
  anim_subframe = 0 # 0 -> 1 -> 2 -> 3 -> 4 -> 0, every frame
  canvas_width  = 640
  canvas_height = 480

  num_rows      = 12
  num_columns   = 15
  square_width  = 32
  square_height = 32

  # The unchanging background of the world.
  # 0: bare
  # 1: grass
  # 2: water
  # 3: tree
  scenery =
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

  word    = 'FIRST'
  letters = ''
  apples  = 0
  bridges = 0

  newTile = (letter, r, c) ->
    sprite: 'tile'
    x: c * square_width
    y: r * square_height
    letter: letter

  newFloor = (sprite, r, c) ->
    sprite: sprite
    x: c * square_width
    y: r * square_height

  newBody = (sprite, r, c, misc = {}) ->
    obj =
      sprite: sprite
      x: c * square_width
      y: r * square_height
      facing: 'down'
      state: 'stopped'
      speed: 2
      was_moving: false # true if was moving last frame
    for k, v of misc
      obj[k] = v
    obj

  # Entities are square-sized objects which can change state.
  floor_entities =
    [ newTile('F', 3, 6)
    , newTile('I', 2, 8)
    , newTile('R', 2, 12)
    , newTile('S', 6, 13)
    , newTile('T', 8, 12)
    , newFloor('apple', 5, 8)
    ]
  body_entities =
    [ newBody('player', 5, 7)
    , newBody('gazelle', 6, 7, {speed: 4, walled: false})
    ]

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

  # entities which will be added/deleted on end of frame
  floor_to_add = []
  floor_to_delete = []
  body_to_add = []
  body_to_delete = []

  # 'playing', 'dead', 'complete'
  status = 'playing'

  canvas = $('#canvas')[0]
  ctx = canvas.getContext('2d')

  draw_scenery = ->
    ctx.fillStyle = 'black'
    ctx.fillRect 0, 0, canvas_width, canvas_height
    for r in [0 .. num_rows - 1]
      for c in [0 .. num_columns - 1]
        ctx.fillStyle = switch scenery[r][c]
          when 0 then '#ffffcc'
          when 1 then '#00ff00'
          when 2 then '#0033ff'
          when 3 then '#006600'
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
    for entity in floor_entities
      ctx.drawImage getImage(entity), entity.x + 10, entity.y + 10
    for entity in body_entities
      ctx.drawImage getImage(entity), entity.x + 10, entity.y + 10
    null

  # row and column should be multiples of 0.5.
  is_occupied = (row, column, entity_to_move) ->
    for entity in body_entities
      continue if entity is entity_to_move
      cx = column * square_width
      ry = row * square_height
      if cx - square_width < entity.x < cx + square_width
        if ry - square_height < entity.y < ry + square_height
          return true
    if entity_to_move.sprite isnt 'player'
      # Non-player body entities can't walk over floor entities
      for entity in floor_entities
        continue if entity is entity_to_move
        cx = column * square_width
        ry = row * square_height
        if cx - square_width < entity.x < cx + square_width
          if ry - square_height < entity.y < ry + square_height
            return true
    not walkable_bg(row, column)

  # row and column should be multiples of 0.5.
  walkable_bg = (row, column) ->
    unless row == Math.floor row
      return walkable_bg(row - 0.5, column) and walkable_bg(row + 0.5, column)
    unless column == Math.floor column
      return walkable_bg(row, column - 0.5) and walkable_bg(row, column + 0.5)
    return false if scenery[row][column] is 2
    return false if scenery[row][column] is 3
    true
  
  # returns [r, c] or null, where r and c are multiples of 0.5.
  entity_square = (entity) ->
    x = entity.x
    y = entity.y
    if x % (square_width / 2) isnt 0
      return null
    if y % (square_height / 2) isnt 0
      return null
    [y / square_height, x / square_width]

  get_next_square = (entity, direction) ->
    [r, c] = entity_square(entity)
    switch direction
      when 'left'  then [r,       c - 0.5]
      when 'right' then [r,       c + 0.5]
      when 'up'    then [r - 0.5, c      ]
      when 'down'  then [r + 0.5, c      ]

  bump = (entity) ->
    switch entity.facing
      when 'left'  then entity.x -= entity.speed
      when 'right' then entity.x += entity.speed
      when 'up'    then entity.y -= entity.speed
      when 'down'  then entity.y += entity.speed
    null

  start_moving = (entity, direction) ->
    entity.facing = direction
    entity.state = 'moving'
    bump entity
    null

  check_pickup = (x, y) ->
    for entity in floor_entities
      if entity.x is x and entity.y is y
        floor_to_delete.push entity
        switch entity.sprite
          when 'tile'
            letters += entity.letter
            status = 'complete' if letters is word
          when 'apple'  then apples++
          when 'bridge' then bridges++
    null
  
  clockwise = (dir) ->
    switch dir
      when 'up'    then 'right'
      when 'right' then 'down'
      when 'down'  then 'left'
      when 'left'  then 'up'
  
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

  # Handles updating the moving/stopped state, and applying movement to
  # position.
  check_movement = (entity) ->
    switch entity.state
      when 'moving'
        entity.was_moving = true
        bump entity
        if entity_square entity
          entity.state = 'stopped'
          check_pickup entity.x, entity.y if entity.sprite is 'player'
      when 'stopped'
        entity.was_moving = false
        switch entity.sprite
          when 'player'  then move_player  entity
          when 'gazelle' then move_gazelle entity
          when 'rhino'   then move_rhino   entity
    null

  can_move = (entity, direction) ->
    [r, c] = get_next_square(entity, direction)
    not is_occupied(r, c, entity)

  update_entities = ->
    for entity in body_entities
      check_movement entity
    null

  is_in = (x, ys) ->
    for y in ys
      return true if x is y
    false

  delete_entities = ->
    new_floor = []
    new_body  = []
    for entity in floor_entities
      unless is_in entity, floor_to_delete
        new_floor.push entity
    for entity in body_entities
      unless is_in entity, body_to_delete
        new_body.push entity
    floor_entities  = new_floor
    body_entities   = new_body
    floor_to_delete = []
    body_to_delete  = []
    null

  add_entities = ->
    floor_entities = floor_entities.concat(floor_to_add)
    body_entities  = body_entities.concat(body_to_add)
    floor_to_add   = []
    body_to_add    = []
    null
  
  keys =
    37: 'left'
    38: 'up'
    39: 'right'
    40: 'down'
    87: 'up'    # W
    65: 'left'  # A
    83: 'down'  # S
    68: 'right' # D

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

  (animloop = ->
    requestAnimFrame animloop
    frame++
    anim_subframe++
    if anim_subframe is 5
      anim_subframe = 0
      anim_frame = (anim_frame + 1) % 4
    draw_scenery()
    draw_debug()
    draw_entities()
    update_entities()
    delete_entities()
    add_entities()
    null
  )()
