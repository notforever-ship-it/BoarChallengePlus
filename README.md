# Boar Challenge +

For a character that levels on boars alone, on the 1.12 client (Turtle WoW, Ravencraft, OctoWoW). A
wide panel on screen with everything about the run, every number changeable, every row optional,
and advice on where the next boars are.

Type `/boar` to show or hide the panel. That is remembered per character, so it can be on for your
boar character and off for the rest.

## The panel

```
Boar Challenge +                                                    Stealthboar
135 boars to level 19   about 5h 39m at this pace
[====== Level 18   1,486 / 19,400 XP   8% =====================================]
Boars killed      1,002  +2 this session        XP per hour       3,165  last 30 min 3,165
Boars per hour       24  last 30 min 24         XP per boar         133
Played          14h 30m  this session 5m        Deaths                0  100% of XP is boar
Here   Goretusk 14-15 green, Great Goretusk 16-17 yellow
Next   Great Goretusk 16-17 in Redridge Mountains, Three Corners (30 spawns)
```

- The headline is **boars to the next level**, with the time that takes at your pace, then an XP bar.
- **Rows** you can switch on or off (right-click the panel, or `/boar show <row>`): boars killed,
  XP per hour, boars per hour, XP per boar, played, deaths, boars this level, what the last level
  took, rested XP (and how many boars it covers at double XP), best XP per hour, XP this session,
  here, next. The panel closes up around the rows you keep.
- **Here** is the boars in the zone you stand in, coloured by level the way the game colours them.
  Grey means no XP: time to move on.
- **Next** is the best zone for your level that is not this one, by one rule: boars at your level or
  a few below, with the most spawns. Dungeon boars and the other faction's starting lands count for
  less. `/boar where` prints the top four with map positions, `/boar route` every boar low to high.

## Where the boar data comes from

With **pfQuest** installed (pfQuest-turtle, pfQuest-octo), every boar's level and spawn points come
from its database, so a server's own zones are in. Without it, a list taken from that database on
2026-09-25 (vanilla plus Turtle WoW) is built in; OctoWoW's database shows the same boars at the
same levels.

The road, roughly: Teldrassil / Dun Morogh / Elwynn (1-10), Westfall's Goretusks and Loch Modan's
Mountain Boars (10-17), Redridge's Great Goretusks (16-17, still XP until 23), Hillsbrad's Forest
Boars (23-27), Northwind's Goldbristle Boars (26-30), Grim Reaches' Stonehide Boars (32-38) and
Arathi's Hightusk Boars (33-34), then Blasted Lands' Ashmane Boars (48-49) and Helboars (52-53).
Razorfen Kraul (24-28) and Razorfen Downs (34-37) have boars too, in a dungeon.

## What counts

- A **kill** is "You have slain X!" in the combat log, or "X dies, you gain N experience.", or "X
  dies." while X is your target (your pet got the blow).
- A **boar** is anything the game calls a Boar when you target it (remembered by name from then on),
  anything with boar, goretusk, agam'ar or swine in its name, and any name you add with `/boar add`.
- **XP per hour** and **boars per hour** count this session; the last 30 minutes are in the notes.
  **Next level in** uses the last 30 minutes once you have played 5 minutes, else the session.
- **Played** counts while you are logged in and not AFK.
- Level-ups are written down with the boars and time they took: `/boar levels` lists them.

## Changing the numbers

Right-click the panel, or `/boar edit`: boars killed, deaths, time played (like `14h30m`), XP from
boars, XP from other things. Or from chat: `/boar set kills 1000`, `/boar set played 14h30m`.

Every character starts at 0, yours and anyone else's, except Stealthboar, who had 1000 boars before
this addon existed and starts there. If the old Boaring Challenge addon's data is still on the
account, chat says once what it counted and the command to take it over.

## Commands

| Command | What it does |
|---|---|
| `/boar` | Show or hide the panel, remembered for this character only |
| `/boar edit` | The numbers and the row checkboxes, in a window |
| `/boar where` | Boars in this zone, and the best zones for your level |
| `/boar route` | Every boar known, low to high, with zone and map position |
| `/boar show <row>` | One panel row on or off; `/boar show` lists the rows |
| `/boar set kills 1000` | Set one number: `kills`, `deaths`, `played`, `xp` (from boars), `otherxp` |
| `/boar add <name>` | Count this creature as a boar (no name: your target) |
| `/boar remove <name>` | Stop counting it |
| `/boar list` | Boars killed, by kind |
| `/boar levels` | When each level came, with the boars and time it took |
| `/boar session` | Start the session counters again |
| `/boar lock` | Lock or unlock the panel for dragging (Shift-drag works any time) |
| `/boar reset` | Everything for this character back to zero (asks twice) |

## Installing

Copy the `BoarChallengePlus` folder into `Interface\AddOns\`, or run `node tools/install.js` from
this folder. `node tools/check-lua.js .` checks the code against Lua 5.0 and the 1.12 API.
