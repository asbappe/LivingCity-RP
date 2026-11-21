# The Combine's own architecture: why it looks unnatural (work in progress, 21 November)

The owner's request (batch 6): "pay special attention to the odd, unnerving, and unnatural architecture of the
combine structures. they never have symmetrical architecture ... I want to reproduce it". Numbers from the VMFs
(read as text) of d3_citadel_01 to 05, d3_breen_01, ep1_intro, ep1_citadel_00 to 04, styleguide_core and
styleguide_destroyed_citadel, against the old buildings of d3_c17_10a, 10b, ep1_c17_00 and 01. Tools in the chat's
scratch folder (`arch/arch_lib.py`, `analyse.py`, `walls.py`). Status: first maps measured (d3_citadel_03,
ep1_citadel_00, styleguide_core, d3_c17_10b); the rest running.

## How it was measured

- Combine brushes: most of their visible area in citadel_*, metalcombine*, metalwall_combinecore*, combineglass,
  comshield, or metal/metalwall063/072/076/077/078/090/091/101 (the same plates outside the Citadel). Old: concrete,
  plaster, brick, building_template, stone, wood, tile, window glass. Skybox (the box round sky_camera), Hammer-hidden
  (hidden blocks, hidden visgroups) and tools faces left out. A face is visible when the point just in front of it is
  inside no other solid brush.
- Symmetry, three ways: (a) a wall's elevation as a depth picture on an 8 grid, mirrored about the best upright line
  in its middle half (share of cells that match within 1.5); (b) the two sides of a passage (walls facing each other
  64 to 640 apart): share of cells whose relief matches; (c) the box round a door (192 deep, door plus 160 each side):
  overlap of the left half with the mirrored right half.

(Recipe and generator plan come here when every map is in.)
