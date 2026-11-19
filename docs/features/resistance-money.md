# The Resistance's own money (19 November)

The owner, 19 November, wanted the Resistance to earn money the way real movements do ("mafia-esque tactics ... Making their own bootleg alcohol and selling it to the black market dealer"), chose five ways from a list, and added for all of them: "the resistance member doing the deed/act/work gets a maybe 50% cut for the brewing of moonshine or robbing the paymaster or for selling/smuggling combine gear, etc." And on logic: "please be logical ... why would anyone deliver things for free"; "killing headcrabs and bringing their corpses home does not magically produce credits; only raids, sweeps, etc would have a logical way for credits to be provided".

`sv_livingcity_resistancemoney.lua` (all five), `entities/lc_still.lua`, `entities/lc_cardtable.lua`, `cl_livingcity_cards.lua` (the card window); the dealer's buying and selling in `sv_livingcity_underground.lua`; the flags in `sh_livingcity_shop.lua`. Tests: `Nov19_ResistanceMoneyTests`, the client smoke test, the robot players (`res_paymaster`). Every credit into the fund is one line in the server's log with a short reason ("Moonshine x3 sold to the dealer (Kerr)", "The dealer's rent", "The paymaster's satchel", "The card table's cut").

Nothing is said about any of it beyond what was there: no notice, hint, chat line or announcement, except the still's one line and the paymaster job's posting (posted the way the supply drop's raid job is).

## 1. The still

The owner: "The still. Moonshine brewed at the camp or lab from water, bottles and ration food over time, then sold to the black market dealer."

- **A fixture**, "Fixture: Resistance still" in the editor (point kind `still`, entity `lc_still`, the sawmill boiler `models/props_forest/sawmill_boiler.mdl` since 19 November at the owner's ask; the older boiler only if a server lacks it), meant for a camp or beside the lab. Saved with the layout like any fixture.
- **A Resistance member presses E with the makings in their pockets:** a ration packet (or a short ration), 2 water (any bottle or can of water, untreated included: the still boils it) and an empty bottle for each bottle made, 4. They are taken, and it brews by itself for **5 minutes**. Nobody has to stay (house rule 9): it steams and hisses quietly while it works. **E when it is done takes the 4 bottles of moonshine** (any member may take them). Anyone else's E does nothing.
- Lacking something, one line: "You need a ration packet, 2 water and 8 empty bottles."
- **Moonshine is contraband**, as it always was: a unit's search takes it.
- The numbers are constants at the top of the module (`BATCH` 8, doubled on 19 November at the owner's word ("just increase the amount in a batch please by double"; an empty bottle for each), `WATER` 2, `FOOD` 1, `BREW_SECS` 300). A batch brewing is not kept over a restart.

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

## 6. The card table: a fundraiser

The owner: "A back-room card game on rebel ground, with the house cut going to the fund." The first one (18 November) played high card against the house and paid wins out of the fund; the owner, 19 November: "wait what, I thought this would be like a fundraiser card game where you play cards and you get like 70% of the winnings from the pot/pool and the rest goes into the resistance fund; the resistance fund should not be drained from this". So it is a pot game now, and **the table never pays anything out of the fund.**

- **A fixture**, "Fixture: card table" (point kind `cardtable`, entity `lc_cardtable`), for a back room on rebel ground. **Off rebel ground it does nothing.** Units, soldiers, the Administrator and the infested don't play.
- **Four seats. E on the table sits you down** and opens one small window, "High card". **Closing the window, or walking off (160 units from the table), stands you up**, as do dying or becoming a unit. With four players seated, E shows the table as it is without a seat.
- **Empty seats are filled by the Resistance's own people** (no models: plain names from the city's name list in the window), so a lone player has three to play against and two players have two. A player sitting down takes the seat of one of them; a player standing up gives it back. When the last player stands, they go and the table is empty.
- **The deck (19 November, the owner: "can you make the cards (images/graphics)? Would be funny if they could be themed to the gamemode and HL2"):** the window shows the four seats side by side, each card a picture from the Resistance's own hand-made deck, the name under it: 2 the can, 3 a ration packet (a sealed pouch with the Combine emblem), 4 a headcrab, 5 a manhack, 6 a barnacle (with a boot), 7 a scanner, 8 Civil Protection, 9 an antlion, 10 a strider, J a vortigaunt, Q the Administrator on her screen, K the Colonel, A the Free Man; a seat with no card shows the back (the lambda sprayed on a ration box). **Four suits, as layers** (the owner: "remove the lambda from the cards so they are all suite neutral ... one set of cards and 4 images: one for each suite"): a face is ink alone on nothing (`2.png` to `14.png`), and the card under it is its suit's (`suit1.png` the Resistance, `suit2.png` the Combine, `suit3.png` the Union, `suit4.png` the vortigaunts: the paper's tint, a line, the suit's mark under each rank and faint in the middle); the window lays the face over the suit. A suit decides nothing in either game: it is only which of the four cards of a rank it is. All eighteen pictures (with `back.png`; 256 x 356, about 250 KB together, made by `_dev/posters/cards.js` then `cards_shrink.py`) are in `materials/livingcity/cards/`, loose in the server's `garrysmod/` (`livingcity_content.zip`), sent to players at map start; **without them the cards are drawn plainly, as before**.
- **Two games (19 November, the owner: "can we have a few more simple card games"; of four offered they picked Twenty-one, with "Same pot as high card"):** whoever sat first picks the game between hands, with two buttons, "High card" and "Twenty-one" (the window's title is the game; everyone else reads it there). **Twenty-one:** Deal takes the stakes exactly as in high card (the same pot, the same 70 per cent, the same limit of hands an hour) and gives everyone two cards; you see your own, fanned, with what they are worth under your name (2 to 10 their number; the vortigaunt, the Administrator and the Colonel 10; the Free Man 11 or 1), and the others' face down. **Card** takes one, **Stay** ends your part, where Deal was; 21, over 21 or five cards ends it too. Everyone plays at once and has 20 seconds (a thin bar runs down; out of time you stay). The Resistance's own people take a card below 16. Then every hand is turned up: **the nearest to 21 without passing it takes 70 per cent of the pot (a tie splits it), the fund the rest; with everyone over 21 the fund takes the whole pot.** Standing up during a hand leaves your stake in it (the table emptied, the pot is the fund's); nobody sits down, and the stake and the game can't change, while a hand is on. Nothing in the chat.
- **The stake:** one for everyone at the table, 5, 10 or 25, picked by whoever sat first (three buttons, one they can't cover greyed out; they may change it between hands). If they stand, the player seated longest picks it. **It stays until the table is empty.** No hand before it is picked.
- **A hand:** any seated player presses Deal (one hand every 4 seconds at a table). Everyone seated puts the stake into the pot; a player who can't is stood up first, with nothing in the chat (their window says "Short of the stake"; nobody else is told). **The Resistance's own people put in 5 at most, whatever the stake** (their own money, from the city, as when the city's people buy things). One card each from a fresh deck; **the highest card takes 70 per cent of the pot, rounded down; the rest goes to the fund** ("The card table's cut" on the fund's record). **A tie splits the 70 per cent** among the tied, and what does not divide goes to the fund. What one of the city's people wins goes home with them.
- **No farming the fund: 20 hands a character in a real hour.** After the twentieth, Deal is greyed for them ("Out of hands this hour") until an hour has passed since the first of them; they may stay seated and sit out the others' hands, staking nothing. Counted per character and kept over a reconnect or a restart (PData `lc_cards_hour`: the character, when the hour began, the hands).
- **The window:** the four seats (a name each, yours lit; the card each had in the last hand; what the winner took, "+21", in the winner's colour; a chip by whoever dealt it), "Pot 30", the stake (the three buttons, or the number), Deal, and one line only when you can't: "Out of hands this hour" or "Short of the stake". Nothing goes in the chat.
- **What it comes to** (exact over every four cards from a deck; the tests check it). A lone player, against three of the city's people at 5:

  | Stake | Pot | Winner's take | Lone player, a hand on average | The fund, a hand on average (at most) | The fund in an hour from one lone player, on average (at most) |
  |---|---|---|---|---|---|
  | 5 | 20 | 14 | loses 1.50 | 6.01 (8) | 120 (160) |
  | 10 | 25 | 17 | loses 5.78 | 8.12 (10) | 162 (200) |
  | 25 | 40 | 28 | loses 18.00 | 12.00 (13) | 240 (260) |

  A player wins (or ties for) the pot 28 hands in 100. Of the fund's cut, the city's own money is at most 4.51 a hand (at 5; 2.34 at 10; at 25 the city's people win more than they put in), so at most about 90 an hour from one lone player. Four players at 25 make a pot of 100: 70 to the winner, 30 to the fund (32 at most), and each loses 7.50 a hand on average.
- The server decides everything asked for from the window: who (seated, alive, not a unit, on rebel ground), how near (160 units), the stake (one of the three, the player able to cover it), how often (4 seconds at a table) and the hour's hands. Constants: `STAKES` 5, 10, 25, `SEATS` 4, `THEIRS` 5, `WINNER` 70, `RATE` 4, `HOUR_HANDS` 20, `TABLE_REACH` 160.

## What is new, for the core

New, in no core list: the point kinds `still` and `cardtable`, the entities `lc_still` and `lc_cardtable`, the job `res_paymaster`, the ledger field `bootleg`, the net messages `lc_cards` and `lc_cards_deal` (their shape changed with the pot game, and again with Twenty-one and the suits, 19 November), the PData key `lc_cards_hour` (the card table's hands this hour), the item flag `resistanceSplit` (on `moonshine`, `union_goods`, `ration_forged`), the goods flags `bootleg` (beer, moonshine) and `gone` (`vodka_black`). No new item, setting or command.
