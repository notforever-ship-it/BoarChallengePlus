-- Boar Challenge +: for a character that levels on boars alone. Counts every boar you kill and the XP
-- you get, keeps your time, and works out XP and boars per hour and how long the next level will take.
-- Everything is saved per character; every number can be changed with /boar set or the edit window.
--
-- A kill is "You have slain X!" in the combat log, or "X dies, you gain N experience.", or "X dies."
-- while X is your target (your pet got the blow). A boar is anything the game calls a Boar when you
-- target it (remembered by name from then on), anything with boar or goretusk in its name, and any
-- name you add with /boar add.

BoarChallengePlus = {}
local BC = BoarChallengePlus
BC.VERSION = "1.5.0"

local GOLD, GREY, WHITE, RED, GREEN, END = "|cffffd100", "|cff9d9d9d", "|cffffffff", "|cffff4040", "|cff40ff40", "|r"
BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END = GOLD, GREY, WHITE, RED, GREEN, END

local NAME_WORDS = { "boar", "goretusk", "agam'ar" }   -- boars whose names say so, or nearly
local WINDOW = 1800                                    -- seconds: the "last 30 min" rate
local DOUBLE = 1.5                                     -- seconds: the same death seen twice is one kill

local DEFAULTS = { locked = true, scale = 1 }
local OPTIONS = { "levelUp", "milestones", "records", "goal", "deathNotes", "streaks" }   -- the message switches, on at first

BC.session = { startedAt = 0, kills = 0, xp = 0, boarXP = 0, boarBase = 0, played = 0, deaths = 0 }
local recent = {}        -- { at, xp, kill }: the last hour, for the "last 30 min" rate
local lastKill = {}      -- [name] = GetTime() of the last counted kill

function BC.Print(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffd9a066Boar Challenge +:|r " .. msg) end
end

function BC.Trim(s)
  if type(s) ~= "string" then return "" end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

-- 1234567 -> "1,234,567"
function BC.Num(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  local s = tostring(n)
  local out = ""
  while string.len(s) > 3 do
    out = "," .. string.sub(s, -3) .. out
    s = string.sub(s, 1, -4)
  end
  return s .. out
end

-- 5025 -> "1h 24m", 300 -> "5m", 90000 -> "25h 00m"
function BC.Time(seconds)
  seconds = math.floor((tonumber(seconds) or 0) + 0.5)
  if seconds < 0 then seconds = 0 end
  local h = math.floor(seconds / 3600)
  local m = math.floor(math.mod(seconds, 3600) / 60)
  if h == 0 then return m .. "m" end
  if m < 10 then return h .. "h 0" .. m .. "m" end
  return h .. "h " .. m .. "m"
end

------------------------------------------------------------------------------------------------------
-- Saved data
------------------------------------------------------------------------------------------------------

local function InitDB()
  if type(BoarChallengePlusDB) ~= "table" then BoarChallengePlusDB = {} end
  for k, v in pairs(DEFAULTS) do
    if BoarChallengePlusDB[k] == nil then BoarChallengePlusDB[k] = v end
  end
  BC.db = BoarChallengePlusDB

  if type(BoarChallengePlusCharDB) ~= "table" then BoarChallengePlusCharDB = {} end
  local c = BoarChallengePlusCharDB
  if type(c.kills) ~= "number" then c.kills = 0 end
  if type(c.boarXP) ~= "number" then c.boarXP = 0 end
  if type(c.otherXP) ~= "number" then c.otherXP = 0 end
  if type(c.deaths) ~= "number" then c.deaths = 0 end
  if type(c.played) ~= "number" then c.played = 0 end
  if type(c.xpKills) ~= "number" then
    -- boars whose XP the addon saw: everything but the 1000 Stealthboar started with
    c.xpKills = c.kills - (c.seeded and 1000 or 0)
    if c.xpKills < 0 then c.xpKills = 0 end
  end
  if c.shown == nil then c.shown = true end            -- the panel on or off, for this character only
  if type(c.show) ~= "table" then c.show = {} end
  if c.showVersion ~= 2 then
    -- 1.3 had rows with notes in them; 1.4 has one switch per thing. Keep what was switched on.
    local old = c.show
    c.show = {}
    local same = { "xph", "bph", "xpb", "played", "deaths", "here", "rested", "best", "sessionXP", "thisLevel" }
    for i = 1, table.getn(same) do
      if old[same[i]] ~= nil then c.show[same[i]] = old[same[i]] end
    end
    if old.kills ~= nil then c.show.sessionKills = old.kills end
    if old.played ~= nil then c.show.sessionPlayed = old.played end
    if old.rested ~= nil then c.show.restedBoars = old.rested end
    if old.lastLevel ~= nil then
      c.show.lastBoars = old.lastLevel
      c.show.lastTime = old.lastLevel
    end
    if old.next ~= nil then
      c.show.now = old.next
      c.show.next = old.next
    end
    c.showVersion = 2
  end
  for i = 1, table.getn(BC.ITEMS or {}) do
    local it = BC.ITEMS[i]
    if c.show[it.key] == nil then c.show[it.key] = it.on end
  end
  if type(c.byName) ~= "table" then c.byName = {} end
  if type(c.byLevel) ~= "table" then c.byLevel = {} end
  if type(c.levels) ~= "table" then c.levels = {} end
  if type(c.names) ~= "table" then c.names = {} end        -- names the game called Boar when targeted
  if type(c.extra) ~= "table" then c.extra = {} end        -- names you added with /boar add
  if not c.startedAt then c.startedAt = time() end
  if not c.startLevel then c.startLevel = UnitLevel("player") end
  -- 1.5: the messages, records, boars per day and death notes
  if type(c.opt) ~= "table" then c.opt = {} end
  if c.opt.lines ~= "off" and c.opt.lines ~= "rare" and c.opt.lines ~= "normal" then c.opt.lines = "rare" end
  for i = 1, table.getn(OPTIONS) do
    if type(c.opt[OPTIONS[i]]) ~= "boolean" then c.opt[OPTIONS[i]] = true end
  end
  if type(c.records) ~= "table" then c.records = {} end
  if type(c.records.pace) ~= "table" then c.records.pace = {} end      -- { bph, level, at }: best level pace
  c.records.level = nil                                                -- 1.5.0 test builds: the fastest level
  if type(c.records.hour) ~= "table" then c.records.hour = {} end      -- { n, at }: most boars in 60 minutes
  if type(c.records.day) ~= "table" then c.records.day = {} end        -- { n, day }: most boars in a day
  if type(c.records.streak) ~= "table" then c.records.streak = {} end  -- { n, at }: most boars in a row
  if type(c.streak) ~= "table" then c.streak = {} end                  -- { n, last, base }: the streak now
  if type(c.streak.n) ~= "number" then c.streak.n = 0 end
  if type(c.streak.last) ~= "number" then c.streak.last = 0 end
  if type(c.hourKills) ~= "table" then c.hourKills = {} end            -- time() of each boar, the last hour
  if type(c.days) ~= "table" then c.days = {} end                      -- ["2026-10-17"] = boars that day
  for day, n in pairs(c.days) do
    if type(day) ~= "string" or type(n) ~= "number" then c.days[day] = nil end
  end
  if c.goal ~= nil and (type(c.goal) ~= "number" or c.goal < 1) then c.goal = nil end   -- nil: beat yesterday
  if type(c.deathLog) ~= "table" then c.deathLog = {} end
  if type(BC.db.seen) ~= "table" then BC.db.seen = {} end              -- funny lines shown lately, per kind
  if type(BC.db.lastLine) ~= "table" then BC.db.lastLine = {} end
  BC.char = c
end

-- The old Boaring Challenge addon kept one number, the kills, for the whole account, so it can't say
-- which character they belong to. Every character starts at zero here; when the old data is still
-- around, chat says once what it counted and how to take it over, and you decide.
local function OldAddonHint()
  local c = BC.char
  if c.kills > 0 or c.oldHintShown then return end
  if type(BoaringChallengeDB) ~= "table" or type(BoaringChallengeDB.totalKills) ~= "number" then return end
  c.oldHintShown = true
  local n = math.floor(BoaringChallengeDB.totalKills)
  local level = tonumber(BoaringChallengeDB.characterLevel)
  BC.Print("the old Boaring Challenge counted " .. BC.Num(n) .. " boars" .. (level and (" on a level " .. level .. " character") or "") ..
    ". If that was you, type " .. GOLD .. "/boar set kills " .. n .. END .. ".")
end

------------------------------------------------------------------------------------------------------
-- What counts as a boar
------------------------------------------------------------------------------------------------------

function BC.IsBoar(name)
  if not name or name == "" or not BC.char then return false end
  if BC.char.names[name] or BC.char.extra[name] then return true end
  local lower = string.lower(name)
  for i = 1, table.getn(NAME_WORDS) do
    if string.find(lower, NAME_WORDS[i], 1, true) then return true end
  end
  return false
end

-- Targeting a boar teaches its name, so kills by your pet count too, and so do boars with odd names.
local function LearnTarget()
  if not BC.char or not UnitExists("target") then return end
  local family = UnitCreatureFamily("target")
  local name = UnitName("target")
  if family == "Boar" and name and not BC.char.names[name] then
    BC.char.names[name] = true
  end
end

------------------------------------------------------------------------------------------------------
-- Funny lines, milestones, records, boars per day, and where you died
------------------------------------------------------------------------------------------------------

local MILESTONES = { 100, 250, 500, 1000, 2500, 5000, 7500, 10000 }   -- then every 5,000
local LINE_GAP = { rare = 900, normal = 420 }   -- seconds between funny lines while you kill, about
local LINE_COLOUR = "|cffffe0b8"
local nextLineAt = nil   -- GetTime() of the next funny line
local lastHit = nil      -- { name, at }: the last thing that hurt you, for the death notes
local hourBase = false   -- the best hour when this session's first boar fell (nil: none yet). false: not looked yet
local STREAK_GAP = 90    -- seconds: a longer wait between boars ends the streak
local STREAKS = { 5, 10, 25, 50, 100 }

-- A funny line of this kind, or nil when they are off.
local function FunLine(kind)
  if BC.char.opt.lines == "off" or not BC.PickLine then return nil end
  return BC.PickLine(kind)
end

local function SayLine(line)
  if line then BC.Print(LINE_COLOUR .. line .. END) end
end

local function Banner(title, text, foot, secs)
  if BC.Banner then BC.Banner(title, text, foot, secs) end
end

function BC.SetLines(mode)
  BC.char.opt.lines = mode
  nextLineAt = nil
end

-- "2026-10-17", by this PC's clock.
function BC.Today()
  return date("%Y-%m-%d")
end

-- Noon, so many days ago: counting back from noon, a clock change in the night can't skip a day.
local function Noon(back)
  local now = time()
  local secs = tonumber(date("%H", now)) * 3600 + tonumber(date("%M", now)) * 60 + tonumber(date("%S", now))
  return now - secs + 43200 - back * 86400
end

function BC.Yesterday()
  return date("%Y-%m-%d", Noon(1))
end

-- The last 7 days, oldest first: { day = "2026-10-17", name = "Fri", n = boars, today = true/nil }
function BC.WeekDays()
  local list = {}
  for back = 6, 0, -1 do
    local t = Noon(back)
    local day = date("%Y-%m-%d", t)
    table.insert(list, { day = day, name = date("%a", t), n = BC.char.days[day] or 0, today = (back == 0) or nil })
  end
  return list
end

function BC.TodayKills()
  return BC.char.days[BC.Today()] or 0
end

function BC.YesterdayKills()
  return BC.char.days[BC.Yesterday()] or 0
end

-- The day's goal: the number you set, else one more than yesterday (or than the last day you played).
-- Also returns the day it has to beat, when it is that second kind.
function BC.DayGoal()
  local c = BC.char
  if c.goal then return c.goal, nil end
  local y = BC.Yesterday()
  if (c.days[y] or 0) > 0 then return c.days[y] + 1, y end
  local today, last = BC.Today(), nil
  for day, n in pairs(c.days) do
    if day < today and n > 0 and (not last or day > last) then last = day end
  end
  if last then return c.days[last] + 1, last end
  return nil, nil
end

-- Keeps the last 14 days.
local function PruneDays()
  local list = {}
  for day in pairs(BC.char.days) do table.insert(list, day) end
  table.sort(list, function(a, b) return a > b end)
  for i = 15, table.getn(list) do BC.char.days[list[i]] = nil end
end

function BC.IsMilestone(n)
  for i = 1, table.getn(MILESTONES) do
    if MILESTONES[i] == n then return true end
  end
  return n > 10000 and math.mod(n, 5000) == 0
end

-- 480 -> "8 minutes", over an hour "1h 05m"
local function Span(secs)
  local m = math.floor(secs / 60 + 0.5)
  if m < 60 then return m .. (m == 1 and " minute" or " minutes") end
  return BC.Time(secs)
end

local function NewRecord(what, value)
  if not BC.char.opt.records then return end
  local line = FunLine("record")
  Banner("NEW RECORD!", what .. ": " .. value, line, 5)
  BC.Print(GOLD .. "NEW RECORD!" .. END .. " " .. what .. ": " .. WHITE .. value .. END)
  SayLine(line)
  PlaySound("LEVELUPSOUND")
end

-- How long the level that ended at c.levels[i] took in time played, or nil when the addon didn't see all of it.
local function LevelTook(i)
  local c = BC.char
  local l, prev = c.levels[i], c.levels[i - 1]
  if not l then return nil end
  if l.took then
    if l.full and l.took > 0 then return l.took end
    return nil
  end
  -- saved before 1.5: two level-ups in a row tell it
  if prev and prev.level == l.level - 1 and l.played > prev.played then return l.played - prev.played end
  return nil
end

-- The best level pace: boars per hour over a whole level (its boars / its time played), for levels 5 and up that
-- the addon saw from start to end. The first one is kept quietly; only beating it makes a fuss.
local PACE_FROM = 5
local function PaceRecord(i, quiet)
  local c = BC.char
  local level = c.levels[i].level - 1          -- the level that just ended
  local took = LevelTook(i)
  if level < PACE_FROM or not took or took < 60 then return end
  local boars = c.byLevel[level] or 0
  if boars < 1 then return end
  local bph = boars / took * 3600
  local r = c.records.pace
  if r.bph and bph <= r.bph then return end
  local first = not r.bph
  r.bph, r.level, r.at = bph, level, time()
  if not first and not quiet then
    NewRecord("Best level pace", BC.Num(bph) .. " boars per hour on level " .. level)
  end
end

-- At login: the time on this level so far, if the addon saw it start. And the best level pace from the levels saved
-- before records existed.
local function StartClocks()
  local c = BC.char
  if type(c.levelPlayed) ~= "number" then
    c.levelPlayed, c.levelFull = 0, false
    local level = UnitLevel("player") or 0
    local n = table.getn(c.levels)
    if n > 0 and c.levels[n].level == level and c.played >= (c.levels[n].played or 0) then
      c.levelPlayed, c.levelFull = c.played - (c.levels[n].played or 0), true
    elseif level == 1 and (UnitXP("player") or 0) == 0 then
      c.levelFull = true
    end
  end
  if type(c.levelFull) ~= "boolean" then c.levelFull = false end
  if not c.records.pace.bph then
    for i = 1, table.getn(c.levels) do PaceRecord(i, true) end
  end
  PruneDays()
end

-- "412 boars, 1h 12m. 8 minutes faster than last level." for the level that ended at c.levels[i].
local function LevelText(i)
  local c = BC.char
  local l = c.levels[i]
  local text = BC.Num(c.byLevel[l.level - 1] or 0) .. " boars"
  local took, before = LevelTook(i), LevelTook(i - 1)
  if took then text = text .. ", " .. BC.Time(took) end
  text = text .. "."
  if took and before then
    local d = took - before
    if math.abs(d) < 60 then
      text = text .. " Same pace as last level."
    elseif d < 0 then
      text = text .. " " .. Span(-d) .. " faster than last level."
    else
      text = text .. " " .. Span(d) .. " slower than last level."
    end
  end
  return text
end

local function ShowLevelUp(i)
  local c = BC.char
  local l = c.levels[i]
  local line = FunLine("level")
  if c.opt.levelUp then
    local text = LevelText(i)
    Banner("Level " .. l.level .. "!", text, line, 6)
    BC.Print("level " .. (l.level - 1) .. " done: " .. text)
  elseif line then
    Banner(nil, line, nil, 4)
  end
  SayLine(line)
end

local function Milestone(n)
  local line = FunLine("milestone")
  Banner(BC.Num(n) .. " boars!", line, nil, 5)
  BC.Print(GOLD .. BC.Num(n) .. " boars killed!" .. END)
  SayLine(line)
end

local function GoalBanner(d, goal, base)
  local line = FunLine("goal")
  local text = BC.Num(d) .. " boars today."
  if base == BC.Yesterday() then
    text = text .. " You beat yesterday's " .. BC.Num(goal - 1) .. "."
  elseif base then
    text = text .. " You beat your last day, " .. BC.Num(goal - 1) .. " on " .. base .. "."
  end
  Banner("Daily goal reached!", text, line, 5)
  BC.Print(GOLD .. "Daily goal reached!" .. END .. " " .. text)
  SayLine(line)
end

-- The streak: boars in a row with no break. A break is a wait over 90 seconds, eating, drinking, AFK or dying.
-- c.streak = { n, last = time() of the last boar, base = the best streak when this one started }
function BC.StreakNow()
  local s = BC.char.streak
  if s.n > 0 and time() - s.last > STREAK_GAP then return 0 end
  return s.n
end

function BC.BreakStreak()
  if BC.char and BC.char.streak.n > 0 then
    BC.char.streak.n = 0
    if BC.Refresh then BC.Refresh() end
  end
end

local function Streak(now)
  local c = BC.char
  local s, r = c.streak, c.records.streak
  if s.n > 0 and now - s.last > STREAK_GAP then s.n = 0 end
  if s.n == 0 then s.base = r.n end
  s.n, s.last = s.n + 1, now
  if s.n > (r.n or 0) then
    r.n, r.at = s.n, now
    if s.base and s.n == s.base + 1 then NewRecord("Longest streak", BC.Num(s.n) .. " boars in a row") end
  end
  if not c.opt.streaks then return end
  for i = 1, table.getn(STREAKS) do
    if STREAKS[i] == s.n then
      local line = FunLine("streak")
      Banner(s.n .. " boars in a row, no break!", line, nil, 4)
      BC.Print(GOLD .. s.n .. " boars in a row, no break!" .. END)
      SayLine(line)
    end
  end
end

-- After each boar: the best hour and day, milestones, the day's goal, and now and then a funny line.
local function AfterKill()
  local c = BC.char
  local now = time()
  -- boars in the last 60 minutes. Raising a record you set within the hour is the same run, so it stays quiet.
  table.insert(c.hourKills, now)
  while c.hourKills[1] and now - c.hourKills[1] >= 3600 do table.remove(c.hourKills, 1) end
  local n = table.getn(c.hourKills)
  local r = c.records.hour
  if hourBase == false then hourBase = r.n end
  if n > (r.n or 0) then
    r.n, r.at = n, now
    -- one fuss per session, when it beats the best from before the session
    if hourBase and n == hourBase + 1 then NewRecord("Most boars in one hour", BC.Num(n)) end
  end
    Streak(now)
  -- boars today; today raising its own record stays quiet
  local today = BC.Today()
  if not c.days[today] then
    c.days[today] = 0
    PruneDays()
  end
  c.days[today] = c.days[today] + 1
  local d = c.days[today]
  r = c.records.day
  if d > (r.n or 0) then
    local beat = r.n and r.day ~= today
    r.n, r.day = d, today
    if beat then NewRecord("Most boars in one day", BC.Num(d)) end
  end
  if c.opt.milestones and BC.IsMilestone(c.kills) then Milestone(c.kills) end
  -- the day's goal, and passing yesterday (when the goal isn't simply that)
  if c.opt.goal then
    local goal, base = BC.DayGoal()
    local yday = BC.YesterdayKills()
    if goal and d == goal then
      GoalBanner(d, goal, base)
    elseif yday > 0 and d == yday + 1 then
      local line = FunLine("goal")
      Banner("You beat yesterday!", BC.Num(d) .. " boars today, " .. BC.Num(yday) .. " yesterday.", line, 5)
      BC.Print(GOLD .. "You beat yesterday!" .. END .. " " .. BC.Num(d) .. " boars today.")
      SayLine(line)
    end
  end
  -- a funny line every so often, when nothing else is on screen
  local mode = c.opt.lines
  if mode ~= "off" and LINE_GAP[mode] then
    local t = GetTime()
    if not nextLineAt then nextLineAt = t + LINE_GAP[mode] * (0.3 + math.random() * 0.4) end
    if t >= nextLineAt and not (BC.BannerBusy and BC.BannerBusy()) then
      nextLineAt = t + LINE_GAP[mode] * (0.7 + math.random() * 0.6)
      local line = FunLine("kill")
      Banner(nil, line, nil, 4)
      SayLine(line)
    end
  end
end

-- "X hits you for 5." and the like: remembers X, so a death can say what did it.
local function Hurt(msg, spell)
  local _, who
  if spell then
    _, _, who = string.find(msg, "^(.+)'s .+ hits you for %d")
    if not who then _, _, who = string.find(msg, "^(.+)'s .+ crits you for %d") end
    if not who then _, _, who = string.find(msg, "^You suffer %d+ .- damage from (.+)'s ") end
  else
    _, _, who = string.find(msg, "^(.+) hits you for %d")
    if not who then _, _, who = string.find(msg, "^(.+) crits you for %d") end
    if not who and string.find(msg, "^You fall and lose") then who = "falling" end
    if not who and string.find(msg, "^You are drowning") then who = "drowning" end
    if not who and string.find(msg, "^You lose %d+ health for swimming in lava") then who = "lava" end
    if not who and string.find(msg, "^You are exhausted and lose") then who = "fatigue" end
  end
  if who then lastHit = { name = who, at = GetTime() } end
end

local function NoteDeath()
  local c = BC.char
  if c.opt.deathNotes then
    -- the map follows you, unless it is open: then leave it where you put it
    if not (WorldMapFrame and WorldMapFrame:IsVisible()) then SetMapToCurrentZone() end
    local x, y = GetPlayerMapPosition("player")
    local killer = "unknown"
    if lastHit and GetTime() - lastHit.at <= 30 then killer = lastHit.name end
    local zone = GetZoneText() or "?"
    table.insert(c.deathLog, {
      at = time(), zone = zone, sub = GetSubZoneText() or "", level = UnitLevel("player") or 0, killer = killer,
      x = math.floor((x or 0) * 1000 + 0.5) / 10, y = math.floor((y or 0) * 1000 + 0.5) / 10,
    })
    while table.getn(c.deathLog) > 50 do table.remove(c.deathLog, 1) end
    BC.Print("death noted: " .. WHITE .. killer .. END .. GREY .. ", " .. zone .. ". /boar deaths lists them." .. END)
  end
  lastHit = nil
  BC.BreakStreak()
  local line = FunLine("death")
  if line then
    Banner(nil, line, nil, 4)
    SayLine(line)
  end
end

------------------------------------------------------------------------------------------------------
-- Counting
------------------------------------------------------------------------------------------------------

local function Prune()
  local now = GetTime()
  while recent[1] and now - recent[1].at > 3600 do table.remove(recent, 1) end
end

local function Kill(name)
  local now = GetTime()
  if lastKill[name] and now - lastKill[name] < DOUBLE then return end
  if not BC.IsBoar(name) then return end
  lastKill[name] = now
  local c = BC.char
  c.kills = c.kills + 1
  c.byName[name] = (c.byName[name] or 0) + 1
  local level = UnitLevel("player") or 0
  c.byLevel[level] = (c.byLevel[level] or 0) + 1
  BC.session.kills = BC.session.kills + 1
  table.insert(recent, { at = now, kill = true })
  AfterKill()
  if BC.Refresh then BC.Refresh() end
end

local function GainXP(amount, from, bonus)
  local c = BC.char
  if from and BC.IsBoar(from) then
    c.boarXP = c.boarXP + amount
    c.xpKills = (c.xpKills or 0) + 1
    BC.session.boarXP = BC.session.boarXP + amount
    BC.session.boarBase = BC.session.boarBase + amount - (bonus or 0)
    -- the last boar, kept for the next login: what it gave without rested, at what level, and its own level
    local mob = (UnitName("target") == from) and UnitLevel("target") or nil
    if mob and mob < 1 then mob = nil end
    c.lastBoar = { xp = amount, base = amount - (bonus or 0), level = UnitLevel("player"), mob = mob, at = time() }
  else
    c.otherXP = c.otherXP + amount
  end
  BC.session.xp = BC.session.xp + amount
  table.insert(recent, { at = GetTime(), xp = amount })
  if BC.Refresh then BC.Refresh() end
end

local function LevelUp(level)
  local c = BC.char
  table.insert(c.levels, { level = level, at = time(), kills = c.kills, played = c.played,
    took = c.levelPlayed, full = c.levelFull })
  BC.Print(GOLD .. "Level " .. level .. "!" .. END .. " " .. BC.Num(c.kills) .. " boars and " .. BC.Time(c.played) .. " played so far.")
  local i = table.getn(c.levels)
  ShowLevelUp(i)
  PaceRecord(i)
  c.levelPlayed, c.levelFull = 0, true
  if BC.Refresh then BC.Refresh() end
end

------------------------------------------------------------------------------------------------------
-- The numbers the panel shows
------------------------------------------------------------------------------------------------------

-- XP and boars in the last 30 minutes (or the whole session when it is shorter), as an hourly rate.
local function WindowRates()
  Prune()
  local now = GetTime()
  local xp, kills = 0, 0
  for i = 1, table.getn(recent) do
    local e = recent[i]
    if now - e.at <= WINDOW then
      xp = xp + (e.xp or 0)
      if e.kill then kills = kills + 1 end
    end
  end
  local span = BC.session.played
  if span > WINDOW then span = WINDOW end
  if span < 60 then return 0, 0 end
  return xp / span * 3600, kills / span * 3600
end

-- Everything the panel and /boar print: a table of numbers, worked out fresh.
function BC.Stats()
  local c, s = BC.char, BC.session
  local st = {}
  st.kills, st.sessionKills, st.deaths = c.kills, s.kills, c.deaths
  st.level = UnitLevel("player") or 1
  st.xp, st.xpMax = UnitXP("player") or 0, UnitXPMax("player") or 1
  if st.xpMax < 1 then st.xpMax = 1 end
  st.pct = math.floor(st.xp / st.xpMax * 100 + 0.5)
  st.played, st.sessionPlayed = c.played, s.played
  local hours = s.played / 3600
  st.xpHour = (hours > 0.0167) and (s.xp / hours) or 0
  st.killsHour = (hours > 0.0167) and (s.kills / hours) or 0
  st.xpHourRecent, st.killsHourRecent = WindowRates()
  -- What a boar gives without the rested bonus: this session's boars; before the first kill of a
  -- session, the last boar you killed (scaled if you have levelled since); failing that, all time.
  local plain
  if s.kills > 0 and s.boarBase > 0 then
    plain = s.boarBase / s.kills
  elseif c.lastBoar and c.lastBoar.base and c.lastBoar.base > 0 then
    plain = c.lastBoar.base
    if c.lastBoar.level and c.lastBoar.level ~= st.level and BC.KillXP then
      local mob = c.lastBoar.mob or c.lastBoar.level
      local was, now = BC.KillXP(c.lastBoar.level, mob), BC.KillXP(st.level, mob)
      if was > 0 then plain = plain * now / was end
    end
  elseif (c.xpKills or 0) > 0 then
    plain = c.boarXP / c.xpKills
  else
    plain = 0
  end
  st.rested = (GetXPExhaustion and GetXPExhaustion()) or 0
  st.xpPerBoarBase = plain
  -- while rested XP lasts a boar gives double, and the pool goes down by the plain amount
  st.xpPerBoar = (st.rested >= plain) and plain * 2 or plain
  local left = st.xpMax - st.xp
  if plain > 0 then
    if 2 * st.rested >= left then
      st.boarsToLevel = math.ceil(left / (2 * plain))
    else
      st.boarsToLevel = math.ceil((left - st.rested) / plain)
    end
    if st.boarsToLevel < 0 then st.boarsToLevel = 0 end
  else
    st.boarsToLevel = nil
  end
  -- the pace: the last 30 minutes, else this session, else the pace you left with last time
  local rate = (s.played >= 300 and st.xpHourRecent > 0) and st.xpHourRecent or st.xpHour
  if rate > 0 and s.played >= 600 then c.lastRate = rate end
  if rate <= 0 and c.lastRate then
    rate = c.lastRate
    st.paceFromLast = true
  end
  st.secondsToLevel = (rate > 0) and (left / rate * 3600) or nil
  -- the extra rows
  st.thisLevelKills = c.byLevel[st.level] or 0
  local n = table.getn(c.levels)
  if n >= 1 then
    local last, prev = c.levels[n], c.levels[n - 1]
    st.lastLevel = last.level
    st.lastLevelKills = last.kills - (prev and prev.kills or 0)
    st.lastLevelTime = last.played - (prev and prev.played or 0)
    st.lastLevelFull = (prev ~= nil)
  end
  st.restedBoars = (plain > 0 and st.rested > 0) and math.floor(st.rested / plain) or nil
  st.sessionXP = s.xp
  if s.played >= 600 and st.xpHour > (c.bestXPHour or 0) then c.bestXPHour = st.xpHour end
  st.bestXPHour = c.bestXPHour or 0
  return st
end

------------------------------------------------------------------------------------------------------
-- /boar
------------------------------------------------------------------------------------------------------

-- "14h30m", "14.5", "90m", "2h" -> seconds
function BC.ParseTime(text)
  text = string.lower(BC.Trim(text))
  local _, _, h, m = string.find(text, "^(%d+)h%s*(%d*)m?$")
  if h then return tonumber(h) * 3600 + (tonumber(m) or 0) * 60 end
  local _, _, mins = string.find(text, "^(%d+)m$")
  if mins then return tonumber(mins) * 60 end
  local n = tonumber(text)
  if n then return n * 3600 end
  return nil
end

local function SetValue(what, value)
  local c = BC.char
  local n = tonumber(value)
  if what == "kills" and n then
    c.kills = math.floor(n)
    BC.Print("boars killed set to " .. BC.Num(c.kills) .. ".")
  elseif what == "deaths" and n then
    c.deaths = math.floor(n)
    BC.Print("deaths set to " .. c.deaths .. ".")
  elseif what == "xp" and n then
    c.boarXP = math.floor(n)
    BC.Print("XP from boars set to " .. BC.Num(c.boarXP) .. ".")
  elseif what == "otherxp" and n then
    c.otherXP = math.floor(n)
    BC.Print("XP from everything else set to " .. BC.Num(c.otherXP) .. ".")
  elseif what == "played" or what == "time" then
    local secs = BC.ParseTime(value)
    if not secs then
      BC.Print("time like 14h30m, 90m or 14.5.")
      return
    end
    c.played = secs
    BC.Print("time played set to " .. BC.Time(c.played) .. ".")
  else
    BC.Print("set kills, deaths, played, xp or otherxp. Like " .. GOLD .. "/boar set kills 1000" .. END)
    return
  end
  if BC.Refresh then BC.Refresh() end
end

function BC.ResetSession()
  BC.session = { startedAt = GetTime(), kills = 0, xp = 0, boarXP = 0, boarBase = 0, played = 0, deaths = 0 }
  recent = {}
  hourBase = false
  BC.Print("session counters start again.")
  if BC.Refresh then BC.Refresh() end
end

function BC.ResetAll()
  BoarChallengePlusCharDB = {}
  InitDB()
  StartClocks()
  BC.ResetSession()
  BC.Print(RED .. "everything for this character is back to zero." .. END)
end

local function ListNames()
  local list = {}
  for name, n in pairs(BC.char.byName) do table.insert(list, { name = name, n = n }) end
  table.sort(list, function(a, b) return a.n > b.n end)
  if table.getn(list) == 0 then
    BC.Print("no boars counted yet on this character.")
    return
  end
  BC.Print("boars killed, by kind:")
  for i = 1, table.getn(list) do
    DEFAULT_CHAT_FRAME:AddMessage("  " .. WHITE .. BC.Num(list[i].n) .. END .. "  " .. list[i].name)
  end
end

local function ListLevels()
  local c = BC.char
  if table.getn(c.levels) == 0 then
    BC.Print("no level-ups seen yet.")
    return
  end
  BC.Print("levels reached:")
  for i = 1, table.getn(c.levels) do
    local l = c.levels[i]
    DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. "Level " .. l.level .. END .. "  after " .. BC.Num(l.kills) .. " boars and " ..
      BC.Time(l.played) .. " played  " .. GREY .. date("%Y-%m-%d %H:%M", l.at) .. END)
  end
end

local function ListDeaths()
  local log = BC.char.deathLog
  local n = table.getn(log)
  if n == 0 then
    BC.Print("no deaths noted yet.")
    return
  end
  BC.Print("last deaths, newest first:")
  for i = n, math.max(1, n - 19), -1 do
    local d = log[i]
    local where = d.zone .. ((d.sub ~= "" and d.sub ~= d.zone) and (", " .. d.sub) or "")
    if (d.x or 0) > 0 or (d.y or 0) > 0 then where = where .. " (" .. d.x .. ", " .. d.y .. ")" end
    DEFAULT_CHAT_FRAME:AddMessage("  " .. GREY .. date("%m-%d %H:%M", d.at) .. END .. "  " .. RED .. d.killer .. END ..
      "  level " .. d.level .. "  " .. WHITE .. where .. END)
  end
end

local function ListRecords()
  local r = BC.char.records
  local dash = GREY .. "none yet" .. END
  BC.Print("your records:")
  local lines = {
    "Best level pace: " .. (r.pace.bph and (WHITE .. BC.Num(r.pace.bph) .. " boars per hour" .. END .. GREY .. "  level " .. r.pace.level .. END) or dash),
    "Most boars in one hour: " .. (r.hour.n and (WHITE .. BC.Num(r.hour.n) .. END .. GREY .. "  " .. date("%Y-%m-%d", r.hour.at) .. END) or dash),
    "Most boars in one day: " .. (r.day.n and (WHITE .. BC.Num(r.day.n) .. END .. GREY .. "  " .. r.day.day .. END) or dash),
    "Longest streak: " .. (r.streak.n and (WHITE .. BC.Num(r.streak.n) .. " in a row" .. END .. GREY .. "  " .. date("%Y-%m-%d", r.streak.at) .. END) or dash),
  }
  for i = 1, table.getn(lines) do DEFAULT_CHAT_FRAME:AddMessage("  " .. lines[i]) end
  DEFAULT_CHAT_FRAME:AddMessage("  " .. GREY .. "Best level pace: levels 5 and up the addon saw from start to end." .. END)
end

local function ListDays()
  local list = {}
  for day, n in pairs(BC.char.days) do table.insert(list, { day = day, n = n }) end
  table.sort(list, function(a, b) return a.day > b.day end)
  if table.getn(list) == 0 then
    BC.Print("no boars counted per day yet.")
    return
  end
  BC.Print("boars per day (last 14):")
  local today = BC.Today()
  for i = 1, table.getn(list) do
    local d = list[i]
    DEFAULT_CHAT_FRAME:AddMessage("  " .. (d.day == today and GOLD or GREY) .. d.day .. END .. "  " .. WHITE .. BC.Num(d.n) .. END)
  end
end

local function GoalCommand(rest)
  local c = BC.char
  rest = string.lower(BC.Trim(rest))
  local n = tonumber(rest)
  if n and n >= 1 then
    c.goal = math.floor(n)
    BC.Print("daily goal set to " .. BC.Num(c.goal) .. " boars. " .. GOLD .. "/boar goal auto" .. END .. " goes back to beating yesterday.")
  elseif rest == "auto" or rest == "off" then
    c.goal = nil
    BC.Print("daily goal: one more than yesterday.")
  else
    local goal = BC.DayGoal()
    BC.Print("today " .. BC.Num(BC.TodayKills()) .. " boars, goal " .. (goal and BC.Num(goal) or "none yet") ..
      (c.goal and " (set by you)" or " (beat yesterday)") .. ". " .. GOLD .. "/boar goal 200" .. END .. " or " .. GOLD .. "/boar goal auto" .. END .. ".")
    return
  end
  if BC.Refresh then BC.Refresh() end
end

-- Hidden: /boar test <thing> shows each message once, even when it is switched off.
local function Test(what)
  local c = BC.char
  local pick = BC.PickLine or function() return nil end
  if what == "line" then
    local line = pick("kill")
    Banner(nil, line, nil, 4)
    SayLine(line)
  elseif what == "banner" then
    Banner("Test banner", "The middle line.", "The small line.", 4)
    Banner("A second one", "It waits for the first.", nil, 3)
  elseif what == "level" then
    local level = UnitLevel("player") or 2
    local text = BC.Num(c.byLevel[level - 1] or 0) .. " boars, 1h 12m. 8 minutes faster than last level."
    Banner("Level " .. level .. "!", text, pick("level"), 6)
  elseif what == "milestone" then
    Banner("1,000 boars!", pick("milestone"), nil, 5)
  elseif what == "record" then
    Banner("NEW RECORD!", "Most boars in one hour: 99", pick("record"), 5)
    PlaySound("LEVELUPSOUND")
  elseif what == "goal" then
    Banner("Daily goal reached!", "120 boars today. You beat yesterday's 119.", pick("goal"), 5)
  elseif what == "streak" then
    Banner("10 boars in a row, no break!", pick("streak"), nil, 4)
  elseif what == "death" then
    local line = pick("death")
    Banner(nil, line, nil, 4)
    SayLine(line)
  else
    BC.Print("test: line, banner, level, milestone, record, goal, streak, death.")
  end
end

local function Help()
  BC.Print("v" .. BC.VERSION)
  local lines = {
    GOLD .. "Panel" .. END,
    "/boar" .. GREY .. "  show or hide the panel" .. END,
    "/boar edit" .. GREY .. "  settings (or right-click the panel)" .. END,
    "/boar show <thing>" .. GREY .. "  one thing on or off" .. END,
    "/boar scale 1.2" .. GREY .. "  panel size, 0.6 to 2" .. END,
    "/boar lock" .. GREY .. "  lock or unlock (Shift-drag always works)" .. END,
    GOLD .. "Where to go" .. END,
    "/boar where" .. GREY .. "  boars here, and where next" .. END,
    "/boar route" .. GREY .. "  your road to 60" .. END,
    "/boar route all" .. GREY .. "  every boar known" .. END,
    GOLD .. "Boars" .. END,
    "/boar add <name>" .. GREY .. "  count it as a boar" .. END,
    "/boar remove <name>" .. GREY .. "  stop counting it" .. END,
    "/boar list" .. GREY .. "  boars killed, by kind" .. END,
    "/boar levels" .. GREY .. "  each level's boars and time" .. END,
    GOLD .. "Goals and records" .. END,
    "/boar goal 200" .. GREY .. "  daily goal; auto = beat yesterday" .. END,
    "/boar days" .. GREY .. "  boars per day, last 14" .. END,
    "/boar week" .. GREY .. "  chart of the last 7 days" .. END,
    "/boar records" .. GREY .. "  your best level, hour, day, streak" .. END,
    "/boar deaths" .. GREY .. "  where you died, and to what" .. END,
    "/boar lines off" .. GREY .. "  funny lines: off, rare or normal" .. END,
    GOLD .. "Numbers" .. END,
    "/boar set kills 1000" .. GREY .. "  also deaths, played, xp, otherxp" .. END,
    "/boar session" .. GREY .. "  new session" .. END,
    "/boar reset" .. GREY .. "  this character back to zero" .. END,
  }
  for i = 1, table.getn(lines) do DEFAULT_CHAT_FRAME:AddMessage("  " .. WHITE .. lines[i]) end
end

local resetAsked = 0

local function Slash(msg)
  if not BC.char then return end
  msg = BC.Trim(msg)
  local _, _, word, rest = string.find(msg, "^(%S*)%s*(.-)$")
  word = string.lower(word or "")
  if word == "" then
    if BC.TogglePanel then BC.TogglePanel() end
  elseif word == "edit" or word == "options" or word == "settings" or word == "config" then
    if BC.ShowEdit then BC.ShowEdit() end
  elseif word == "set" then
    local _, _, what, value = string.find(rest, "^(%S+)%s*(.-)$")
    SetValue(string.lower(what or ""), value or "")
  elseif word == "add" then
    rest = BC.Trim(rest)
    if rest == "" then rest = UnitName("target") or "" end
    if rest == "" then
      BC.Print("name it or target it: /boar add Mottled Boar")
    else
      BC.char.extra[rest] = true
      BC.Print(WHITE .. rest .. END .. " counts as a boar from now on.")
    end
  elseif word == "remove" then
    rest = BC.Trim(rest)
    BC.char.extra[rest] = nil
    BC.char.names[rest] = nil
    BC.Print(WHITE .. rest .. END .. " no longer counts (unless its name has boar in it).")
  elseif word == "where" or word == "next" then
    if BC.PrintWhere then BC.PrintWhere() end
  elseif word == "route" then
    if BC.PrintRoute then BC.PrintRoute(string.lower(BC.Trim(rest)) == "all") end
  elseif word == "scale" or word == "size" then
    local n = tonumber(rest)
    if n and n > 3 then n = n / 100 end         -- "/boar scale 120" means 120%
    if n and BC.SetScale then
      BC.SetScale(n)
      BC.Print("panel size " .. math.floor(BC.db.scale * 100 + 0.5) .. "%.")
    else
      BC.Print("size like " .. GOLD .. "/boar scale 1.2" .. END .. " (0.6 to 2).")
    end
  elseif word == "show" then
    local key = nil
    local want = string.lower(BC.Trim(rest))
    for i = 1, table.getn(BC.ITEMS or {}) do
      if string.lower(BC.ITEMS[i].key) == want then key = BC.ITEMS[i].key end
    end
    if key then
      BC.char.show[key] = not BC.char.show[key]
      BC.Print(key .. " is now " .. (BC.char.show[key] and "on" or "off") .. ".")
      if BC.Layout then BC.Layout() end
    else
      local keys = {}
      for i = 1, table.getn(BC.ITEMS or {}) do table.insert(keys, BC.ITEMS[i].key) end
      BC.Print("things on the panel: " .. table.concat(keys, ", ") .. ". " .. GOLD .. "/boar show <thing>" .. END .. " switches one.")
    end
  elseif word == "list" then
    ListNames()
  elseif word == "levels" then
    ListLevels()
  elseif word == "deaths" then
    ListDeaths()
  elseif word == "records" or word == "record" then
    ListRecords()
  elseif word == "days" or word == "day" then
    ListDays()
  elseif word == "week" then
    if BC.ToggleWeek then BC.ToggleWeek() end
  elseif word == "goal" then
    GoalCommand(rest)
  elseif word == "lines" or word == "line" then
    local mode = string.lower(BC.Trim(rest))
    if mode == "off" or mode == "rare" or mode == "normal" then
      BC.SetLines(mode)
      if BC.FillEdit then BC.FillEdit() end
    end
    BC.Print("funny lines: " .. WHITE .. BC.char.opt.lines .. END .. ". " .. GOLD .. "/boar lines off" .. END .. ", rare or normal.")
  elseif word == "test" then
    Test(string.lower(BC.Trim(rest)))
  elseif word == "session" then
    BC.ResetSession()
  elseif word == "lock" or word == "unlock" or word == "move" then
    BC.db.locked = not BC.db.locked
    BC.Print("panel " .. (BC.db.locked and "locked." or "unlocked. Drag it, then /boar lock."))
    if BC.Refresh then BC.Refresh() end
  elseif word == "reset" then
    if GetTime() - resetAsked < 10 then
      BC.ResetAll()
    else
      resetAsked = GetTime()
      BC.Print(RED .. "wipes every number for this character." .. END .. " Type " .. GOLD .. "/boar reset" .. END .. " again in 10 seconds.")
    end
  else
    Help()
  end
end

SLASH_BOARCHALLENGEPLUS1 = "/boar"
SLASH_BOARCHALLENGEPLUS2 = "/boarplus"
SlashCmdList["BOARCHALLENGEPLUS"] = Slash

------------------------------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("VARIABLES_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
events:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("PLAYER_AURAS_CHANGED")
-- what hurt you, for the death notes
local HURT = {
  CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS = false, CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS = false, CHAT_MSG_COMBAT_SELF_HITS = false,
  CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE = true, CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE = true,
  CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE = true,
}
for e in pairs(HURT) do events:RegisterEvent(e) end

-- Eating or drinking ends the streak: their buffs have a fork and knife or a drink as the icon.
local function EatingOrDrinking()
  local i = 1
  while UnitBuff("player", i) do
    local icon = UnitBuff("player", i)
    if string.find(icon, "Fork&Knife", 1, true) or string.find(icon, "INV_Drink_", 1, true) then return true end
    i = i + 1
  end
  return false
end
events:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    InitDB()
  elseif event == "PLAYER_LOGIN" then
    if not BC.char then InitDB() end
    BC.session.startedAt = GetTime()
    if BC.InitPanel then BC.InitPanel() end
    BC.Print("v" .. BC.VERSION .. " counting for " .. GOLD .. (UnitName("player") or "you") .. END .. ": " ..
      BC.Num(BC.char.kills) .. " boars. " .. GOLD .. "/boar" .. END .. " panel, " .. GOLD .. "/boar help" .. END .. " commands.")
    -- Stealthboar had 1000 boars before this addon existed (993 on the old addon, a few more since). Everyone else starts at 0.
    if BC.char.kills == 0 and not BC.char.seeded and UnitName("player") == "Stealthboar" then
      BC.char.seeded = true
      BC.char.kills = 1000
      BC.Print("starting at 1000 boars. Right-click the panel to change it.")
    end
    OldAddonHint()
    StartClocks()
  elseif not BC.char then
    return
  elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
    local _, _, name = string.find(arg1 or "", "^You have slain (.-)!$")
    if name then
      Kill(name)
    else
      -- "X dies." with X your target: your pet or a friend got the blow.
      _, _, name = string.find(arg1 or "", "^(.-) dies%.$")
      if name and UnitName("target") == name then Kill(name) end
    end
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
    -- "Mottled Boar dies, you gain 45 experience. (+22 exp Rested bonus)" or "You gain 250 experience."
    local _, _, name, xp = string.find(arg1 or "", "^(.-) dies, you gain (%d+) experience")
    if name then
      local _, _, bonus = string.find(arg1, "(%d+) exp Rested bonus")
      GainXP(tonumber(xp), name, tonumber(bonus))
      Kill(name)
    else
      _, _, xp = string.find(arg1 or "", "^You gain (%d+) experience")
      if xp then GainXP(tonumber(xp), nil) end
    end
  elseif event == "PLAYER_LEVEL_UP" then
    LevelUp(tonumber(arg1) or UnitLevel("player"))
  elseif event == "PLAYER_DEAD" then
    BC.char.deaths = BC.char.deaths + 1
    BC.session.deaths = BC.session.deaths + 1
    NoteDeath()
    if BC.Refresh then BC.Refresh() end
  elseif HURT[event] ~= nil then
    Hurt(arg1 or "", HURT[event])
  elseif event == "PLAYER_AURAS_CHANGED" then
    if BC.char.streak.n > 0 and EatingOrDrinking() then BC.BreakStreak() end
  elseif event == "PLAYER_TARGET_CHANGED" then
    LearnTarget()
  elseif event == "PLAYER_XP_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" then
    if BC.Refresh then BC.Refresh() end
  end
end)

-- Time played ticks while you are logged in and not AFK.
events:SetScript("OnUpdate", function()
  if not BC.char then return end
  if UnitIsAFK and UnitIsAFK("player") then
    BC.BreakStreak()
    return
  end
  BC.char.played = BC.char.played + arg1
  BC.char.levelPlayed = (BC.char.levelPlayed or 0) + arg1
  BC.session.played = BC.session.played + arg1
end)
