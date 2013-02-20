// Generated by CoffeeScript 1.4.0
(function() {

  $(document).ready(function() {
    var add_entities, anim_frame, anim_subframe, animloop, apples, body_entities, body_to_add, body_to_delete, bridges, bump, can_move, canvas, canvas_height, canvas_width, check_movement, check_pickup, ctx, delete_entities, draw_debug, draw_entities, draw_scenery, floor_entities, floor_to_add, floor_to_delete, frame, getImage, get_next_square, get_square, imageURL, images, is_in, is_occupied, keys_down, letters, makeImage, newBody, newFloor, newTile, num_columns, num_rows, scenery, square_height, square_width, start_moving, status, update_entities, walkable_bg, word;
    frame = 0;
    anim_frame = 0;
    anim_subframe = 0;
    canvas_width = 640;
    canvas_height = 480;
    num_rows = 12;
    num_columns = 15;
    square_width = 32;
    square_height = 32;
    scenery = [[3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 3, 3, 3], [3, 3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 3, 3], [3, 3, 3, 3, 2, 2, 0, 0, 0, 0, 0, 3, 3, 3, 3], [3, 3, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3], [3, 3, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3], [3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 3], [3, 3, 3, 3, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 3], [3, 3, 3, 3, 3, 2, 2, 0, 0, 3, 3, 3, 0, 3, 3], [3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3], [3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3], [3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3]];
    word = 'FIRST';
    letters = '';
    apples = 0;
    bridges = 0;
    newTile = function(letter, r, c) {
      return {
        sprite: "tile",
        x: c * square_width,
        y: r * square_height,
        letter: letter
      };
    };
    newFloor = function(sprite, r, c) {
      return {
        sprite: sprite,
        x: c * square_width,
        y: r * square_height
      };
    };
    newBody = function(sprite, r, c) {
      return {
        sprite: sprite,
        x: c * square_width,
        y: r * square_height,
        facing: "down",
        state: "stopped"
      };
    };
    floor_entities = [newTile('F', 3, 6), newTile('I', 2, 8), newTile('R', 2, 12), newTile('S', 6, 13), newTile('T', 8, 12), newFloor('apple', 5, 8)];
    body_entities = [newBody('player', 5, 7)];
    makeImage = function(src) {
      var img;
      img = new Image();
      img.src = src;
      return img;
    };
    images = {};
    imageURL = function(entity) {
      switch (entity.sprite) {
        case "tile":
          return "img/floor/tile/" + entity.letter + ".png";
        case "apple":
          return "img/floor/apple.png";
        case "bridge":
          return "img/floor/bridge.png";
        case "player":
          switch (entity.state) {
            case "stopped":
              return "img/player/stopped/" + entity.facing + ".png";
            case "moving":
              return "img/player/moving/" + entity.facing + "/" + anim_frame + ".png";
          }
          break;
        case "dartdemon":
          return "img/dartdemon/" + entity.facing + ".png";
        case "gazelle":
          switch (entity.state) {
            case "stopped":
              return "img/gazelle/stopped/" + entity.facing + ".png";
            case "moving":
              return "img/gazelle/moving/" + entity.facing + "/" + anim_frame + ".png";
          }
      }
    };
    getImage = function(entity) {
      var img, url;
      url = imageURL(entity);
      if (img = images[url]) {
        return img;
      } else {
        img = makeImage(url);
        images[url] = img;
        return img;
      }
    };
    keys_down = {};
    floor_to_add = [];
    floor_to_delete = [];
    body_to_add = [];
    body_to_delete = [];
    status = 'playing';
    canvas = $("#canvas")[0];
    ctx = canvas.getContext("2d");
    draw_scenery = function() {
      var c, r, _i, _j, _ref, _ref1;
      ctx.fillStyle = "black";
      ctx.fillRect(0, 0, canvas_width, canvas_height);
      for (r = _i = 0, _ref = num_rows - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; r = 0 <= _ref ? ++_i : --_i) {
        for (c = _j = 0, _ref1 = num_columns - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; c = 0 <= _ref1 ? ++_j : --_j) {
          ctx.fillStyle = (function() {
            switch (scenery[r][c]) {
              case 0:
                return "#ffffcc";
              case 1:
                return "#00ff00";
              case 2:
                return "#0033ff";
              case 3:
                return "#006600";
            }
          })();
          ctx.fillRect(c * square_width + 10, r * square_height + 10, square_width, square_height);
        }
      }
      return null;
    };
    draw_debug = function() {
      var frameText;
      ctx.fillStyle = "white";
      frameText = Math.floor(frame / 60) + " | " + (frame % 60);
      ctx.fillText(frameText, 10, 410);
      ctx.fillText("Letters: " + letters, 10, 425);
      ctx.fillText(apples + " apples, " + bridges + " bridges", 10, 440);
      ctx.fillText("Target word: " + word, 10, 455);
      if (status === "dead") {
        ctx.fillText("Dead...", 10, 470);
      } else if (letters === word) {
        ctx.fillText("Victory!", 10, 470);
      } else if (word.indexOf(letters) === 0) {
        ctx.fillText("Playing", 10, 470);
      } else {
        ctx.fillText("Failure...", 10, 470);
      }
      return null;
    };
    draw_entities = function() {
      var entity, _i, _j, _len, _len1;
      for (_i = 0, _len = floor_entities.length; _i < _len; _i++) {
        entity = floor_entities[_i];
        ctx.drawImage(getImage(entity), entity.x + 10, entity.y + 10);
      }
      for (_j = 0, _len1 = body_entities.length; _j < _len1; _j++) {
        entity = body_entities[_j];
        ctx.drawImage(getImage(entity), entity.x + 10, entity.y + 10);
      }
      return null;
    };
    is_occupied = function(row, column, ignore_entity) {
      var cx, entity, ry, _i, _len, _ref, _ref1;
      for (_i = 0, _len = body_entities.length; _i < _len; _i++) {
        entity = body_entities[_i];
        if (ignore_entity === entity) {
          continue;
        }
        cx = column * square_width;
        ry = row * square_height;
        if ((cx - square_width < (_ref = entity.x) && _ref < cx + square_width) && (ry - square_height < (_ref1 = entity.y) && _ref1 < ry + square_height)) {
          return true;
        }
      }
      return !walkable_bg(row, column);
    };
    walkable_bg = function(row, column) {
      if (row !== Math.floor(row)) {
        return walkable_bg(row - 0.5, column) && walkable_bg(row + 0.5, column);
      }
      if (column !== Math.floor(column)) {
        return walkable_bg(row, column - 0.5) && walkable_bg(row, column + 0.5);
      }
      if (scenery[row][column] === 2) {
        return false;
      }
      if (scenery[row][column] === 3) {
        return false;
      }
      return true;
    };
    get_square = function(entity) {
      var x, y;
      x = entity.x;
      y = entity.y;
      if (x % (square_width / 2) !== 0 || y % (square_height / 2) !== 0) {
        return null;
      }
      return [y / square_height, x / square_width];
    };
    get_next_square = function(entity, direction) {
      var c, r, _ref;
      _ref = get_square(entity), r = _ref[0], c = _ref[1];
      switch (direction) {
        case "left":
          return [r, c - 0.5];
        case "right":
          return [r, c + 0.5];
        case "up":
          return [r - 0.5, c];
        case "down":
          return [r + 0.5, c];
      }
    };
    bump = function(entity) {
      switch (entity.facing) {
        case "left":
          entity.x -= 2;
          break;
        case "right":
          entity.x += 2;
          break;
        case "up":
          entity.y -= 2;
          break;
        case "down":
          entity.y += 2;
      }
      return null;
    };
    start_moving = function(entity, direction) {
      entity.facing = direction;
      entity.state = "moving";
      bump(entity);
      return null;
    };
    check_pickup = function(x, y) {
      var entity, _i, _len;
      for (_i = 0, _len = floor_entities.length; _i < _len; _i++) {
        entity = floor_entities[_i];
        if (entity.x === x && entity.y === y) {
          floor_to_delete.push(entity);
          switch (entity.sprite) {
            case "tile":
              letters += entity.letter;
              if (letters === word) {
                status = "complete";
              }
              break;
            case "apple":
              apples++;
              break;
            case "bridge":
              bridges++;
          }
        }
      }
      return null;
    };
    check_movement = function(entity) {
      var dir, kd;
      if (entity.state === "moving") {
        bump(entity);
        if (entity.x % (square_width / 2) === 0 && entity.y % (square_height / 2) === 0) {
          entity.state = "stopped";
          if (entity.sprite === "player") {
            check_pickup(entity.x, entity.y);
          }
        }
      } else if (entity.state === "stopped") {
        if (entity.sprite === "player") {
          kd = Object.keys(keys_down);
          if (kd.length) {
            dir = kd[0];
            entity.facing = dir;
            if (can_move(entity, dir)) {
              start_moving(entity, dir);
            }
          }
        }
      }
      return null;
    };
    can_move = function(entity, direction) {
      var c, r, _ref;
      _ref = get_next_square(entity, direction), r = _ref[0], c = _ref[1];
      return !is_occupied(r, c, entity);
    };
    update_entities = function() {
      var entity, _i, _len;
      for (_i = 0, _len = body_entities.length; _i < _len; _i++) {
        entity = body_entities[_i];
        check_movement(entity);
      }
      return null;
    };
    is_in = function(x, ys) {
      var y, _i, _len;
      for (_i = 0, _len = ys.length; _i < _len; _i++) {
        y = ys[_i];
        if (x === y) {
          return true;
        }
      }
      return false;
    };
    delete_entities = function() {
      var entity, new_body, new_floor, _i, _j, _len, _len1;
      new_floor = [];
      new_body = [];
      for (_i = 0, _len = floor_entities.length; _i < _len; _i++) {
        entity = floor_entities[_i];
        if (!is_in(entity, floor_to_delete)) {
          new_floor.push(entity);
        }
      }
      for (_j = 0, _len1 = body_entities.length; _j < _len1; _j++) {
        entity = body_entities[_j];
        if (!is_in(entity, body_to_delete)) {
          new_body.push(entity);
        }
      }
      floor_entities = new_floor;
      body_entities = new_body;
      floor_to_delete = [];
      body_to_delete = [];
      return null;
    };
    add_entities = function() {
      floor_entities = floor_entities.concat(floor_to_add);
      body_entities = body_entities.concat(body_to_add);
      floor_to_add = [];
      body_to_add = [];
      return null;
    };
    $(document).keydown(function(evt) {
      switch (evt.which) {
        case 37:
          keys_down["left"] = true;
          break;
        case 38:
          keys_down["up"] = true;
          break;
        case 39:
          keys_down["right"] = true;
          break;
        case 40:
          keys_down["down"] = true;
      }
      return null;
    });
    $(document).keyup(function(evt) {
      switch (evt.which) {
        case 37:
          delete keys_down["left"];
          break;
        case 38:
          delete keys_down["up"];
          break;
        case 39:
          delete keys_down["right"];
          break;
        case 40:
          delete keys_down["down"];
      }
      return null;
    });
    window.requestAnimFrame = (function() {
      return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback) {
        return window.setTimeout(callback, 1000 / 60);
      };
    })();
    return (animloop = function() {
      requestAnimFrame(animloop);
      frame++;
      anim_subframe++;
      if (anim_subframe === 5) {
        anim_subframe = 0;
        anim_frame = (anim_frame + 1) % 4;
      }
      draw_scenery();
      draw_debug();
      draw_entities();
      update_entities();
      delete_entities();
      add_entities();
      return null;
    })();
  });

}).call(this);
