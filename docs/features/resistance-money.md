# The Resistance's own money (19 November)

The owner, 19 November, wanted the Resistance to earn money the way real movements do ("mafia-esque tactics ... Making their own bootleg alcohol and selling it to the black market dealer"), chose five ways from a list, and added for all of them: "the resistance member doing the deed/act/work gets a maybe 50% cut for the brewing of moonshine or robbing the paymaster or for selling/smuggling combine gear, etc." And on logic: "please be logical ... why would anyone deliver things for free"; "killing headcrabs and bringing their corpses home does not magically produce credits; only raids, sweeps, etc would have a logical way for credits to be provided".

`sv_livingcity_resistancemoney.lua` (all five), `entities/lc_still.lua`, `entities/lc_cardtable.lua`, `cl_livingcity_cards.lua` (the card window); the dealer's buying and selling in `sv_livingcity_underground.lua`; the flags in `sh_livingcity_shop.lua`. Tests: `Nov19_ResistanceMoneyTests`, the client smoke test, the robot players (`res_paymaster`). Every credit into the fund is one line in the server's log with a short reason ("Moonshine x3 sold to the dealer (Kerr)", "The dealer's rent", "The paymaster's satchel", "The card table's take", "The card table paid out (Kerr)").

Nothing is said about any of it beyond what was there: no notice, hint, chat line or announcement, except the still's one line and the paymaster job's posting (posted the way the supply drop's raid job is).

## 1. The still

The owner: "The still. Moonshine brewed at the camp or lab from water, bottles and ration food over time, then sold to the black market dealer."

- **A fixture**, "Fixture: Resistance still" in the editor (point kind `still`, entity `lc_still`, a boiler), meant for a camp or beside the lab. Saved with the layout like any fixture.
- **A Resistance member presses E with the makings in their pockets:** a ration packet (or a short ration), 2 water (any bottle or can of water, untreated included: the still boils it) and an empty bottle for each bottle made, 4. They are taken, and it brews by itself for **5 minutes**. Nobody has to stay (house rule 9): it steams and hisses quietly while it works. **E when it is done takes the 4 bottles of moonshine** (any member may take them). Anyone else's E does nothing.
- Lacking something, one line: "You need a ration packet, 2 water and 4 empty bottles."
- **Moonshine is contraband**, as it always was: a unit's search takes it.
- The numbers are constants at the top of the module (`BATCH` 4, `WATER` 2, `FOOD` 1, `BREW_SECS` 300). A batch brewing is not kept over a restart.

## 2. The dealer sells only what the Resistance sold him

The owner: "let's make it so the black market dealer doesn't sell alcohol unless the resistance is doing so."

- **Each bottle a player sells the black market adds one to its stock of that drink** (beer and moonshine: `bootleg` on their goods in `LCS.Black`), and each it sells takes one. **With none left, the drink is not on his list at all;** with some, the line says how many ("3 left"). Anyone selling counts, a citizen too (the bottle is in his stock all the same).
- **His pre-war vodka is no longer sold:** there is none left in the city (`gone` on `vodka_black`). He still buys a bottle of vodka for its old price, but never sells one. **The Union's own vodka for exemplary citizens at the Commissary is not touched.**
- The stock is kept with the state of the city (`bootleg` in the ledger's `data/livingcity/<map>_city.json`), written the moment it changes, so a restart or a map change keeps it.
- The quartermaster's window lists the same goods as the dealer's, so he too has drink only while there is some in this stock.

## 3. Selling to the dealer: the member's half

The owner: "The existing sidelines send a share" (skimmed machine parts and forged ration cards sold to the dealer), and the 50% cut.

- **A Resistance member selling the dealer moonshine, skimmed Union machine parts or forged ration cards has half of what he pays; the other half goes to the fund.** It is read from the item's flag **`resistanceSplit = true`** (`sh_livingcity_shop.lua`, read by `LC.DealerSplit` in `sv_livingcity_resistancemoney.lua`), so any item given the flag later is split the same way without touching the dealer's code. Half a credit is the fund's (a 5-credit item: 2 to the member, 3 to the fund).
- His window shows a member what they will have (the half), and his line after the sale says what they had.
- **A citizen selling him the same is paid in full** (their money is not the Resistance's). Nothing is split at the quartermaster (he is the Resistance's own).

## 4. The dealer's rent

The owner: "The dealer pays rent. The black market dealer gives the fund a cut for trading on rebel ground: more while the area is safe, nothing while the Combine holds it."

- **For every sale the dealer makes to a player while he stands on rebel ground, 20 per cent of the price goes to the fund;** 30 per cent while the place is safe (no unit within 1200 units, no lockdown); nothing while the Combine hold it (a sweep in that territory, or a unit within 400 units of him). Off rebel ground, nothing. On a map with no dealer, the black market in rebel territory pays the same for where the buyer stands. Nobody is paid for it; the quartermaster pays no rent.
- Constants: `RENT` 0.2, `RENT_SAFE` 0.3, `SAFE_REACH` 1200, `HELD_REACH` 400.

## 5. The paymaster

The owner: "The paymaster. A Union courier carrying the shift wages, run as an event like the supply convoy. Robbing him is a raid, and the credits go to the fund."

- **Now and then, by day, a Union paymaster** (a citizen in the Union's blue) walks the shift wages from a loading dock ("Point: loading dock"; the street if there is none) to where people are paid (Labor Assignment, else the Commissary terminal, else a workplace, the furthest of them), with **two Civil Protection units** beside him. About once in five hours of the city running (a one-in-300 chance each minute; the supply convoy comes about once in 280 minutes), never within 90 minutes of the last, never at night, in a curfew or a lockdown. He walks for at most ten minutes.
- **His satchel holds 80 to 200 credits.** Killed, he drops it (E on it); alive with none of his escort within 700 units, E on him and he hands it over, then runs.
- **Taken by one of ours: half to the fund, half shared equally among the Resistance's players who took part:** the one who took it, those on the job, and those who had a go at him or his escort, within 1500 units ("[Credits] +45 (your share)", as with the fund's other shares). **A citizen who takes it keeps the whole satchel;** the fund gets nothing.
- **The Combine answer it as they do a looted supply drop:** seen at it, the robber is wanted ("Looting Union supplies") and the units nearby go after them; the Resistance's strength in the ledger goes up by one. Killing his escort is what killing any unit is.
- **The Resistance's job while he walks: "Rob the paymaster"** (`res_paymaster`, `brings = true`): posted on their board when he sets out, its one step "A Union paymaster is walking the shift wages across the city with an escort: take his satchel.", its marker on him (or on the satchel he dropped). The board shows its pay: the job's own credits, up to half the satchel each, and "fund +40-100". It ends with him: robbed by one of the job, it is done; robbed by someone else or got through, it ends as out of time.
- Constants: `WAGES` 80 to 200, `ESCORT` 2, `ESCORT_REACH` 700, `MEAN_MINUTES` 300, `GAP_MINUTES` 90, `WALK_SECS` 600, `SATCHEL_SECS` 180.

## 6. The card table

The owner: "A back-room card game on rebel ground, with the house cut going to the fund."

- **A fixture**, "Fixture: card table" (point kind `cardtable`, entity `lc_cardtable`), for a back room on rebel ground. **Off rebel ground it does nothing.** Units, soldiers, the Administrator and the infested don't play.
- **E opens one small window, "High card":** your card and the house's, three bets (5, 10, 25), Deal, and the result ("You win" or "House wins"). **High card:** each draws one card from a fresh deck, the higher rank wins, **a tie is the house's.** The player wins 24 hands in 51; the house's edge is 3 in 51, about 5.9 per cent.
- **A lost bet goes to the fund; a win is paid out of the fund at even money.** The table takes no bet the fund could not pay out and still keep 50 credits (a bet it can't take is greyed out), so it rests while the fund is low. One hand every 4 seconds at most per player. Nothing goes in the chat.
- The server checks every hand asked for from the window: who (not a unit, alive), how near (160 units), how much (one of the three bets, the player able to pay it, the fund able to cover it), how often (4 seconds).

## What is new, for the core

New, in no core list: the point kinds `still` and `cardtable`, the entities `lc_still` and `lc_cardtable`, the job `res_paymaster`, the ledger field `bootleg`, the net messages `lc_cards` and `lc_cards_deal`, the item flag `resistanceSplit` (on `moonshine`, `union_goods`, `ration_forged`), the goods flags `bootleg` (beer, moonshine) and `gone` (`vodka_black`). No new item, setting, command or PData key.
