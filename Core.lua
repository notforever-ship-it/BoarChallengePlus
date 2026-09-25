-- Boar Tally: for a character that levels on boars alone. Counts every boar you kill and the XP
-- you get, keeps your time, and works out XP and boars per hour and how long the next level will take.
-- Everything is saved per character; every number can be changed with /boar set or the edit window.
--
-- A kill is "You have slain X!" in the combat log, or "X dies, you gain N experience.", or "X dies."
-- while X is your target (your pet got the blow). A boar is anything the game calls a Boar when you
-- target it (remembered by name from then on), anything with boar or goretusk in its name, and any
-- name you add with /boar add.

BoarTally = {}
local BC = BoarTally
BC.VERSION = "1.1.0"

local GOLD, GREY, WHITE, RED, GREEN, END = "|cffffd100", "|cff9d9d9d", "|cffffffff", "|cffff4040", "|cff40ff40", "|r"
BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END = GOLD, GREY, WHITE, RED, GREEN, END

local NAME_WORDS = { "boar", "goretusk", "agam'ar" }   -- boars whose names say so, or nearly
local WINDOW = 1800                                    -- seconds: the "last 30 min" rate
local DOUBLE = 1.5                                     -- seconds: the same death seen twice is one kill

local DEFAULTS = { locked = true, shown = true }

BC.session = { startedAt = 0, kills = 0, xp = 0, boarXP = 0, played = 0, deaths = 0 }
local recent = {}        -- { at, xp, kill }: the last hour, for the "last 30 min" rate
local lastKill = {}      -- [name] = GetTime() of the last counted kill

function BC.Print(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffd9a066Boar Tally:|r " .. msg) end
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
  if type(BoarTallyDB) ~= "table" then BoarTallyDB = {} end
  for k, v in pairs(DEFAULTS) do
    if BoarTallyDB[k] == nil then BoarTallyDB[k] = v end
  end
  BC.db = BoarTallyDB

  if type(BoarTallyCharDB) ~= "table" then BoarTallyCharDB = {} end
  local c = BoarTallyCharDB
  if type(c.kills) ~= "number" then c.kills = 0 end
  if type(c.boarXP) ~= "number" then c.boarXP = 0 end
  if type(c.otherXP) ~= "number" then c.otherXP = 0 end
  if type(c.deaths) ~= "number" then c.deaths = 0 end
  if type(c.played) ~= "number" then c.played = 0 end
  if type(c.byName) ~= "table" then c.byName = {} end
  if type(c.byLevel) ~= "table" then c.byLevel = {} end
  if type(c.levels) ~= "table" then c.levels = {} end
  if type(c.names) ~= "table" then c.names = {} end        -- names the game called Boar when targeted
  if type(c.extra) ~= "table" then c.extra = {} end        -- names you added with /boar add
  if not c.startedAt then c.startedAt = time() end
  if not c.startLevel then c.startLevel = UnitLevel("player") end
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
    ". If that was this character, type " .. GOLD .. "/boar set kills " .. n .. END .. ". Anyone else starts at 0.")
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
  if BC.Refresh then BC.Refresh() end
end

local function GainXP(amount, from)
  local c = BC.char
  if from and BC.IsBoar(from) then
    c.boarXP = c.boarXP + amount
    BC.session.boarXP = BC.session.boarXP + amount
  else
    c.otherXP = c.otherXP + amount
  end
  BC.session.xp = BC.session.xp + amount
  table.insert(recent, { at = GetTime(), xp = amount })
  if BC.Refresh then BC.Refresh() end
end

local function LevelUp(level)
  local c = BC.char
  table.insert(c.levels, { level = level, at = time(), kills = c.kills, played = c.played })
  BC.Print(GOLD .. "Level " .. level .. "!" .. END .. " " .. BC.Num(c.kills) .. " boars and " .. BC.Time(c.played) .. " played so far.")
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
  -- XP per boar: this session's boars, else what the character has seen over all time
  if s.kills > 0 then
    st.xpPerBoar = s.boarXP / s.kills
  elseif c.kills > 0 then
    st.xpPerBoar = c.boarXP / c.kills
  else
    st.xpPerBoar = 0
  end
  local left = st.xpMax - st.xp
  st.boarsToLevel = (st.xpPerBoar > 0) and math.ceil(left / st.xpPerBoar) or nil
  local rate = (s.played >= 300 and st.xpHourRecent > 0) and st.xpHourRecent or st.xpHour
  st.secondsToLevel = (rate > 0) and (left / rate * 3600) or nil
  local total = c.boarXP + c.otherXP
  st.boarShare = (total > 0) and math.floor(c.boarXP / total * 100 + 0.5) or nil
  return st
end

------------------------------------------------------------------------------------------------------
-- /boar
------------------------------------------------------------------------------------------------------

-- "14h30m", "14.5", "90m", "2h" -> seconds
local function ParseTime(text)
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
    local secs = ParseTime(value)
    if not secs then
      BC.Print("say the time like 14h30m, 90m or 14.5 (hours).")
      return
    end
    c.played = secs
    BC.Print("time played set to " .. BC.Time(c.played) .. ".")
  else
    BC.Print("you can set: kills, deaths, played, xp (from boars), otherxp. For example " .. GOLD .. "/boar set kills 1000" .. END)
    return
  end
  if BC.Refresh then BC.Refresh() end
end

function BC.ResetSession()
  BC.session = { startedAt = GetTime(), kills = 0, xp = 0, boarXP = 0, played = 0, deaths = 0 }
  recent = {}
  BC.Print("session counters start again.")
  if BC.Refresh then BC.Refresh() end
end

function BC.ResetAll()
  BoarTallyCharDB = {}
  InitDB()
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
    BC.Print("no level-ups seen yet. The first one gets written down with the boars and time it took.")
    return
  end
  BC.Print("levels reached:")
  for i = 1, table.getn(c.levels) do
    local l = c.levels[i]
    DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. "Level " .. l.level .. END .. "  after " .. BC.Num(l.kills) .. " boars and " ..
      BC.Time(l.played) .. " played  " .. GREY .. date("%Y-%m-%d %H:%M", l.at) .. END)
  end
end

local function Help()
  BC.Print("v" .. BC.VERSION .. " commands:")
  local lines = {
    "/boar" .. GREY .. "  show or hide the panel" .. END,
    "/boar edit" .. GREY .. "  change the numbers in a window (or right-click the panel)" .. END,
    "/boar set kills 1000" .. GREY .. "  also: deaths, played (14h30m), xp, otherxp" .. END,
    "/boar add <name>" .. GREY .. "  count this creature as a boar;  " .. END .. "/boar remove <name>",
    "/boar list" .. GREY .. "  boars killed by kind;  " .. END .. "/boar levels" .. GREY .. "  when each level came" .. END,
    "/boar session" .. GREY .. "  start the session counters again;  " .. END .. "/boar lock" .. GREY .. "  lock or unlock the panel (Shift-drag works any time)" .. END,
    "/boar reset" .. GREY .. "  everything for this character back to zero" .. END,
  }
  for i = 1, table.getn(lines) do DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. lines[i]) end
end

local resetAsked = 0

local function Slash(msg)
  if not BC.char then return end
  msg = BC.Trim(msg)
  local _, _, word, rest = string.find(msg, "^(%S*)%s*(.-)$")
  word = string.lower(word or "")
  if word == "" then
    if BC.TogglePanel then BC.TogglePanel() end
  elseif word == "edit" then
    if BC.ShowEdit then BC.ShowEdit() end
  elseif word == "set" then
    local _, _, what, value = string.find(rest, "^(%S+)%s*(.-)$")
    SetValue(string.lower(what or ""), value or "")
  elseif word == "add" then
    rest = BC.Trim(rest)
    if rest == "" then rest = UnitName("target") or "" end
    if rest == "" then
      BC.Print("say the creature's name, or target it: /boar add Mottled Boar")
    else
      BC.char.extra[rest] = true
      BC.Print(WHITE .. rest .. END .. " counts as a boar from now on.")
    end
  elseif word == "remove" then
    rest = BC.Trim(rest)
    BC.char.extra[rest] = nil
    BC.char.names[rest] = nil
    BC.Print(WHITE .. rest .. END .. " no longer counts (unless its name has boar in it).")
  elseif word == "list" then
    ListNames()
  elseif word == "levels" then
    ListLevels()
  elseif word == "session" then
    BC.ResetSession()
  elseif word == "lock" or word == "unlock" or word == "move" then
    BC.db.locked = not BC.db.locked
    BC.Print("panel " .. (BC.db.locked and "locked." or "unlocked: drag it where you want, then /boar lock."))
    if BC.Refresh then BC.Refresh() end
  elseif word == "reset" then
    if GetTime() - resetAsked < 10 then
      BC.ResetAll()
    else
      resetAsked = GetTime()
      BC.Print(RED .. "this wipes every number for this character." .. END .. " Type " .. GOLD .. "/boar reset" .. END .. " again within 10 seconds to do it.")
    end
  else
    Help()
  end
end

SLASH_BOARTALLY1 = "/boar"
SLASH_BOARTALLY2 = "/boartally"
SlashCmdList["BOARTALLY"] = Slash

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
events:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    InitDB()
  elseif event == "PLAYER_LOGIN" then
    if not BC.char then InitDB() end
    BC.session.startedAt = GetTime()
    if BC.InitPanel then BC.InitPanel() end
    BC.Print("v" .. BC.VERSION .. " counting for " .. GOLD .. (UnitName("player") or "you") .. END .. ": " ..
      BC.Num(BC.char.kills) .. " boars so far. " .. GOLD .. "/boar" .. END .. " for the panel, " .. GOLD .. "/boar help" .. END .. " for commands.")
    -- Stealthboar had 1000 boars before this addon existed (993 on the old addon, a few more since). Everyone else starts at 0.
    if BC.char.kills == 0 and not BC.char.seeded and UnitName("player") == "Stealthboar" then
      BC.char.seeded = true
      BC.char.kills = 1000
      BC.Print("starting from the 1000 boars killed before this addon. Right-click the panel if that is off.")
    end
    OldAddonHint()
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
      GainXP(tonumber(xp), name)
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
    if BC.Refresh then BC.Refresh() end
  elseif event == "PLAYER_TARGET_CHANGED" then
    LearnTarget()
  elseif event == "PLAYER_XP_UPDATE" then
    if BC.Refresh then BC.Refresh() end
  end
end)

-- Time played ticks while you are logged in and not AFK.
events:SetScript("OnUpdate", function()
  if not BC.char then return end
  if UnitIsAFK and UnitIsAFK("player") then return end
  BC.char.played = BC.char.played + arg1
  BC.session.played = BC.session.played + arg1
end)
