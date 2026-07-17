// HEAVYSIDE — level data.
// Legend: # wall, . empty, P player, S stone, B bubble, z zapper, * star, E exit
// Gravity starts DOWN (free settle on load). `par` = optimal all-star move count
// (verified by solver.js — run it after editing any grid).
(function (global) {
  'use strict';

  var LEVELS = [
    {
      name: 'First Fall',
      hint: 'Swipe to change gravity. Reach the portal.',
      par: 1,
      grid: [
        '########',
        '#......#',
        '#P....E#',
        '########'
      ]
    },
    {
      name: 'Skyward',
      hint: 'Gravity works in every direction — even up.',
      par: 2,
      grid: [
        '########',
        '#....*E#',
        '#......#',
        '#......#',
        '#P.....#',
        '########'
      ]
    },
    {
      name: 'Chaperone',
      hint: 'Stones fall with you. Use them to stop your slide.',
      par: 4,
      grid: [
        '##########',
        '#P..S....#',
        '#........#',
        '#....#...#',
        '#....#.*.#',
        '#....#E..#',
        '##########'
      ]
    },
    {
      name: 'Live Wire',
      hint: 'Zappers end your run. Go around.',
      par: 3,
      grid: [
        '#########',
        '#P......#',
        '#...#...#',
        '#...#...#',
        '#...#..*#',
        '#..z#..E#',
        '#########'
      ]
    },
    {
      name: 'Demolition',
      hint: 'Stones smash zappers. Send one ahead of you.',
      par: 1,
      grid: [
        '########',
        '#......#',
        '#PS.z*E#',
        '########'
      ]
    },
    {
      name: 'Lighter Than Air',
      hint: 'Bubbles float AGAINST gravity. Swipe left to push it right.',
      par: 3,
      grid: [
        '#########',
        '#..z...E#',
        '#...#####',
        '#B......#',
        '#P......#',
        '#########'
      ]
    },
    {
      name: 'Crossfire',
      hint: 'Heavy sinks, light rises. Clear both wires.',
      par: 7,
      grid: [
        '#########',
        '#...z..E#',
        '#..###.##',
        '#B......#',
        '#P...S..#',
        '#..###.##',
        '#...z...#',
        '#########'
      ]
    },
    {
      name: 'Pachinko',
      hint: 'Pick your column before you drop.',
      par: 18,
      grid: [
        '##########',
        '#P..S..#.#',
        '#........#',
        '#.#.#.#.##',
        '#.#.#.#..#',
        '#*#z#E#.*#',
        '##########'
      ]
    },
    {
      name: 'Counterweight',
      hint: 'The bubble and the stone answer to different masters.',
      par: 4,
      grid: [
        '#########',
        '#.z....B#',
        '#.#####.#',
        '#.......#',
        '#.#####.#',
        '#S....z.#',
        '#P#####E#',
        '#########'
      ]
    },
    {
      name: 'Full Tilt',
      hint: 'Everything you know. Everything at once.',
      par: 14,
      grid: [
        '###########',
        '#P...#...*#',
        '#.S..#....#',
        '#....z....#',
        '#B..###.###',
        '#....z....#',
        '#*...#..E.#',
        '###########'
      ]
    }
  ];

  if (typeof module !== 'undefined' && module.exports) module.exports = LEVELS;
  else global.HEAVYSIDE_LEVELS = LEVELS;
})(typeof window !== 'undefined' ? window : globalThis);
