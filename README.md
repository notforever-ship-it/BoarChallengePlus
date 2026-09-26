# Boar Challenge +

For a character that levels on boars alone, on the 1.12 client (Turtle WoW, Ravencraft, OctoWoW). A
panel on screen with the numbers that matter for the run, every one of them optional, and a road of
boar zones from your level to 60: stay here until level X, then go there.

Type `/boar` to show or hide the panel. That is remembered per character, so it can be on for your
boar character and off for the rest.

## The panel

```
Boar Challenge +                                                    Stealthboar
59 boars to level 20                                       1,127 boars killed
[====== Level 19    7,366 / 21,300 XP    35%    +17,238 rested ====|~~~~~~~~~]
Boars per hour           90        Boars this session           30     (orange)
XP per hour          21,402        XP per boar                 238     (purple)
Time to level           39m        Time played             17h 00m     (blue)
Here   Great Goretusk 16-17, Goretusk 14-15, Young Goretusk 12-13
Now    Stay here until level 22, about 540 boars (or Redridge Mountains)
Next   At 22: Hillsbrad Foothills, Forest Boar 23-25
```

- The big line is **boars to the next level** on the left and **boars killed** on the right.
- The **XP bar** shows your rested XP as a blue stretch past your XP, like the game's own bar, and
  the rested amount on the bar.
- **Numbers** come in colour groups, each starting its own line: boars in orange, XP in purple, time
  in blue, rested in green, deaths in red. Each number has its label on the left of its half of the
  line and the number on the right, so nothing runs into anything else.
- **Here** is the boars in the zone you stand in, biggest first, coloured the way the game colours
  them for you. Grey gives no XP.
- **Now** says stay here until a level, with about how many boars that is, or go somewhere better.
  A zone with boars just as good is named too.
- **Next** is the stop after that and the level to go at. **Later** (off at first) the ones after.
- Hover the panel for the whole road with boar counts.

## Everything can be switched off

Right-click the panel for the settings window. Every box works as soon as you click it:

- **Top**: title, character name, boars to level, boars killed (big), XP bar, numbers on the bar,
  rested on the bar, background.
- **Advice**: here, now, next, later.
- **Numbers**: boars killed, boars per hour, boars this session, boars this level, boars per hour in
  the last 30 minutes, boars the last level took; XP per hour, XP per boar, XP per hour in the last
  30 minutes, XP to level, XP this session, best XP per hour, how much of your XP came from boars;
  time to level, time played, played this session, time the last level took; rested XP, boars on
  rested; deaths.
- **Size**: smaller and bigger buttons (or `/boar scale 1.2`), and a lock so it only moves with Shift.
- **Defaults** puts the panel back to how it starts.

`/boar show <thing>` switches one thing from chat; `/boar show` lists their names.

## The road

The road is worked out with the game's own XP rules. For every level to 60 it asks what each zone's
boars give you (boars 3 or 4 levels above you count half, 5 above not at all, grey ones nothing) and
how many there are. You stay where you are until a zone with bigger boars is clearly better, so it
never sends you across the world for the same boars. From Westfall at level 18 it comes out as:

| Levels | Where | Boars | Or |
|---|---|---|---|
| 18 to 22 | Westfall | Great Goretusk 16-17, Goretusk 14-15 | Redridge Mountains, Loch Modan |
| 22 to 27 | Hillsbrad Foothills | Forest Boar 23-25, Elder Forest Boar 26-27 | |
| 27 to 32 | Northwind | Young, Burly and plain Goldbristle Boars 26-30 | |
| 32 to 46 | Grim Reaches | Stonehide Boar 32-34, Elder Stonehide Boar 37-38 | Arathi Highlands |
| 46 to 58 | Blasted Lands | Ashmane Boar 48-49, Helboar 52-53 | |
| 58 to 60 | Eastern Plaguelands | Plagued Swine 60 | |

The boar counts are estimates from the XP rules; the rested XP you have now comes off the first stop.
Dungeon boars count for less, and so do the other faction's lands. `/boar route` prints the road with
map positions, `/boar route all` every boar known.

## Where the boar data comes from

With **pfQuest** installed (pfQuest-turtle, pfQuest-octo), every boar's level and spawn points come
from its database, so a server's own zones are in. Without it, a list taken from that database on
2026-09-25 (vanilla plus Turtle WoW) is built in; OctoWoW's database shows the same boars at the
same levels. pfQuest lists a creature on every map its spawns fall on, so the boars at the edge of
one zone also turn up at the edge of the next (Loch Modan's Mountain Boars on the Grim Reaches map);
those are kept in the zone they are really in.

## What counts

- A **kill** is "You have slain X!" in the combat log, or "X dies, you gain N experience.", or "X
  dies." while X is your target (your pet got the blow).
- A **boar** is anything the game calls a Boar when you target it (remembered by name from then on),
  anything with boar, goretusk or agam'ar in its name, and any name you add with `/boar add`.
- **Boars to level** starts from what a boar gives you without the rested bonus (read from the combat
  log): this session's boars, or before the first kill of a session the last boar you killed, which
  is remembered between logins and scaled if you have levelled since. Then it counts your rested XP:
  those boars give double. So it is right the moment you log in.
- **XP per hour** and **boars per hour** count this session. **Time to level** uses the last 30
  minutes once you have played 5 minutes, else the session, and before that the pace you left with
  last time.
- **Boars on rested** is the rested pool over what a boar gives without the bonus.
- **Played** counts while you are logged in and not AFK.
- Level-ups are written down with the boars and time they took: `/boar levels` lists them.

## Changing the numbers

Right-click the panel, or `/boar edit`: boars killed, deaths, time played (like `14h30m`), XP from
boars, XP from other things. Only boxes you change are saved. Or from chat: `/boar set kills 1000`,
`/boar set played 14h30m`.

Every character starts at 0, yours and anyone else's, except Stealthboar, who had 1000 boars before
this addon existed and starts there. If the old Boaring Challenge addon's data is still on the
account, chat says once what it counted and the command to take it over.

## Commands

| Command | What it does |
|---|---|
| `/boar` | Show or hide the panel, remembered for this character only |
| `/boar edit` | Settings: your numbers, what the panel shows, its size |
| `/boar where` | Boars here, and now, next and later |
| `/boar route` | Your road to 60: every stop, its boars, map position and boar count |
| `/boar route all` | Every boar known, low to high |
| `/boar show <thing>` | One thing on the panel on or off; `/boar show` lists them |
| `/boar scale 1.2` | The panel's size, 0.6 to 2 |
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
