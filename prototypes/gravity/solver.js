// BFS solver — verifies every level is solvable and reports optimal move counts.
// Usage: node solver.js [levelIndex]
'use strict';
var E = require('./engine.js');
var LEVELS = require('./levels.js');

var DIR_NAMES = ['up', 'down', 'left', 'right'];

function allStars(s) {
  for (var i = 0; i < s.starTaken.length; i++) if (!s.starTaken[i]) return false;
  return true;
}

function solve(level, requireStars) {
  var s0 = E.initialState(level);
  s0 = E.applyMove(level, s0, 'down').state; // free initial settle
  if (s0.dead) return { error: 'player dies during initial settle' };
  if (s0.won && (!requireStars || allStars(s0))) return { moves: 0, path: [] };

  var seen = {};
  seen[E.serialize(s0)] = true;
  var queue = [{ s: s0, path: [] }];
  var head = 0;
  while (head < queue.length) {
    var cur = queue[head++];
    if (cur.path.length > 60) break;
    for (var d = 0; d < 4; d++) {
      var dir = DIR_NAMES[d];
      var res = E.applyMove(level, cur.s, dir);
      var ns = res.state;
      if (ns.dead) continue;
      var k = E.serialize(ns);
      if (seen[k]) continue;
      seen[k] = true;
      var path = cur.path.concat([dir]);
      if (ns.won && (!requireStars || allStars(ns))) {
        return { moves: path.length, path: path, states: Object.keys(seen).length };
      }
      if (!ns.won) queue.push({ s: ns, path: path });
    }
  }
  return { error: 'UNSOLVABLE (' + Object.keys(seen).length + ' states searched)' };
}

var only = process.argv[2] !== undefined ? parseInt(process.argv[2], 10) : null;

LEVELS.forEach(function (def, i) {
  if (only !== null && i !== only) return;
  var level;
  try { level = E.parseLevel(def); }
  catch (e) { console.log(i + '. PARSE ERROR: ' + e.message); return; }
  var anyWin = solve(level, false);
  var fullWin = solve(level, true);
  var line = i + '. ' + level.name + ' — ';
  if (anyWin.error) line += anyWin.error;
  else {
    line += 'win: ' + anyWin.moves + ' [' + anyWin.path.join(',') + ']';
    if (level.starCells.length) {
      line += fullWin.error
        ? ' | ALL-STARS: ' + fullWin.error
        : ' | all-stars: ' + fullWin.moves + ' [' + fullWin.path.join(',') + ']';
    }
    line += ' (par ' + level.par + ')';
  }
  console.log(line);
});
