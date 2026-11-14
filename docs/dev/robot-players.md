# The robot players

Asked for by the owner on 14 November 2026: they have little time to play, so a fake player does every job from start to payout, and each must finish, pay and never stick.

    python3 _dev/robots.py            the table, and what stuck, failed or errored (about a minute and a half)
    python3 _dev/robots.py --quiet    only the summary and the problems

## What a robot does

A robot (`_dev/robots.lua`) is a fake player in the test harness. It takes a job the real way (`LC.AcceptPosting`) and does each step as a player would: walks to the place, presses E on the thing or the person, makes the arrest (`LC.ArrestNPC`), holds E on what is to be searched or worked on by hand, kills what a counter asks for, walks an escort home, answers a choice (the first one offered, with a good roll). It never reaches into the job to move it on.

A job passes when it finishes and pays. Otherwise it is one of:

- **STUCK**: the robot did its part for a minute and a half and nothing was counted.
- **FAILED**: the game called the job off (the line says why).
- **TIMED OUT**, **ERROR**: as they say.
- **robot can't**: a step the robot has not been taught. Never counted as done.
- **not offered**, **not built**: the job's own conditions are not met in the robot's city (the city the first 505 lines of `tests.lua` build), or the city has nothing to build it from.
- **KNOWN**: it does not finish, the reason is written in `TODO.md` and waits on the owner (the `KNOWN` table at the top of `robots.lua`).

For each job the table also gives the seconds it took, the XP paid, and how many chat lines and notices the player was sent (house rule 10).

## Both ways round

Every job is done twice, the second time with the game's hooks answering in the other order (`_HOOK_REVERSE` in `_dev/gmod_stub.lua`). In the game, when two pieces of code both listen for the same key press, which hears it first is not ours to choose, and the first to answer wins. A job that goes differently the second time depends on that order: it works on one server and is dead on another. The first run found five (below).

## What is covered (14 November 2026)

135 jobs: every job on the boards for each side it is offered to (85), every part of every story chain, and every kind of shift of the twelve Union jobs. 84 finish and pay, both ways round.

Not yet: the 36 jobs that need a situation in the city (a supply drop, a hijacked screen, a prison break, a sweep or a raid under way, night, a special role), dreams, endings, and the job games themselves (a game inside a job is ended the way an admin's test ends it; the games have their own tests). Seven steps the robot cannot do yet: healing and preaching with The Blessing, looting a supply drop, the mole hunt's loyalty test, the hoover on a nest, weedkiller on weeds, patching a wound, bringing headcrab meat to the crate.

## What the first runs found

1. **Five "hold E on it" steps depended on which code heard E first** (fixed the same day, with the owner's yes): posting flyers (`res_propaganda`), patching the leak (`cit_pipe`), counting the ration packs and scrubbing graffiti and emptying bins (Union shifts). The things those steps put down carry the job's mark, and the older hook for job items (`LivingCityQuestItems`, sv_livingcity_quests.lua) swallowed the key press whenever it ran before the search hook (`LivingCityQuestSearch`). It now leaves a thing that is being searched to the search hook.
2. **The Union kitchen shift "The counter"** waits at the counter until three citizens have been handed rations. In the robot's city nobody came in ten minutes and the shift failed. `TODO.md`.
3. **The Man Inside, part 2** was called off at once in one run ("the job's target couldn't be found"). `TODO.md`.
4. The fake game ran hooks and timers in a random order from one run to the next, which is why a job (or a test) could pass one time and stick the next. They now run in the order they were made.
