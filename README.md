# Boar Challenge +

For a character that levels on boars alone, on the 1.12 client (Turtle WoW, Ravencraft, OctoWoW). A
small panel on screen with everything about the run, and every number can be changed.

Type `/boar` to show or hide the panel.

## The panel

```
Boar Challenge +  Stealthboar
Boars 1,024  (37 this session)
Level 17 43%  2,400 / 5,600 XP
XP per hour 2,150  (last 30 min 2,400)
Boars per hour 48  (last 30 min 52)
XP per boar 45  about 71 more to level 18
Next level in ~1h 30m  at this pace
Played 14h 30m  this session 1h 12m
Deaths 2  98% of your XP is boar
```

- **Boars** is every boar this character has killed. A kill is "You have slain X!" in the combat
  log, or "X dies, you gain N experience.", or "X dies." while X is your target (your pet got it).
- **A boar** is anything the game calls a Boar when you target it (remembered by name from then
  on), anything with boar or goretusk in its name, and any name you add with `/boar add`.
- **XP per hour** and **boars per hour** count this session; the last 30 minutes are in brackets.
  **Next level in** uses the last 30 minutes once you have played 5 minutes, else the session.
- **Played** counts while you are logged in and not AFK.
- **% of your XP is boar** compares XP from boars with XP from everything else since counting began.
- Level-ups are written down with the boars and time they took: `/boar levels` lists them.

## Changing the numbers

Right-click the panel, or `/boar edit`: boars killed, deaths, time played (like `14h30m`), XP from
boars, XP from other things. Or from chat: `/boar set kills 1000`, `/boar set played 14h30m`.

Every character starts at 0, yours and anyone else's, except Stealthboar, who had 1000 boars before
this addon existed and starts there. If the old Boaring Challenge addon's data is
still on the account, chat says once what it counted and the command to take it over
(`/boar set kills 993`), so the number only lands on the character you choose.

## Commands

| Command | What it does |
|---|---|
| `/boar` | Show or hide the panel |
| `/boar edit` | Change the numbers in a window |
| `/boar set kills 1000` | Set one number: `kills`, `deaths`, `played`, `xp` (from boars), `otherxp` |
| `/boar add <name>` | Count this creature as a boar (no name: your target) |
| `/boar remove <name>` | Stop counting it |
| `/boar list` | Boars killed, by kind |
| `/boar levels` | When each level came, with the boars and time it took |
| `/boar session` | Start the session counters again |
| `/boar lock` | Lock or unlock the panel for dragging (Shift-drag works any time) |
| `/boar reset` | Everything for this character back to zero (asks twice) |

## Installing

Copy the `BoarChallengePlus` folder into `Interface\AddOns\`, or run `node tools/install.js` from this
folder. `node tools/check-lua.js .` checks the code against Lua 5.0 and the 1.12 API.
