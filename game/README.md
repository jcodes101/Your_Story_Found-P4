# The Last Expedition (Playtest Build)

Godot 4.3+ project, **Compatibility** renderer. Open `project.godot` in Godot and press F5. The game opens at the main menu; begin the expedition, review the briefing, then choose **Enter Temple**.

## Controls
| Key | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Aim flashlight and sweep for marked dig sites |
| Hold **E** (3s) | Dig (can't move while digging) |
| Hold **R** (1.5s) | Brush |
| **F** | Activate the orb, inspect clues, collect fragments, take / drop relics |
| **J** | Open / close the fragment journal |
| Hold **C** | Crouch through the hidden fissure |
| Hold **G** (3s) | Restore the Holy Grail (needs all 4 fragments) |
| **Escape** | Pause / resume or return from a sub-screen |
| **Enter / Space** | Continue from a fragment inspection; activate focused menu buttons |
| **F1** | Debug: toggle bright mode |

## Playtest build
The default build is a compact first-person 3D temple. The sanctuary orb opens the stone route to Room 3; the sealed gate blocks that route until the orb is activated. Investigate the lit crack there with F, then hold C to crouch through the fissure into the inner chamber. E digs each layer for three seconds; R brushes. When a fragment is exposed, press F to physically collect it. J reopens its inscription in the field journal. F also examines murals and takes or drops optional relics. Recover all four intact, return to the altar, and hold G for three seconds. The finale plays before the success screen. The flashlight has no battery limit. Nearby shapes stay faintly visible, while details and burial markings beyond roughly 12 meters need the mouse-aimed beam. Optional side rooms contain a Pilgrim Prism that widens and extends the beam and a Scribe's Lens that makes burial marks pulse brighter. Dropping a relic removes its benefit.

Painted murals depict the Grail's ceremony, curse, deliberate separation, and final revelation. Large, faded wall warnings grow more direct as the player advances; the flashlight helps reveal them in the dark. Fragment inspections pause the action and show their individual clues. A brief apparition appears once when the inner mural is examined. The original 2D game remains available from the main menu as **2D FALLBACK BUILD**.

## Art direction
The 3D rooms use an original aged-sandstone material, rounded stone piers, framed doorways, and restrained atmospheric lighting. Six frescoes distinguish the story spaces: the original ritual, curse, division, and reveal murals, plus `murals/votive_gallery_fresco.png` (the cup sustaining a thriving people) and `murals/scribe_vault_fresco.png` (the keepers dividing the cup as later explorers flee). These optional rooms reward searching with flashlight upgrades and add visual context before the final altar. The reveal mural is hidden until restoration. The texture asset is `art_sandstone.png`.

## Files (who to hand off to)
| File | What it is | Owner (per team doc) |
|---|---|---|
| `main.gd` | Builds the level, connects mechanics, win/lose | everyone |
| `app.gd` + `main.tscn` | Main menu, briefing, pause, endings, scene lifecycle | shared |
| `gameplay_3d.gd` + `gameplay_3d.tscn` | Default first-person 3D gameplay scene | shared |
| `gameplay.tscn` | Original 2D gameplay fallback | shared |
| `grail_emblem.gd`, `direction_cue.gd` | Procedural menu/end art and first-site pointer | shared |
| `darkness.gdshader` + light code in `main.gd` (`_update_light`) | Mechanic 1: Flashlight | Hali |
| `fragment_collection.gd` + integration in `main.gd` | Mechanic 2: Fragment collection + restoration | Jadin |
| `dig_site.gd` | Mechanic 4: Digging and brushing; emits completion and damage events | Naomi |
| `artifact.gd` | Mechanic 3: Object inspection, blessings/curses | Jeremiah |
| `player.gd`, `hud.gd` | Movement, on-screen text | shared |

## Rules implemented (from the team's Part 1 decisions)
- **Flashlight:** follows mouse, cone that fades with distance, small always-visible circle around the player, no battery. Surface markings brighten and gain a soft halo in the beam; buried fragments stay hidden until excavation. Some relics change the beam, but their effects are not labeled in the player-facing inspection text.
- **Fragments:** IDs 1–4 are tracked once each; any damaged fragment = lose; hold G for 3s with all 4 intact = win.
- **Objects:** carry one at a time; inspect by standing near (name + atmospheric description on HUD), while the actual effect is left for the player to discover. Most risky objects have a red outline + "!"; the **Gilded Mask** is unmarked and its hidden effect only starts after 15s carried; dropping removes the effect.
- **Digging/brushing:** E 3s per layer (2 layers per fragment site), then you must brush (R). Digging again while brushing is needed (0.4s grace) damages the fragment. Brushing when not needed just wastes time. Decoy sites hold only pottery.

## Remaining ideas
- More optional relic variety and a longer expedition mode
- The approved playtest rules remain authoritative: a damaged required fragment ends the expedition, with no repair action.
