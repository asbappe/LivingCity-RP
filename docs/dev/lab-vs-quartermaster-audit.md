# The Resistance lab vs the quartermaster (audit, 14 November)

Prices at rest (no shortages or demand from `sv_livingcity_market.lua`), for a Resistance member. Sources: `LCS.Lab` and `LCS.Black` (sh_livingcity_shop.lua), `LC.LabPrice` (sv_livingcity_lab.lua), `LC.QuartermasterPrice` and `LC.OpenMarket` (sv_livingcity_underground.lua), `LC.SellPrice` (sv_livingcity_crafting.lua).

## How each works

| | The lab (scientist) | The quartermaster |
|---|---|---|
| Who | Resistance only; strangers are turned away | Resistance buy and sell; strangers may only sell or give arms (for sympathy) |
| Sells | 19 recipes: free with your materials, or for credits | 37 goods (the dealer's list), 2 of them his alone (paste-ups, pamphlets) |
| Price | `lc_lab_price` 0.6 of the dealer's, never under the buyback | The same formula (`LC.QuartermasterPrice` calls `LC.LabPrice`) |
| Wait | 5 to 20 seconds, you stay in the lab (he keeps it if you walk off) | None |
| Buys from you | Nothing | Anything with a sell value; arms at 1.5x (`lc_quartermaster_arms_bonus`), more when in demand; food and drink for at most 2; intel only he buys; not Combine chips (the lab decodes those) |
| Also | Decodes chips, surgery | Takes arms as gifts (sympathy, for strangers); decodes chips from his menu |

## What the lab makes, side by side

| Item | Lab: materials | Lab: pay | Quartermaster sells | He buys it back | Bought materials cost* |
|---|---|---|---|---|---|
| Pistol rounds | 2 scrap, 1 chemicals | 25 | 25 | 23 | 4 |
| Shotgun shells | 2 scrap, 2 chemicals | 33 | 33 | 30 | 8 |
| SMG rounds | 3 scrap, 2 chemicals | 40 | 40 | 38 | 8 |
| .357 rounds | 3 scrap, 2 chemicals | 33 | 33 | 30 | 8 |
| Pistol | 2 gun parts, 3 scrap | 72 | 72 | 68 | 26 |
| SMG | 4 gun parts, 6 scrap, 1 chemicals | 120 | 120 | 113 | 56 |
| Shotgun | 3 gun parts, 5 scrap | 126 | 126 | 120 | 39 |
| .357 revolver | 4 gun parts, 6 scrap, 1 chemicals | 144 | 144 | 135 | 56 |
| Powered vest | 6 scrap, 4 cloth, 1 chemicals | 54 | 54 | 30 | 4 |
| Bypass charge | 1 gun parts, 2 scrap, 2 chemicals | 42 | 42 | 25 | 21 |
| Smoke bomb | 1 empty can, 2 chemicals | 18 | 18 | 8 | 8 |
| Forged ration cards (5) | 3 paper, 1 chemicals | 30 | 30 (6 each) | 4 each | 4 |
| Radio transmitter | 1 Freq 7 radio, 2 scrap | 42 | 42 | 25 | 36 |
| Radio jammer | 1 Freq 7 radio, 2 scrap, 1 chemicals | 90 | 90 | 35 | 40 |
| Crowbar | 6 scrap | 30 | 30 (the weapon) | 20 (as a weapon) | 0 |
| Chemicals (from weedkiller) | 2 weedkiller | 4 | 4 | 3 | (weedkiller sells for 6 each) |
| **Charge cell** | 2 scrap, 2 chemicals | 30 | **not sold** | 8 | 8 |
| **Firebomb** | 2 weedkiller, 1 bottle, 1 rag | 30 | **not sold** | 25 | (found, not sold) |
| **Foil hat** (after enough dreams) | 1 scrap, 1 rag | 30 | **not sold** | 1 | 0 |

\* What the materials cost bought from the quartermaster himself (gun parts 13, chemicals 4, a Freq 7 radio 36). Scrap, rags, paper, cans, bottles and weedkiller he doesn't sell: they're found (bins, salvage, weeds), so count as 0 here.

## What only the quartermaster has

Freq 7 radio (36), forged papers (48), blank forms (18), lockpicks (21; also 4 scrap by hand), the Civil Protection uniform (96), the multitool (150), tablets, medicine, cigarettes, beer, moonshine, vodka, stimulants (limited stock), gun parts, chemicals, seeds, tinned food, cuffs, satchels, spray cans, and his own paste-ups and pamphlets. The lab also gets extra recipes for Commissary goods the Administrator restricts (`LC.MarketLabList`), priced the same way.

## What stands out

1. **Paying the lab is pointless for 16 of its 19 recipes.** The quartermaster sells the same thing at exactly the same price, at once, with no standing in the lab. Paying the scientist only makes sense for the three he alone makes (charge cells, firebombs, foil hats). The lab's real value is making things free from your own materials.
2. **A credit loop through gun parts.** Buy gun parts from the quartermaster (13 each), have the lab make the gun from them for free, sell the gun back to the quartermaster at the arms rate: a pistol nets about 42, an SMG about 57, a revolver about 79, a shotgun about 81. Ammunition does the same from chemicals (4) and found scrap: about 19 to 30 a box. Nothing caps it but the lab's few seconds a job.
3. **Selling back is close to buying for arms, far below for everything else.** Guns and ammo come back at 93 to 95% of the price; the vest, bypass, transmitter and jammer at 40 to 60%; smoke bombs and forged cards at a quarter or less.
4. **Some recipes aren't worth making.** Chemicals from weedkiller turns 12 credits of weedkiller into a 4-credit bottle. The transmitter's radio costs 36 bought, so the lab saves only 6 over buying it outright.
5. **The crowbar is two different things.** The lab makes it as an item (sells back 14 as an item), the quartermaster sells the weapon (sells back 20); the same 30 either way.

## What the owner chose (14 November), and what was done

- Nothing the quartermaster sells is made or listed at the lab: the lab keeps charge cells, firebombs and the foil hat, and its services (decoding, a new face, pulling the chip). That ends the gun loop too (the lab makes no guns).
- The weedkiller-to-chemicals recipe is gone; the transmitter went with the rest (the quartermaster sells it).
- Surgery: forty seconds under, black screen, scripted sounds.

## The choices as first offered

- Close the gun loop: the lab could refuse to make guns from bought gun parts' full value (for example, the quartermaster buying lab-made arms back at the plain sell price, not 1.5x), or gun parts could cost more.
- Give the lab's "pay" option a reason: a lower price than the quartermaster (for example 0.45 instead of 0.6), or keep the quartermaster for goods the lab doesn't make and take the lab's recipes off his list.
- Drop or rework the weedkiller-to-chemicals recipe.
