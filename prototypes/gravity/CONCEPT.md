# HEAVYSIDE — Concept & Plan

*Working title. A gravity puzzle game where every swipe tilts the world for everything at once.*

## The hook

Most gravity games flip gravity for **you**. In HEAVYSIDE, a swipe re-aims gravity for the
**entire board simultaneously**:

- **You** (the Core) fall with gravity until you hit something.
- **Stones** fall with gravity too — they smash hazards and become movable walls that stop your slide.
- **Bubbles** fall *against* gravity — swipe left and they drift right. Two entity types obeying
  opposite masters from a single input is the mind-bender that makes puzzles feel fresh.

Zappers kill you but are destroyed by any block that hits them; stars are optional pickups;
the portal wins the level. Ratings: 1★ finish, 2★ all stars, 3★ all stars within par.

## Why this can work commercially

- **One-thumb, portrait, sessions under a minute per level** — ideal interstitial/rewarded ad shape.
- Deterministic grid logic means levels are cheap to author and can be **machine-verified**
  (`solver.js` BFS-proves solvability and computes true pars — already wired up).
- Difficulty knobs are clean: board size, entity count, par tightness, bonus-star depth
  (Pachinko's bonus star is an 18-move optimal chase on a 3-move level).

## Prototype (this folder)

- `index.html` — playable in any browser, mobile-first (swipe) + desktop (arrows/WASD, drag).
- `engine.js` — pure rules engine, shared by game and solver. No rendering, no DOM.
- `levels.js` — 10 levels teaching each mechanic in order.
- `solver.js` — `node solver.js` verifies every level and prints optimal paths.

Run locally: open `index.html`, or `python3 -m http.server` in this folder.

## Path to $100 (realistic version)

$100 net is a real but modest bar — the plan is ads-first, minimal spend:

1. **Validate fun (now):** share the browser prototype link with ~10 people. Watch where they
   quit. If nobody finishes level 6, fix the game before writing a line of Godot.
2. **Port to Godot (this repo):** the engine is ~300 lines of pure logic — a direct GDScript
   translation. Reuse TechnoBeat's audio system, mobile export setup, and AdMob notes.
3. **Content:** 60–80 levels (levels are ASCII strings + solver verification, so this is fast).
   Optional daily puzzle for retention.
4. **Monetize lightly:** interstitial every 3–4 levels, rewarded ad for "show next move"
   (the BFS solver literally *is* the hint system — it can generate the optimal next move at
   runtime or bake hints per level), and a single $1.99 "remove ads" IAP.
5. **Distribution:** Google Play first ($25 one-time fee vs Apple's $99/yr — protects the $100
   goal). Also ship the HTML version to web game portals (Poki/CrazyGames submissions are free
   and pay rev-share) — a second shot at the same $100 with zero store fees.

Rough math: at ~$8–12 eCPM for rewarded video, $100 ≈ 10–12k ad impressions ≈ ~1.5–3k installs
with average engagement. Portal rev-share can hit the number with a few thousand plays.

## Next steps

- [ ] Playtest the prototype, tune TICK_MS / level order
- [ ] 10 more levels (introduce: one-way gates? sticky cells? timed zappers?)
- [ ] GDScript port of `engine.js` + juice (screen shake, beat-synced SFX à la TechnoBeat)
- [ ] Hint system backed by the solver
- [ ] Play Store closed track + portal submissions
