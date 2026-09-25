-- Boar Challenge +: where the boars are, and the road from your level to 60.
--
-- With pfQuest installed, every creature's level and spawn points come from its database, including
-- a server's own zones (pfQuest-turtle, pfQuest-octo). Without it, the list at the bottom is used,
-- taken from that database (vanilla plus Turtle WoW) on 2026-09-25.
--
-- The road is worked out with the game's own XP rules. For every level to 60 it asks what each zone's
-- boars give you (boars 3-4 levels above you count half, 5 above not at all, grey ones nothing) and how
-- many of them there are. You stay where you are until a zone with bigger boars is clearly better, so
-- the road never sends you across the world for the same boars. Zones with boars as good as the stop
-- it picked are named as well ("Redridge works too").

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WORDS = { "boar", "goretusk", "agam'ar", "swine" }
local NOT = { "quilboar", "spearhide", "hedgehog", "spirit", "tamed", "armored", "horror" }
local DUNGEONS = { ["Razorfen Kraul"] = true, ["Razorfen Downs"] = true, ["The Deadmines"] = true }
local CITIES = {
  ["Stormwind City"] = true, Ironforge = true, Darnassus = true, ["Alah'Thalas"] = true,
  Orgrimmar = true, ["Thunder Bluff"] = true, Undercity = true,
}
local HOME = {   -- starting lands: the other faction's guards make grinding there a chore
  Durotar = "Horde", Mulgore = "Horde", ["Tirisfal Glades"] = "Horde",
  Teldrassil = "Alliance", ["Dun Morogh"] = "Alliance", ["Elwynn Forest"] = "Alliance", ["Thalassian Highlands"] = "Alliance",
}
local LANDS = {  -- the rest of each faction's own lands
  Westfall = "Alliance", ["Redridge Mountains"] = "Alliance", ["Loch Modan"] = "Alliance", Northwind = "Alliance",
  Darkshore = "Alliance", Duskwood = "Alliance",
  ["The Barrens"] = "Horde", ["Silverpine Forest"] = "Horde",
}
local COLOUR = { grey = "|cff9d9d9d", green = "|cff40ff40", yellow = "|cffffff40", orange = "|cffff8000", red = "|cffff4040" }

local STAY = 1.3    -- a zone with bigger boars must be this much better before the road moves you on
local ALSO = 0.55   -- zones with boars as big, and at least this good, are named as well

-- XP from each level to the next on the 1.12 client, levels 1 to 59.
local XP_TABLE = {
  400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
  8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
  25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
  50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
  95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
  153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800,
}

------------------------------------------------------------------------------------------------------
-- The game's XP rules
------------------------------------------------------------------------------------------------------

-- At or below this level a creature gives no XP.
function BC.GreyLevel(level)
  if level <= 5 then return 0 end
  if level <= 39 then return level - 5 - math.floor(level / 10) end
  if level <= 59 then return level - 1 - math.floor(level / 5) end
  return level - 9
end

-- grey / green / yellow / orange / red, as the game colours a creature of that level for you.
function BC.LevelColour(mobLevel, level)
  if mobLevel <= BC.GreyLevel(level) then return "grey" end
  local diff = mobLevel - level
  if diff >= 5 then return "red" end
  if diff >= 3 then return "orange" end
  if diff >= -2 then return "yellow" end
  return "green"
end

local function ZeroDiff(level)
  if level < 8 then return 5 end
  if level < 10 then return 6 end
  if level < 12 then return 7 end
  if level < 16 then return 8 end
  if level < 20 then return 9 end
  if level < 30 then return 11 end
  if level < 40 then return 12 end
  if level < 45 then return 13 end
  if level < 50 then return 14 end
  if level < 55 then return 15 end
  if level < 60 then return 16 end
  return 17
end

-- The XP one kill of a creature of mobLevel gives at your level, without rested XP.
function BC.KillXP(level, mobLevel)
  local base = level * 5 + 45
  if mobLevel >= level then
    local d = mobLevel - level
    if d > 4 then d = 4 end
    return math.floor((math.floor(base * (20 + d) / 10) + 1) / 2)
  end
  if mobLevel > BC.GreyLevel(level) then
    local zd = ZeroDiff(level)
    return math.floor(base * (zd + mobLevel - level) / zd)
  end
  return 0
end

-- What a boar of levels lo-hi is worth to you: its average XP, the risky ones counted down.
local function Worth(level, lo, hi)
  local sum = 0
  for v = lo, hi do
    local x = BC.KillXP(level, v)
    if v - level >= 5 then
      x = 0
    elseif v - level >= 3 then
      x = x * 0.5
    end
    sum = sum + x
  end
  return sum / (hi - lo + 1)
end


-- "Great Goretusk 16-17" in the colour the game gives it at that level.
local function BoarText(row, level)
  local c = level and COLOUR[BC.LevelColour(row[3], level)] or WHITE
  local levels = (row[2] == row[3]) and tostring(row[2]) or (row[2] .. "-" .. row[3])
  return c .. row[1] .. " " .. levels .. END
end

-- " at Three Corners (25, 61)"
local function Spot(row)
  local s = ""
  if row[5] then s = " at " .. row[5] end
  return s .. " (" .. row[6] .. ", " .. row[7] .. ")"
end

local function IsBoarName(name)
  local lower = string.lower(name)
  for i = 1, table.getn(NOT) do
    if string.find(lower, NOT[i], 1, true) then return false end
  end
  for i = 1, table.getn(WORDS) do
    if string.find(lower, WORDS[i], 1, true) then return true end
  end
  return false
end

------------------------------------------------------------------------------------------------------
-- Rows: { name, lo, hi, zone, area, x, y, spawns }
------------------------------------------------------------------------------------------------------

local live = nil          -- rows from pfQuest's database, built once

local function AreaAt(map, x, y)
  local zones, names = pfDB.zones.data, pfDB.zones.loc or pfDB.zones.enUS
  if not zones or not names then return nil end
  local best, bestSize = nil, nil
  for id, z in pairs(zones) do
    if type(z) == "table" and z[1] == map and names[id] and z[2] and z[3] and z[4] and z[5] then
      if math.abs(x - z[4]) <= z[2] / 2 and math.abs(y - z[5]) <= z[3] / 2 then
        local size = z[2] * z[3]
        if not bestSize or size < bestSize then best, bestSize = names[id], size end
      end
    end
  end
  return best
end

-- Every boar in pfQuest's database, one row per boar and zone. Built once and kept.
local function LiveRows()
  if live then return live end
  if not (pfDB and pfDB.units and pfDB.units.data and pfDB.zones) then return nil end
  local names = pfDB.units.loc or pfDB.units.enUS
  local zoneNames = pfDB.zones.loc or pfDB.zones.enUS
  if not names or not zoneNames then return nil end
  live = {}
  for id, name in pairs(names) do
    if type(name) == "string" and IsBoarName(name) then
      local u = pfDB.units.data[id]
      if u and type(u.coords) == "table" and u.coords[1] then
        local _, _, lo, hi = string.find(tostring(u.lvl or ""), "^(%d+)%-?(%d*)$")
        lo = tonumber(lo)
        hi = tonumber(hi) or lo
        if lo then
          local maps = {}
          for _, c in ipairs(u.coords) do
            local map = c[3]
            if map then
              local m = maps[map]
              if not m then
                m = { n = 0, sx = 0, sy = 0, pts = {} }
                maps[map] = m
              end
              m.n = m.n + 1
              m.sx, m.sy = m.sx + c[1], m.sy + c[2]
              table.insert(m.pts, c)
            end
          end
          for map, m in pairs(maps) do
            if m.n >= 3 then
              local mx, my = m.sx / m.n, m.sy / m.n
              local bx, by, best = mx, my, nil
              for _, p in ipairs(m.pts) do
                local d = (p[1] - mx) * (p[1] - mx) + (p[2] - my) * (p[2] - my)
                if not best or d < best then bx, by, best = p[1], p[2], d end
              end
              bx, by = math.floor(bx + 0.5), math.floor(by + 0.5)
              table.insert(live, { name, lo, hi, zoneNames[map] or ("map " .. map), AreaAt(map, bx, by) or false, bx, by, m.n })
            end
          end
        end
      end
    end
  end
  return live
end

local function EdgeOfMap(r)
  local m = r[6]
  if r[7] < m then m = r[7] end
  if 100 - r[6] < m then m = 100 - r[6] end
  if 100 - r[7] < m then m = 100 - r[7] end
  return m <= 10
end

local function FromMiddle(r)
  return (r[6] - 50) * (r[6] - 50) + (r[7] - 50) * (r[7] - 50)
end

-- pfQuest puts a creature on every map its spawn points fall on, so Loch Modan's boars also turn up
-- at the edge of Grim Reaches, and Hillsbrad's at the edge of Alterac. Keep each in the zone it is in.
local function Clean(rows)
  local out = {}
  for i = 1, table.getn(rows) do
    local r = rows[i]
    local keep = not CITIES[r[4]]
    if keep then
      for j = 1, table.getn(rows) do
        local o = rows[j]
        if j ~= i and o[1] == r[1] and not CITIES[o[4]] then
          if o[8] == r[8] and FromMiddle(o) < FromMiddle(r) then
            keep = false          -- the same spawns on two maps: the one nearer the middle is the real zone
          elseif EdgeOfMap(r) and o[8] > r[8] then
            keep = false          -- a few at the edge of this map, more elsewhere
          elseif r[8] < 6 and o[8] >= 3 * r[8] then
            keep = false          -- a stray handful
          end
        end
      end
    end
    if keep then table.insert(out, r) end
  end
  return out
end

local cleaned, cleanedFrom = nil, nil
local byZone, byZoneFrom = nil, nil

-- Every boar known, cleaned up, one row per boar and zone.
function BC.BoarRows()
  local src = LiveRows() or BC.BOARS
  if cleanedFrom ~= src then
    cleaned = Clean(src)
    cleanedFrom = src
  end
  return cleaned
end

function BC.RowsAreLive()
  return LiveRows() ~= nil
end

local function Zones()
  local rows = BC.BoarRows()
  if byZoneFrom ~= rows then
    byZone = {}
    for i = 1, table.getn(rows) do
      local z = rows[i][4]
      if not byZone[z] then byZone[z] = {} end
      table.insert(byZone[z], rows[i])
    end
    byZoneFrom = rows
  end
  return byZone
end

------------------------------------------------------------------------------------------------------
-- How good a zone is, and the road
------------------------------------------------------------------------------------------------------

-- More spawns means less waiting and running; past 40 it makes no odds.
local function Spread(n)
  if n > 40 then n = 40 end
  return math.sqrt(n / 40)
end

-- How good a zone is at this level: a score, the average XP a boar, and the boars worth killing
-- there, best first.
local function ZoneValue(level, zone, faction)
  local rows = Zones()[zone]
  if not rows then return 0, 0, nil end
  local list = {}
  for i = 1, table.getn(rows) do
    local xp = Worth(level, rows[i][2], rows[i][3])
    if xp > 0 then table.insert(list, { row = rows[i], xp = xp }) end
  end
  table.sort(list, function(a, b) return a.xp > b.xp end)
  local best, bestXP, used = 0, 0, nil
  local xsum, n = 0, 0
  for i = 1, table.getn(list) do
    xsum = xsum + list[i].xp * list[i].row[8]
    n = n + list[i].row[8]
    local v = xsum / n * Spread(n)
    if v > best then best, bestXP, used = v, xsum / n, i end
  end
  if not used then return 0, 0, nil end
  local set = {}
  for i = 1, used do set[i] = list[i].row end
  local mult = 1
  if DUNGEONS[zone] then
    mult = 0.4
  elseif HOME[zone] and HOME[zone] ~= faction then
    mult = 0.3
  elseif LANDS[zone] and LANDS[zone] ~= faction then
    mult = 0.5
  end
  return best * mult, bestXP, set
end

local planKey, planStages = nil, nil

-- The road from this level to 60, one stop per zone:
-- { zone, from, to, xp = { [level] = XP a boar }, rows = { boars killed there }, also = { zones as good } }
function BC.Plan(level, here)
  local faction = UnitFactionGroup("player") or ""
  local key = level .. "|" .. (here or "") .. "|" .. faction .. "|" .. tostring(BC.BoarRows())
  if planKey == key then return planStages end
  local zones = Zones()
  local stages, stage = {}, nil
  local cur = (here and zones[here]) and here or nil
  for L = level, 59 do
    local best, bv = nil, 0
    for z in pairs(zones) do
      local v = ZoneValue(L, z, faction)
      if v > bv then best, bv = z, v end
    end
    local cv, cset = 0, nil
    if cur then
      local _
      cv, _, cset = ZoneValue(L, cur, faction)
    end
    if cv <= 0 then
      cur = best
    elseif best and best ~= cur and bv > cv * STAY then
      local _, _, bset = ZoneValue(L, best, faction)
      if bset and cset and bset[1][3] > cset[1][3] then cur = best end   -- only for bigger boars
    end
    if not cur then break end
    local v, xp, set = ZoneValue(L, cur, faction)
    if not stage or stage.zone ~= cur then
      stage = { zone = cur, from = L, xp = {}, rows = {}, seen = {}, also = {} }
      table.insert(stages, stage)
      local top = set and set[1][3] or 0
      for z in pairs(zones) do
        if z ~= cur then
          local ov, _, oset = ZoneValue(L, z, faction)
          if oset and ov >= v * ALSO and oset[1][3] >= top then table.insert(stage.also, { zone = z, v = ov }) end
        end
      end
      table.sort(stage.also, function(a, b) return a.v > b.v end)
    end
    stage.to = L + 1
    stage.xp[L] = xp
    if set then
      for i = 1, table.getn(set) do
        if not stage.seen[set[i][1]] then
          stage.seen[set[i][1]] = true
          table.insert(stage.rows, set[i])
        end
      end
    end
  end
  planKey, planStages = key, stages
  return stages
end

-- About how many boars a stop takes, by the game's XP rules. Rested XP left comes off the first stop.
function BC.StageBoars(stage, level)
  local have, max = UnitXP("player") or 0, UnitXPMax("player") or 0
  local scale = 1
  if XP_TABLE[level] and max > 0 then scale = max / XP_TABLE[level] end   -- a server with its own XP table
  local total = 0
  for L = stage.from, stage.to - 1 do
    local need = (XP_TABLE[L] or 0) * scale
    if L == level then need = max - have end
    local xp = stage.xp[L]
    if xp and xp > 0 then total = total + need / xp end
  end
  if stage.from == level and stage.xp[level] and stage.xp[level] > 0 then
    local rested = (GetXPExhaustion and GetXPExhaustion()) or 0
    total = total - rested / stage.xp[level]
  end
  if total < 0 then total = 0 end
  return math.floor(total + 0.5)
end

-- "Redridge Mountains or Loch Modan"
local function AlsoText(stage, most)
  local names = {}
  for i = 1, math.min(most or 2, table.getn(stage.also)) do table.insert(names, stage.also[i].zone) end
  if table.getn(names) == 0 then return nil end
  return table.concat(names, " or ")
end

------------------------------------------------------------------------------------------------------
-- The advice lines
------------------------------------------------------------------------------------------------------

-- The boars in the zone you stand in, biggest first, coloured the way the game colours them for you.
function BC.HereLine(level)
  local zone = GetZoneText() or ""
  local rows = Zones()[zone]
  if not rows then return GREY .. "no boars in " .. (zone ~= "" and zone or "this zone") .. END end
  local list = {}
  for i = 1, table.getn(rows) do table.insert(list, rows[i]) end
  table.sort(list, function(a, b) return a[3] > b[3] end)
  local parts = {}
  for i = 1, math.min(3, table.getn(list)) do table.insert(parts, BoarText(list[i], level)) end
  local text = table.concat(parts, GREY .. ", " .. END)
  if BC.LevelColour(list[1][3], level) == "grey" then text = text .. RED .. "  no XP here" .. END end
  return text
end

-- What to do now: stay here until a level, or go somewhere.
function BC.NowLine(level)
  if level >= 60 then return GOLD .. "Level 60. The challenge is done!" .. END end
  local here = GetZoneText()
  local s = BC.Plan(level, here)[1]
  if not s then return GREY .. "no boars known for level " .. level .. END end
  local boars = BC.Num(BC.StageBoars(s, level))
  local also = AlsoText(s, 1)
  if s.zone == here then
    local text
    if s.to >= 60 then
      text = "Stay here to level 60, about " .. boars .. " boars"
    else
      text = "Stay here until level " .. GOLD .. s.to .. END .. ", about " .. boars .. " boars"
    end
    if also then text = text .. GREY .. " (or " .. also .. ")" .. END end
    return text
  end
  local r = s.rows[1]
  return "Go to " .. GOLD .. s.zone .. END .. ": " .. BoarText(r, level) .. GREY .. Spot(r) .. END
end

-- The stop after this one.
function BC.NextLine(level)
  if level >= 60 then return GREY .. "nothing: you made it" .. END end
  local stages = BC.Plan(level, GetZoneText())
  local s = stages[2]
  if not s then return GREY .. "nothing after this: it takes you to 60" .. END end
  local text = "At " .. GOLD .. s.from .. END .. ": " .. GOLD .. s.zone .. END .. ", " .. BoarText(s.rows[1], s.from)
  local also = AlsoText(s, 1)
  if also then text = text .. GREY .. " (or " .. also .. ")" .. END end
  return text
end

-- The stops after that, short.
function BC.LaterLine(level)
  local stages = BC.Plan(level, GetZoneText())
  local parts = {}
  for i = 3, math.min(5, table.getn(stages)) do
    table.insert(parts, GOLD .. stages[i].zone .. END .. " at " .. stages[i].from)
  end
  if table.getn(parts) == 0 then return GREY .. "nothing more after that" .. END end
  return table.concat(parts, ", ")
end

-- The whole road as { left, right } text pairs, for the panel's tooltip and /boar route.
function BC.RouteLines(level)
  local out = {}
  local stages = BC.Plan(level, GetZoneText())
  for i = 1, table.getn(stages) do
    local s = stages[i]
    local left = s.from .. " to " .. s.to .. "  " .. s.zone
    local right = "about " .. BC.Num(BC.StageBoars(s, level)) .. " boars"
    table.insert(out, { left = left, right = right, stage = s })
  end
  return out
end

------------------------------------------------------------------------------------------------------
-- Chat
------------------------------------------------------------------------------------------------------

function BC.PrintWhere()
  local level = UnitLevel("player") or 1
  BC.Print("boars in " .. WHITE .. (GetZoneText() or "?") .. END .. ": " .. BC.HereLine(level))
  DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. "Now" .. END .. "  " .. BC.NowLine(level))
  DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. "Next" .. END .. "  " .. BC.NextLine(level))
  DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. "Later" .. END .. "  " .. BC.LaterLine(level))
  BC.Print(GREY .. "/boar route shows every stop with its boars and map position. " ..
    (BC.RowsAreLive() and "From pfQuest's database on this server." or "From the built-in list; install pfQuest for this server's own.") .. END)
end

-- Every boar known, low to high, as it comes from the database.
local function PrintAll()
  local level = UnitLevel("player") or 1
  local rows = {}
  local src = BC.BoarRows()
  for i = 1, table.getn(src) do table.insert(rows, src[i]) end
  table.sort(rows, function(a, b)
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[8] > b[8]
  end)
  BC.Print("every boar known, low to high (" .. table.getn(rows) .. "):")
  for i = 1, table.getn(rows) do
    local r = rows[i]
    local where = r[4]
    if r[5] then where = where .. ", " .. r[5] end
    DEFAULT_CHAT_FRAME:AddMessage("  " .. BoarText(r, level) .. GREY .. "  " .. where .. " (" .. r[6] .. ", " .. r[7] .. "), " ..
      r[8] .. " spawns" .. (DUNGEONS[r[4]] and ", dungeon" or "") .. END)
  end
end

-- The road from your level: every stop, its boars, where they are and about how many to kill.
function BC.PrintRoute(all)
  if all then
    PrintAll()
    return
  end
  local level = UnitLevel("player") or 1
  local lines = BC.RouteLines(level)
  if table.getn(lines) == 0 then
    BC.Print("no road known from level " .. level .. ". " .. GOLD .. "/boar route all" .. END .. " lists every boar.")
    return
  end
  BC.Print("your road from level " .. level .. " (boar counts by the game's XP rules, rested XP counted for now):")
  for i = 1, table.getn(lines) do
    local s = lines[i].stage
    local names = {}
    for j = 1, math.min(3, table.getn(s.rows)) do table.insert(names, BoarText(s.rows[j], nil)) end
    local also = AlsoText(s, 2)
    DEFAULT_CHAT_FRAME:AddMessage("  " .. GOLD .. s.from .. " to " .. s.to .. END .. "  " .. WHITE .. s.zone .. END .. ": " ..
      table.concat(names, ", ") .. GREY .. Spot(s.rows[1]) .. ", " .. lines[i].right ..
      (also and (", or " .. also) or "") .. END)
  end
  BC.Print(GREY .. "/boar route all lists every boar known." .. END)
end

------------------------------------------------------------------------------------------------------
-- The built-in list: name, low level, high level, zone, area, x, y, spawns
------------------------------------------------------------------------------------------------------

BC.BOARS = {
  { "Mottled Boar", 1, 2, "Durotar", "Valley of Trials", 45, 65, 65 },
  { "Mottled Boar", 1, 2, "The Barrens", false, 67, 35, 3 },
  { "Young Thalassian Boar", 1, 2, "Eastern Plaguelands", false, 10, 23, 33 },
  { "Young Thalassian Boar", 1, 2, "Thalassian Highlands", "Brinthilien", 48, 81, 58 },
  { "Young Thistle Boar", 1, 2, "Teldrassil", "Shadowglen", 59, 43, 24 },
  { "Thalassian Boar", 2, 3, "Thalassian Highlands", false, 47, 73, 22 },
  { "Thistle Boar", 2, 3, "Teldrassil", "Shadowglen", 60, 37, 20 },
  { "Battleboar", 3, 4, "Mulgore", false, 56, 84, 46 },
  { "Small Crag Boar", 3, 3, "Dun Morogh", "Coldridge Valley", 23, 72, 56 },
  { "Small Crag Boar", 3, 3, "Northwind", false, 47, 5, 8 },
  { "Swine", 3, 3, "Durotar", false, 43, 16, 22 },
  { "Swine", 3, 3, "The Barrens", "The Mor'shan Rampart", 48, 9, 9 },
  { "Bristleback Battleboar", 4, 5, "Mulgore", false, 62, 79, 14 },
  { "Crag Boar", 5, 6, "Dun Morogh", false, 44, 59, 73 },
  { "Elder Thalassian Boar", 5, 7, "Eastern Plaguelands", false, 15, 12, 3 },
  { "Elder Thalassian Boar", 5, 7, "Alah'Thalas", false, 16, 97, 5 },
  { "Elder Thalassian Boar", 5, 7, "Thalassian Highlands", false, 48, 61, 51 },
  { "Stonetusk Boar", 5, 6, "Elwynn Forest", "Fargodeep Mine", 39, 79, 52 },
  { "Dire Mottled Boar", 6, 7, "Durotar", false, 48, 46, 136 },
  { "Large Crag Boar", 6, 7, "Dun Morogh", false, 48, 47, 42 },
  { "Elder Crag Boar", 7, 8, "Dun Morogh", "Gates of Ironforge", 45, 43, 87 },
  { "Elder Crag Boar", 7, 8, "Grim Reaches", false, 1, 70, 4 },
  { "Rockhide Boar", 7, 8, "Elwynn Forest", "Jerod's Landing", 58, 81, 90 },
  { "Elder Mottled Boar", 8, 9, "Durotar", "Thunder Ridge", 45, 27, 127 },
  { "Elder Mottled Boar", 8, 9, "The Barrens", false, 64, 17, 25 },
  { "Bristleback Boar", 9, 10, "The Barrens", false, 38, 35, 5 },
  { "Bristleback Boar", 9, 10, "Mulgore", "Red Rocks", 63, 15, 5 },
  { "Scarred Crag Boar", 9, 10, "Dun Morogh", "Helm's Bed Lake", 79, 50, 32 },
  { "Scarred Crag Boar", 9, 10, "Grim Reaches", false, 1, 71, 21 },
  { "Mountain Boar", 10, 11, "Loch Modan", false, 34, 32, 26 },
  { "Mountain Boar", 10, 11, "Grim Reaches", false, 16, 61, 26 },
  { "Young Goretusk", 12, 13, "Westfall", false, 50, 29, 46 },
  { "Cragtusk Boar", 14, 17, "Tirisfal Glades", false, 20, 62, 30 },
  { "Goretusk", 14, 15, "Westfall", "Moonbrook", 46, 55, 54 },
  { "Mangy Mountain Boar", 14, 15, "Loch Modan", "Ironband's Excavation Site", 65, 63, 41 },
  { "Mangy Mountain Boar", 14, 15, "Grim Reaches", false, 32, 77, 41 },
  { "Bramblethorn Boar", 15, 16, "The Barrens", false, 33, 18, 11 },
  { "Bramblethorn Boar", 15, 16, "Stonetalon Mountains", "Bramblethorn Pass", 77, 76, 12 },
  { "Elder Mountain Boar", 16, 17, "Loch Modan", false, 66, 40, 19 },
  { "Elder Mountain Boar", 16, 17, "Grim Reaches", false, 33, 65, 19 },
  { "Great Goretusk", 16, 17, "Westfall", "The Dead Acre", 58, 62, 17 },
  { "Great Goretusk", 16, 17, "Redridge Mountains", "Three Corners", 25, 61, 30 },
  { "Mesa Boar", 21, 23, "The Barrens", false, 43, 95, 3 },
  { "Mesa Boar", 21, 23, "Thousand Needles", false, 29, 28, 3 },
  { "Forest Boar", 23, 25, "Alterac Mountains", false, 46, 95, 5 },
  { "Forest Boar", 23, 25, "Hillsbrad Foothills", "Hillsbrad Fields", 43, 46, 12 },
  { "Forest Boar", 23, 25, "Gilneas", false, 94, 16, 5 },
  { "Agam'ar", 24, 25, "Razorfen Kraul", false, 44, 46, 15 },
  { "Raging Agam'ar", 25, 26, "Razorfen Kraul", false, 37, 55, 15 },
  { "Elder Forest Boar", 26, 27, "Hillsbrad Foothills", "Eastern Strand", 62, 67, 7 },
  { "Young Goldbristle Boar", 26, 28, "Stormwind City", false, 62, 11, 13 },
  { "Young Goldbristle Boar", 26, 28, "Northwind", "Merchant's Highroad", 50, 83, 13 },
  { "Rotting Agam'ar", 28, 28, "Razorfen Kraul", false, 49, 57, 3 },
  { "Burly Goldbristle Boar", 29, 30, "Northwind", false, 65, 50, 77 },
  { "Goldbristle Boar", 29, 30, "Northwind", false, 51, 56, 41 },
  { "Stonehide Boar", 32, 34, "Wetlands", false, 97, 64, 4 },
  { "Stonehide Boar", 32, 34, "Grim Reaches", false, 50, 44, 78 },
  { "Hightusk Boar", 33, 34, "Arathi Highlands", "Stromgarde Keep", 21, 53, 13 },
  { "Withered Battle Boar", 34, 34, "Razorfen Downs", false, 35, 17, 8 },
  { "Elder Stonehide Boar", 37, 38, "Grim Reaches", "Barleycrest Farmstead", 58, 39, 76 },
  { "Ashmane Boar", 48, 49, "Blasted Lands", "Rise of the Defiler", 52, 29, 34 },
  { "Helboar", 52, 53, "Blasted Lands", "The Dark Portal", 56, 49, 23 },
  { "Plagued Swine", 60, 60, "Eastern Plaguelands", "Terrordale", 16, 33, 17 },
  { "Plagued Swine", 60, 60, "Thalassian Highlands", false, 58, 98, 16 },
}
