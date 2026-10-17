# Boar Challenge +

For a character that levels on boars alone, on the 1.12 client (Turtle WoW, Ravencraft, OctoWoW).

- A panel with the numbers that matter for the run.
- Every number can be switched off.
- A road of boar zones from your level to 60.

## Start

- Type `/boar` to show or hide the panel.
- It is remembered per character.
- Right-click the panel for settings.
- Hover the panel for your whole road.
- Shift-drag to move it.

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

- **Big line**: boars to next level (left), boars killed (right).
- **XP bar**: rested XP shows in blue, with the amount.
- **Colours**: boars orange, XP purple, time blue, rested green, deaths red.
- **Here**: boars in this zone, biggest first. Grey gives no XP.
- **Now**: stay here until a level, or go somewhere better.
- **Next**: the next stop and the level to go.
- **Later**: the stops after that (off at first).

## Settings

- Right-click the panel, or `/boar edit`.
- Every box works as soon as you click it.
- **Top**: title, name, boars to level, boars killed, XP bar, bar numbers, rested, background.
- **Advice**: here, now, next, later.
- **Boars**: killed, per hour, this session, this level, last 30 min, last level, to 60.
- **XP**: per hour, per boar, last 30 min, to level, this session, best per hour.
- **Time**: to level, played, this session, last level.
- **Other**: rested XP, boars on rested, deaths.
- **Size**: smaller and bigger buttons, or `/boar scale 1.2`.
- **Lock**: then it only moves with Shift.
- **Defaults**: panel back to how it starts.

## Your numbers

- Settings window: boars killed, deaths, time played (like `14h30m`), XP from boars, other XP.
- Only boxes you change are saved.
- Or from chat: `/boar set kills 1000`, `/boar set played 14h30m`.
- Every character starts at 0.
- Stealthboar starts at 1000 (boars from before this addon).
- Old Boaring Challenge data: chat says once what it counted, and how to take it over.

## The road

- Worked out with the game's own XP rules.
- Boars 3 or 4 levels above you count half, 5 above not at all.
- You stay put until a zone is clearly better.
- Boar counts are estimates. Rested XP comes off the first stop.
- Dungeon boars and the other faction's lands count for less.

From Westfall at level 18:

| Levels | Where | Boars | Or |
|---|---|---|---|
| 18 to 22 | Westfall | Great Goretusk 16-17, Goretusk 14-15 | Redridge Mountains, Loch Modan |
| 22 to 27 | Hillsbrad Foothills | Forest Boar 23-25, Elder Forest Boar 26-27 | |
| 27 to 32 | Northwind | Young, Burly and plain Goldbristle Boars 26-30 | |
| 32 to 46 | Grim Reaches | Stonehide Boar 32-34, Elder Stonehide Boar 37-38 | Arathi Highlands |
| 46 to 58 | Blasted Lands | Ashmane Boar 48-49, Helboar 52-53 | |
| 58 to 60 | Eastern Plaguelands | Plagued Swine 60 | |

## Boar data

- With **pfQuest** (pfQuest-turtle, pfQuest-octo): boars come from its database, server zones included.
- Without it: a built-in list from that database (2026-09-25, vanilla plus Turtle WoW).
- OctoWoW shows the same boars at the same levels.
- Boars on a zone's edge are kept in the zone they are really in.

## What counts

- **Kill**: "You have slain X!", "X dies, you gain N experience.", or "X dies." on your target (pet kills).
- **Boar**: anything the game calls a Boar when you target it.
- Also any name with boar, goretusk or agam'ar, and names you add with `/boar add`.
- **Boars to level**: uses what a boar gives without rested. Rested boars count double.
- **Boars to 60**: every stop of the road added up, by the game's XP rules. A rough guide.
- It uses your last boar before the first kill of a session, so it is right at login.
- **Per hour**: this session.
- **Time to level**: last 30 minutes (after 5 minutes played), else the session, else last time's pace.
- **Boars on rested**: rested pool over what a boar gives.
- **Played**: counts while logged in and not AFK.
- **Levels**: each level-up is saved with its boars and time. See `/boar levels`.

## Commands

| Command | What it does |
|---|---|
| `/boar` | Show or hide the panel (per character) |
| `/boar edit` | Settings: numbers, what shows, size |
| `/boar where` | Boars here, now, next and later |
| `/boar route` | Road to 60: stops, boars, map positions, boar counts |
| `/boar route all` | Every boar known, low to high |
| `/boar show <thing>` | One thing on or off; `/boar show` lists them |
| `/boar scale 1.2` | Panel size, 0.6 to 2 |
| `/boar set kills 1000` | Set `kills`, `deaths`, `played`, `xp` (boars) or `otherxp` |
| `/boar add <name>` | Count it as a boar (no name: your target) |
| `/boar remove <name>` | Stop counting it |
| `/boar list` | Boars killed, by kind |
| `/boar levels` | Each level with its boars and time |
| `/boar session` | Session counters start again |
| `/boar lock` | Lock or unlock the panel (Shift-drag always works) |
| `/boar reset` | This character back to zero (asks twice) |
| `/boar help` | List the commands |

## Install

- Copy the `BoarChallengePlus` folder into `Interface\AddOns\`, or update through your launcher.
- Or run `node tools/install.js` from this folder.
- `node tools/check-lua.js .` checks the code (Lua 5.0, 1.12 API).
