# The Last Expedition (Playtest Build)

Godot 4.3+ project, **Compatibility** renderer. Open `project.godot` in Godot and press F5. The game opens at the main menu; begin the expedition, review the briefing, then choose **Enter Temple**.

## Controls
| Key | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Aim flashlight and sweep for marked dig sites |
| Hold **E** (3s) | Dig (can't move while digging) |
| Hold **R** (1.5s) | Brush |
| **F** | Pick up / drop an object, read the journal |
| Hold **G** (3s) | Restore the Holy Grail (needs all 4 fragments) |
| **Escape** | Pause / resume or return from a sub-screen |
| **Enter / Space** | Activate the focused menu button |
| **F1** | Debug: toggle bright mode |

## Playtest build
The default build is a compact first-person 3D temple. Read the entrance journal, follow the glowing ground marks, hold E for three seconds to dig a layer, and hold R for 1.5 seconds to brush before digging again. F takes or drops relics. Recover all four fragments intact and hold G for three seconds at the altar to restore the Grail. The ending screen offers a restart. The flashlight has no battery limit.

The murals and fragment inscriptions gradually reveal why the Grail was broken. A brief apparition appears once in the inner chamber. The original 2D game remains available from the main menu as **2D FALLBACK BUILD**.

## Files (who to hand off to)
| File | What it is | Owner (per team doc) |
|---|---|---|
| `main.gd` | Builds the level, connects mechanics, win/lose | everyone |
| `app.gd` + `main.tscn` | Main menu, briefing, pause, endings, scene lifecycle | shared |
| `gameplay.tscn` | Gameplay scene instantiated after the briefing | shared |
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
- Real art/audio, collision walls, a bigger or randomized map
- Expedition timer (the pitch says "before the expedition ends in failure")
- More artifacts + inventory
- Jeremiah's water-spring repair idea (currently a damaged fragment = instant loss, per Jadin's decision)
