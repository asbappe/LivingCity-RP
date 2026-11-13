# Gas masks, and how people take the gas and the flashbang

Asked for by the owner, 13 November.

## Gas masks

- **Contraband** (`gas_mask`, `gas_mask_broken`): "a gasmask is contraband, so no" citizen ever has one. Units have their own (their mask, as before).
- **Off a uniform**: a Civil Protection uniform in a rebel's or citizen's pockets gets a **Scavenge gas mask** button (F3). Five seconds, keeping still; the uniform is used up. Seen by a unit, it's a crime ("Possessing Combine equipment").
- **Off the dead**: searching a dead Civil Protection or Overwatch unit always turns up their mask: whole half the time ("if the combine unit is dead, the gas mask is likely broken"), else broken (`LC.DeadUnitMask`, `LC.GASMASK_INTACT` 0.5).
- **Four broken make one**: F3's Make list (out of sight of units, ten seconds).
- **Resistance fighters**: about 1 in 3 carries one (`lc_gasmask_rebels`, 0.33), decided once per fighter.

## In the gas (chlorine, and the Combine's weedkiller gas)

- **A mask goes on by itself** as the gas reaches someone carrying one, NPC or player (nothing to pick), and keeps the gas out completely. A player is told the first time. It comes off by itself 3 seconds after they're out of the gas (`LC.GasMaskOn`, `LC.GasMaskOff`). Players see the edge of the visor and hear their breathing while it's on.
- **Everyone else covers their mouth with their left hand and coughs** for as long as they're in it, players and NPCs (`LC.HandToFace`, NW2 `lc_handface` "mouth").
- **NPCs run from it as fast as they can** (`LC.GasFlee`, `LC.GasFleeSpot`): eight ways out of the cloud are tried, each as far as there's room; they take the way out with no Combine unit (city units or unit players) near it, the farthest from the gas; only if every way has Combine units on it do they take the one with fewest, straight into them. While running their own thinking waits (`st.gasFleeUntil`). Metrocops and the Overwatch don't run: they're masked (unless an Insider fouled the filters, as before).

## The flashbang

- **A blinded NPC covers their eyes with their left hand** ("preferably left hand, since their right is holding their weapon") for as long as they're blind, standing pressing their eyes and stumbling a few steps in turn (sv_livingcity_fieldops.lua). This replaces Half-Life 2's two-handed flinch, which is still used with `lc_flash_hand` 0. Their weapons are still taken away while blind, as since 11 November.

## How it's drawn

- cl_livingcity_gasmask.lua. **The mask** is the Metrocop's own model drawn on the wearer with every bone but the head folded away, so only his helmet and mask show, on the wearer's head. (The owner hoped the mask alone could be cut out of the Metrocop model: that needs the model taken apart and rebuilt on a PC; this needs no new files.) **The hand** is the left arm turned bone by bone, on top of whatever they're doing, like the cuffed pose; a cuffed person's arms are left to the cuffs.
- Tuned by eye (your own client): `lc_gasmask_show`, `lc_gasmask_fit` ("forward right up scale"), `lc_handface_eyes` and `lc_handface_mouth` ("raised in twist bend wrist").

Tests: `GasMaskTests`, and the flashbang section of `RetakeFieldTests`.
