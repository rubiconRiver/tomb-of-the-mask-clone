// HEAVYSIDE — pure puzzle engine (no rendering, runs in browser or Node)
//
// Rules:
//  - Swiping sets the gravity direction for the whole board.
//  - The player orb and STONES fall WITH gravity; BUBBLES float AGAINST it.
//  - Everything moves at once, one cell per tick, until nothing can move.
//  - Zappers kill the player, but a stone or bubble that falls into one
//    destroys both the zapper and itself.
//  - Stars are collected when the player passes through them.
//  - The player wins on touching the exit; stones/bubbles can't enter it.
(function (global) {
  'use strict';

  var DIRS = {
    up: { dr: -1, dc: 0 },
    down: { dr: 1, dc: 0 },
    left: { dr: 0, dc: -1 },
    right: { dr: 0, dc: 1 }
  };

  function parseLevel(def) {
    var grid = def.grid;
    var rows = grid.length;
    var cols = grid[0].length;
    var level = {
      name: def.name || 'Untitled',
      hint: def.hint || '',
      par: def.par || 0,
      rows: rows,
      cols: cols,
      walls: {},
      starCells: [],
      zapperCells: [],
      exit: null,
      start: { player: null, stones: [], bubbles: [] }
    };
    for (var r = 0; r < rows; r++) {
      if (grid[r].length !== cols) throw new Error(level.name + ': ragged row ' + r);
      for (var c = 0; c < cols; c++) {
        var ch = grid[r][c];
        var key = r * cols + c;
        if (ch === '#') level.walls[key] = true;
        else if (ch === 'P') level.start.player = { r: r, c: c };
        else if (ch === 'S') level.start.stones.push({ r: r, c: c });
        else if (ch === 'B') level.start.bubbles.push({ r: r, c: c });
        else if (ch === 'z') level.zapperCells.push({ r: r, c: c });
        else if (ch === '*') level.starCells.push({ r: r, c: c });
        else if (ch === 'E') level.exit = { r: r, c: c };
      }
    }
    if (!level.start.player) throw new Error(level.name + ': no player');
    if (!level.exit) throw new Error(level.name + ': no exit');
    return level;
  }

  function initialState(level) {
    return {
      player: { r: level.start.player.r, c: level.start.player.c },
      stones: level.start.stones.map(function (p) { return { r: p.r, c: p.c }; }),
      bubbles: level.start.bubbles.map(function (p) { return { r: p.r, c: p.c }; }),
      zapperAlive: level.zapperCells.map(function () { return true; }),
      starTaken: level.starCells.map(function () { return false; }),
      won: false,
      dead: false,
      moves: 0
    };
  }

  function cloneState(s) {
    return {
      player: s.player ? { r: s.player.r, c: s.player.c } : null,
      stones: s.stones.map(function (p) { return p ? { r: p.r, c: p.c } : null; }),
      bubbles: s.bubbles.map(function (p) { return p ? { r: p.r, c: p.c } : null; }),
      zapperAlive: s.zapperAlive.slice(),
      starTaken: s.starTaken.slice(),
      won: s.won,
      dead: s.dead,
      moves: s.moves
    };
  }

  function serialize(s) {
    function pp(p) { return p ? p.r + ',' + p.c : 'x'; }
    return pp(s.player) + '|' +
      s.stones.map(pp).sort().join(';') + '|' +
      s.bubbles.map(pp).sort().join(';') + '|' +
      s.zapperAlive.join('') + '|' +
      s.starTaken.join('') + '|' +
      (s.won ? 'W' : s.dead ? 'D' : '-');
  }

  function snapshot(s) {
    return {
      player: s.player ? { r: s.player.r, c: s.player.c } : null,
      stones: s.stones.map(function (p) { return p ? { r: p.r, c: p.c } : null; }),
      bubbles: s.bubbles.map(function (p) { return p ? { r: p.r, c: p.c } : null; })
    };
  }

  // Applies one gravity move. Returns { state, frames, events }.
  // frames[i] = entity positions after tick i (frames[0] = before any tick),
  // events = [{tick, type, r, c, ...}] for rendering/sfx.
  function applyMove(level, s0, dirName) {
    var dir = DIRS[dirName];
    var s = cloneState(s0);
    var frames = [snapshot(s)];
    var events = [];
    if (s.won || s.dead) return { state: s, frames: frames, events: events };

    function key(r, c) { return r * level.cols + c; }
    function isWall(r, c) {
      return r < 0 || c < 0 || r >= level.rows || c >= level.cols || level.walls[key(r, c)];
    }
    function zapperAt(r, c) {
      for (var i = 0; i < level.zapperCells.length; i++) {
        var z = level.zapperCells[i];
        if (s.zapperAlive[i] && z.r === r && z.c === c) return i;
      }
      return -1;
    }
    function starAt(r, c) {
      for (var i = 0; i < level.starCells.length; i++) {
        var st = level.starCells[i];
        if (!s.starTaken[i] && st.r === r && st.c === c) return i;
      }
      return -1;
    }

    var maxTicks = level.rows * level.cols * 4 + 20;
    var movedAny = true;
    var tick = 0;

    while (movedAny && tick < maxTicks) {
      movedAny = false;
      tick++;

      // occupancy map, updated as entities move within the tick
      var occ = {};
      if (s.player && !s.dead && !s.won) occ[key(s.player.r, s.player.c)] = true;
      s.stones.forEach(function (p) { if (p) occ[key(p.r, p.c)] = true; });
      s.bubbles.forEach(function (p) { if (p) occ[key(p.r, p.c)] = true; });

      var movers = [];
      if (s.player && !s.dead && !s.won) {
        movers.push({ kind: 'player', dr: dir.dr, dc: dir.dc,
          get: function () { return s.player; },
          set: function (p) { s.player = p; } });
      }
      s.stones.forEach(function (p, i) {
        if (!p) return;
        movers.push({ kind: 'stone', idx: i, dr: dir.dr, dc: dir.dc,
          get: function () { return s.stones[i]; },
          set: function (q) { s.stones[i] = q; } });
      });
      s.bubbles.forEach(function (p, i) {
        if (!p) return;
        movers.push({ kind: 'bubble', idx: i, dr: -dir.dr, dc: -dir.dc,
          get: function () { return s.bubbles[i]; },
          set: function (q) { s.bubbles[i] = q; } });
      });

      // furthest along its own travel direction moves first
      movers.sort(function (a, b) {
        var pa = a.get(), pb = b.get();
        return (pb.r * b.dr + pb.c * b.dc) - (pa.r * a.dr + pa.c * a.dc);
      });

      for (var m = 0; m < movers.length; m++) {
        var mv = movers[m];
        var p = mv.get();
        if (!p) continue;
        var nr = p.r + mv.dr, nc = p.c + mv.dc;
        if (isWall(nr, nc)) continue;
        if (occ[key(nr, nc)]) continue;

        var zi = zapperAt(nr, nc);
        if (zi >= 0) {
          if (mv.kind === 'player') {
            // player moves in and dies
            delete occ[key(p.r, p.c)];
            mv.set({ r: nr, c: nc });
            s.dead = true;
            events.push({ tick: tick, type: 'death', r: nr, c: nc });
            movedAny = true;
          } else {
            // block smashes the zapper; both are destroyed
            delete occ[key(p.r, p.c)];
            mv.set(null);
            s.zapperAlive[zi] = false;
            events.push({ tick: tick, type: 'smash', r: nr, c: nc, kind: mv.kind, fr: p.r, fc: p.c });
            movedAny = true;
          }
          continue;
        }

        if (level.exit.r === nr && level.exit.c === nc) {
          if (mv.kind === 'player') {
            delete occ[key(p.r, p.c)];
            mv.set({ r: nr, c: nc });
            s.won = true;
            events.push({ tick: tick, type: 'win', r: nr, c: nc });
            movedAny = true;
          }
          // stones/bubbles treat the exit as solid
          continue;
        }

        // plain move
        delete occ[key(p.r, p.c)];
        occ[key(nr, nc)] = true;
        mv.set({ r: nr, c: nc });
        movedAny = true;

        if (mv.kind === 'player') {
          var si = starAt(nr, nc);
          if (si >= 0) {
            s.starTaken[si] = true;
            events.push({ tick: tick, type: 'star', r: nr, c: nc });
          }
        }
      }

      if (movedAny) frames.push(snapshot(s));
    }

    return { state: s, frames: frames, events: events };
  }

  var api = {
    DIRS: DIRS,
    parseLevel: parseLevel,
    initialState: initialState,
    cloneState: cloneState,
    serialize: serialize,
    applyMove: applyMove
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else global.HeavysideEngine = api;
})(typeof window !== 'undefined' ? window : globalThis);
