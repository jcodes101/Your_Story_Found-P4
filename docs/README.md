# The Last Expedition (Playtest Build)

Godot 4.3+ project, **Compatibility** renderer. Open `project.godot` in Godot and press F5.

## Controls
| Key | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Aim flashlight and sweep for marked dig sites |
| Hold **E** (3s) | Dig (can't move while digging) |
| Hold **R** (1.5s) | Brush |
| **F** | Pick up / drop an object, read the journal |
| Hold **G** (3s) | Restore the Holy Grail (needs all 4 fragments) |
| **F1** | Debug: toggle bright mode |
| **Enter** | Restart after win/lose |

## Goal
Recover 4 buried Grail fragments without damaging any, then hold G to restore it. Sweep the flashlight over the temple floor to reveal pulsing X marks that brighten in the beam; the fragments remain hidden until excavated. Nearby surroundings stay faintly visible, and the beam fades with distance. The flashlight has no battery limit. Start by reading the journal next to you (F).

## Files (who to hand off to)
| File | What it is | Owner (per team doc) |
|---|---|---|
| `main.gd` | Builds the level, wires everything, win/lose | everyone |
| `darkness.gdshader` + light code in `main.gd` (`_update_light`) | Mechanic 1: Flashlight | Hali |
| `dig_site.gd` + fragment/restore logic in `main.gd` | Mechanic 2: Fragment collection + restoration | Jadin |
| `artifact.gd` | Mechanic 3: Object inspection, blessings/curses | Jeremiah |
| `dig_site.gd` | Mechanic 4: Digging and brushing | Naomi |
| `player.gd`, `hud.gd` | Movement, on-screen text | shared |

## Rules implemented (from the team's Part 1 decisions)
- **Flashlight:** follows mouse, cone that fades with distance, small always-visible circle around the player, no battery. Surface markings brighten and gain a soft halo in the beam; buried fragments stay hidden until excavation. The Lantern Charm extends the beam and widens its cone.
- **Fragments:** 4 hidden; any damaged fragment = lose; hold G for 3s after collecting all 4 = win.
- **Objects:** carry one at a time; inspect by standing near (name + description on HUD); blessed ones boost light/speed; most cursed ones have a red outline + "!"; the **Gilded Mask** is unmarked and its curse only starts after 15s carried; dropping removes the effect.
- **Digging/brushing:** E 3s per layer (2 layers per fragment site), then you must brush (R). Digging again while brushing is needed (0.4s grace) damages the fragment. Brushing when not needed just wastes time. Decoy sites hold only pottery.

## Not built yet (ideas for this week)
- Real art/audio, collision walls, a bigger or randomized map
- Expedition timer (the pitch says "before the expedition ends in failure")
- More artifacts + inventory, a proper tutorial, polish on lose/win screens
- Jeremiah's water-spring repair idea (currently a damaged fragment = instant loss, per Jadin's decision)
