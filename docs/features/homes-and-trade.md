# Homes, trade and the written word

**Apartments.** Tag a door "Door: apartment people can rent" with the editor. Look at it and it says who holds it, or that it is available and what it costs. **No commands needed:** with your hands out (nothing in them), right click at a free door and a yes or no asks whether to rent it; once it is yours, right click locks and unlocks it. The commands still work: look at it and `!rent`: `lc_rent_price` credits (50) for `lc_rent_hours` (3) hours of real time; `!rent` again extends it, up to a day ahead. A double door is rented together. **Rent-free** (the owner: loyalty should pay): Civil Protection units (`lc_free_rent_cp` 1) and citizens with Civil Standing `lc_free_rent_standing` (200) or more take their apartment at no charge. It's locked to everyone but you and whoever you `!givekey <name>` (`!takekey` to take it back). **Locked is locked, for you too:** pressing E on your own locked door just rattles the handle; unlock it first (right click it with your hands out, or `!unlock`). `!lock` and `!unlock` at the door, `!apartment` for where it is and how long is left, `!unrent` to move out. Units force their way in (E, three seconds). One each (`lc_rent_max`). Rentals are kept across restarts (`<map>_rentals.json`); when the rent runs out the apartment is free again.

**Trade.** A **CWU business license** (Commissary, Civil Standing 50) lets you set down a **market stall** (Commissary) and sell from it. Look at your stall and open your pockets: Sell puts one of something on it at the price you name, Price changes it, Take takes it back. Customers press E on the stall and buy; the money waits in the till until you collect it. An officer can revoke a license from the records terminal: it's taken, and the trader's stalls close until they have a new one. Units can search a stall like a crate. One stall each (`lc_stalls_per_person`), `lc_stall_kg` 30.

**Notes and posters.** Paper (Commissary, or bins): Write from your pockets. Leave it on the ground as a note, put it up on the wall you're looking at as a poster, or keep it (up to `lc_notes_kept`, 8; your pockets list them). Sign it or don't. Anyone presses E on a note or poster to read it and take it. Units, and whoever put it up, tear posters down. They stay up `lc_poster_hours` (12), across restarts; three each at a time (`lc_posters_per_person`).

**Letters.** A note you're carrying can be sent as a letter: read it from your pockets and **Send as a letter**, to anyone the city knows (who's here first, then whoever was here most recently). Hand it in at the **post office** (the Courier's workplace; on a map without one, anywhere). After `lc_mail_minutes` (4) of sorting it goes out for delivery: a **Courier** carries it to the recipient's housing block (a player Courier gets "The real mail" shift, paid for each letter; the city's own couriers carry it too), and it turns up in their pockets with a note in chat. If nobody takes it, the Union's van does, eventually; if they aren't in the city, it waits for them. Signed or not, **the post office knows who posted it**: while a letter is waiting there, **Civil Protection can read the mail** (actions menu > Civil Protection > Read the mail, at the post office), see who wrote what to whom, and **confiscate** any of it. The sender never knows.

**The Administrator's broadcasts.** The City Administrator (or an admin, or Civil Protection from Divisional Leader up) speaks to the whole city: `!broadcast <text>`. It crosses everyone's screen, goes into chat, and stays on every **city screen** (editor: "Fixture: city screen") until the next one.

**The law.** `!laws` shows the city's laws, and so does any **law board** (editor: "Fixture: law board"; press E). The Administrator and admins write them, from that screen or with `!addlaw <text>`, `!setlaw <n> <text>`, `!dellaw <n>`. They're kept in `garrysmod/data/livingcity/laws.json`, the same on every map.

## Things other people can see (the owner, 10 November: citizen goals)

Something to save for, and to be seen with. All from the Union Commissary, citizens only:
- **Fine clothes** (Civil Standing 150, 120 credits): use them from your pockets (F3) to put them on: you wear the better-dressed citizen clothes (the same face, a better coat) and **"Well dressed"** shows with your title for everyone. Use them again to take them off; they come off when you respawn or a job puts you in its own clothes.
- **Home decor**: a potted cactus (standing 25, 20 credits), a desk lamp (25, 25), a picture frame (50, 30), an armchair (50, 35, a large thing to carry). Use one from your pockets while you're in your own block and it's set down where you're looking. It stays, across restarts, for anyone who comes by to see. E on your own piece takes it back; nobody else can. At most `lc_decor_max` (6) each.
- **A radio set** (standing 75, 60 credits): set down like decor. E on it (anyone) plays music; again stops it. Its owner crouches and presses E to take it back.
- **A pet bird** (standing 100, 80 credits): a tame pigeon. Use it from your pockets and it rides on your right shoulder for everyone to see; again and it hops back into your coat. Sold or lost, it's gone (where it sits: `lc_petbird_pos`).
Decor is kept in `data/livingcity/<map>_decor.json`.

## Households (the owner, 10 November: roommates, family, a shared stash)

A citizen (or a Resistance member: on paper, a citizen) can take others into their household: **F1, looking at them, "Invite (name) into my household"** (face to face); they accept on **F2 > Me (More) > My household** within two minutes (or decline). Members of a household:
- **live in the head's block** (moved there when they join)
- **share their storage crates and lockers**: each can open the others' (stalls stay their owner's)
- **get keys to the head's apartment**, if they rent one
- **know each other by name**
The household is called after the head's surname ("the Vornholt household"); the head can rename it and send someone away (F2 > Me (More) > My household). Anyone can leave. A household of one is no household; when someone's life ends they leave it. Up to `lc_household_max` (6) people, each character in one at most. Shown in Where I stand. Kept in `data/livingcity/households.json`. `lc_households` 0 turns it off.

## A business of your own (the owner, 10 November: hiring other players, crafting worth selling)

- **Hand-made goods**, anyone can make (F3, crafting): a **rag doll** (3 rags), a **tin toy** (3 scrap), a **patched coat** (4 rags and a scrap). They're for selling.
- **The city's own people buy them**: every `lc_stall_customers_minutes` (3) a citizen walking near an open stall buys one hand-made thing from it, if it's priced at no more than half again what it's worth (a rag doll about 18, a tin toy 20, a patched coat 32). The money goes in the till, like any sale; the owner is told.
- **Hiring**: a stall owner can offer another citizen a job (F1, looking at them, "Offer (name) a job at my stall"); they accept on F2 > Me (More) > My household and stall business > My stall business. A worker can open their employer's stalls and stock them; the till stays the owner's. Every `lc_wage_minutes` (10) a worker who's been at one of the stalls is paid `lc_wage` (10) credits from the till, else from the owner's pocket if they're about, else not at all (and told so). The owner can let a worker go and a worker can quit, on the same page.

