# Food scarcity: an audit (7 November 2026)

The owner: "hardly any scarcity, I end up with too much food without trying." Credits and pay are in `economy-audit.md`; this is food only. Paths are under `gamemode/modules/`.

**Headline: a working citizen gets 2 to 3 times the food hunger uses from the dispenser alone, before spending a credit, and a lone rebel's crate, refilled by NPC scavenging runs that ignore how many rebels there are, gives 4 to 6 times.**

## How fast hunger goes

- `lc_hunger_minutes` 60: full to starving in an hour, so **100 hunger an hour** (75 after a good night's sleep, 200 with parasites). `server/sv_livingcity_survival.lua:35,409-413`.
- Spawn at 80; after a death hunger comes back to at least 60 (`survival.lua:446-450`), so a death is a free meal.
- Food values (`shared/sh_livingcity_shop.lua:26-44,135-159`): ration 45, short ration 31, canned beans 35, fried fish 35, roast headcrab 40, roast bird 30, bread 30, vegetables 25. Eating also heals hunger/4.

## Every source

| Source | Numbers | Where |
|---|---|---|
| Dispenser | one ration per `lc_ration_interval` 600 s (6 an hour; 12 in the "rations" event), one card each; short ration below `lc_ration_full_standing` 150 | survival.lua:45,1193,1340 |
| Ration cards | `lc_shift_ration_cards` 1 per finished shift (+1 at Exemplary). A shift takes about 6 to 8 minutes, so about 8 cards an hour against 6 rations: cards never run short | server/sv_livingcity_work.lua:34,1537 |
| Commissary | ration 5, bread 8, milk 8 (standing 0), melon 25 (400). No card, no stock limit unless the Administrator marks it scarce (`lc_market_scarce_stock` 5, +1 per 20 min) | shop.lua:355,362-365; market.lua:59-60 |
| Black market | canned beans 14, forged card 10, seeds 12 | shop.lua:403,413-414 |
| City bins | 3 s search, refill `lc_scavenge_refill` 600 s; food 12 in 113 (beans 8, bread 4), about 3.5 hunger a search, plus seeds 5 in 113. Every bin model and static bin on the map counts | scavenge.lua:44,118-121 |
| Fridges | same table, refill `lc_fridge_refill` 240 s | scavenge.lua:45 |
| Rebel bins | beans 16 in 108, seeds 10 in 108: about 12 hunger a search counting the pot | scavenge.lua:122-125 |
| Pots | 2 per rebel zone; a seed packet gives 3 vegetables (75) in `lc_garden_minutes` 8 | scavenge.lua:46,567 |
| Fishing | line 15 credits, 4 to 8 casts; a cast is 10 to 22 s, 58% a fish (35 cooked). About **75 hunger per minute of fishing**; one line is about 120 hunger | scavenge.lua:235,247,264 |
| Birds | `lc_birds` 6 alive; a dead one is replaced within 4 s (one spawn per 4 s tick), so endless. Roast 30 | survival.lua:43,767-795 |
| Headcrabs | `lc_vermin` 2 roaming, replaced the same way, plus every crab in an infestation. Roast 40 | survival.lua:44,794-795 |
| Supply crate | every `lc_food_restock_minutes` 20 it gets `lc_food_availability` 0.5 of what the rebels online eat: **about 1.4 tins an hour per rebel**. One tin per player per 240 s | scavenge.lua:47-51,424-487,532 |
| NPC rebel runs | one run per rebel zone every `lc_rebel_errand_minutes` 4, 75% chance of 1 or 2 meals: **about 15 meals an hour per zone, whatever the headcount** | rebellife.lua:49,1050,1092 |
| Quests and ops | 6 meals (smuggling quest), 3 (supply drop raid) into the crate | quests.lua:1798; resistanceops.lua:543 |
| City stores | `lc_stock_max` 400; in: player kitchen shift +12, factory +8, NPC workers 1 to 4, train +15, convoy +15 a load; out: each ration, and 1 a minute per 40 citizens out (60 an hour). One player on kitchen (about 96 an hour) outruns the city | stockpile.lua:28-29,123-138,153 |
| Skimming | each good part pocketed on a Ration Production line is a ration; only risk stops it | jobgames.lua:541 |
| Bodies, pockets | dead citizen 35% ration, 12% bread; cop 15%; rebel 30% beans; pickpocket 12% ration | bodies.lua:36-61; talk.lua:244 |
| Hacked dispenser | 5 to 8 rations, every 10 min per dispenser (multitool) | survival.lua:47-53 |
| CP | supply locker ration every 600 s plus a duty voucher every 600 s | cpsupply.lua:102; cp.lua:1022 |

## Food in against food needed, per hour

**Citizen** (Union work, 8 shifts): dispenser 6 x 45 = **270** (6 x 31 = 186 below Trusted) against a need of **100**. Pay is about 120 credits, which buys 24 more rations (1080) if they wanted. Bins and fridges on the way add another 30 to 100. Even at the short ration the dispenser alone is nearly double.

**Rebel, alone:** crate gets about 1.4 tins from restocks plus about 15 from NPC runs, capped at 12 to 14 in the crate; the 240 s cooldown lets them take 15 tins (525) an hour. Need **100**. Two minutes of fishing or one bird a quarter hour covers the rest twice over.

**Rebels, ten in one zone:** restocks 14 + NPC runs 15 = about 29 tins shared, about 100 each: just even, before fishing, birds, bins and pots. So the crate only bites with a big Resistance; the other sources never do.

## Proposed changes (yes or no each)

1. Dispenser `lc_ration_interval` 600 to 1500 (2.4 rations an hour: 108 full, 74 short, about the need).
2. Commissary ration price 5 to 15, bread and milk 8 to 15 (one shift buys one meal, not three; `shop.lua:355,362-363`).
3. NPC rebel runs: `lc_rebel_errand_minutes` 4 to 12 (about 5 meals an hour per zone).
4. Crate cooldown per player 240 s to 900 s (a small code change, `scavenge.lua:532`).
5. Fishing: fish chance 58% to 30% and a cast 10-22 s to 25-45 s (`scavenge.lua:235,264`).
6. Birds and roaming headcrabs: a replacement every 90 s instead of every 4 s, `lc_birds` 6 to 4 (`survival.lua:767-795`).
7. Bins: `lc_scavenge_refill` 600 to 1800, `lc_fridge_refill` 240 to 900.
8. City stores: `lc_stock_eat` 40 to 20, so the stores run low more often (low already slows dispensers and refuses 35%).
9. A death no longer tops hunger up to 60; it keeps what you had, at least 25 (`survival.lua:450`).
10. Hunger `lc_hunger_minutes` 60 to 45 (need 133 an hour), only if 1 to 9 aren't enough.
