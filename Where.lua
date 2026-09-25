-- Boar Challenge +: where the boars are, and where to go next.
--
-- With pfQuest installed, every creature's level and spawn points come from its database, including
-- a server's own zones (pfQuest-turtle, pfQuest-octo). Without it, the list at the bottom is used,
-- taken from that database (vanilla plus Turtle WoW) on 2026-09-25.
--
-- The advice follows one rule: boars at your level or a few below, with as many spawns as possible,
-- and never grey ones (no XP). Dungeon boars and the other faction's home zones count for less.

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WORDS = { "boar", "goretusk", "agam'ar", "swine" }
local NOT = { "quilboar", "spearhide", "hedgehog", "spirit", "tamed", "armored", "horror" }
local DUNGEONS = { ["Razorfen Kraul"] = true, ["Razorfen Downs"] = true, ["The Deadmines"] = true }
local HOME = {   -- starting lands, where the other faction's guards make grinding a chore
  Durotar = "Horde", Mulgore = "Horde", ["Tirisfal Glades"] = "Horde",
  Teldrassil = "Alliance", ["Dun Morogh"] = "Alliance", ["Elwynn Forest"] = "Alliance", ["Thalassian Highlands"] = "Alliance",
}
local COLOUR = { grey = "|cff9d9d9d", green = "|cff40ff40", yellow = "|cffffff40", orange = "|cffff8000", red = "|cffff4040" }

local live = nil          -- rows from pfQuest's database, built once

-- Below this level a creature gives no XP. The game's own rule.
function BC.GreyLevel(level)
  if level <= 5 then return 0 end
  if level <= 39 then return level - 5 - math.floor(level / 10) end
  if level <= 59 then return level - 5 - math.floor(level / 5) end
  return 51
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

local function Coloured(word)
  return (COLOUR[word] or WHITE) .. word .. END
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

function BC.BoarRows()
  return LiveRows() or BC.BOARS
end

function BC.RowsAreLive()
  return LiveRows() ~= nil
end

------------------------------------------------------------------------------------------------------
-- Here and next
------------------------------------------------------------------------------------------------------

-- The boars in the zone you stand in: one line, and how good they are for you.
-- Returns text, status ("good", "green", "grey", "hard", "none").
function BC.Here(level)
  local zone = GetZoneText() or ""
  local rows = BC.BoarRows()
  local parts, best = {}, "none"
  local rank = { grey = 1, red = 2, orange = 3, green = 4, yellow = 5 }
  for i = 1, table.getn(rows) do
    local r = rows[i]
    if r[4] == zone then
      local colour = BC.LevelColour(r[3], level)
      table.insert(parts, r[1] .. " " .. r[2] .. "-" .. r[3] .. " " .. Coloured(colour))
      if best == "none" or (rank[colour] or 0) > (rank[best] or 0) then best = colour end
    end
  end
  if table.getn(parts) == 0 then return nil, "none" end
  local status = best
  if best == "yellow" then status = "good" end
  if best == "red" or best == "orange" then status = "hard" end
  return table.concat(parts, ", "), status
end

-- Zones worth going to at this level, best first: { zone, boars (text), spawns, area, x, y, note, score }.
function BC.NextSpots(level, skipZone)
  local rows = BC.BoarRows()
  local faction = UnitFactionGroup("player")
  local grey = BC.GreyLevel(level)
  local zones = {}
  for i = 1, table.getn(rows) do
    local r = rows[i]
    local name, lo, hi, zone, area, x, y, spawns = r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]
    if hi > grey and lo <= level + 2 and zone ~= skipZone then
      local fit
      if lo <= level and hi >= level - 3 then fit = 1
      elseif hi >= level - 5 and lo <= level then fit = 0.6
      elseif lo > level then fit = 0.45
      else fit = 0.25 end
      local count = spawns
      if count > 60 then count = 60 end
      local score = fit * count
      local note = nil
      if DUNGEONS[zone] then
        score = score * 0.4
        note = "dungeon"
      elseif HOME[zone] and HOME[zone] ~= faction then
        score = score * 0.5
        note = HOME[zone] .. " starting land"
      end
      local z = zones[zone]
      if not z then
        z = { zone = zone, score = 0, parts = {}, spawns = 0, note = note }
        zones[zone] = z
      end
      z.spawns = z.spawns + spawns
      if score > z.score then
        z.score = score
        z.area, z.x, z.y = area, x, y
        z.top = name .. " " .. lo .. "-" .. hi
      end
      table.insert(z.parts, { text = name .. " " .. lo .. "-" .. hi .. " " .. Coloured(BC.LevelColour(hi, level)), score = score })
    end
  end
  local list = {}
  for _, z in pairs(zones) do
    table.sort(z.parts, function(a, b) return a.score > b.score end)
    local texts = {}
    for i = 1, math.min(3, table.getn(z.parts)) do table.insert(texts, z.parts[i].text) end
    z.boars = table.concat(texts, ", ")
    table.insert(list, z)
  end
  table.sort(list, function(a, b) return a.score > b.score end)
  return list
end

-- One line for the panel: the best zone that isn't this one.
function BC.NextLine(level)
  local list = BC.NextSpots(level, GetZoneText())
  local z = list[1]
  if not z then return nil end
  local where = z.zone
  if z.area then where = where .. ", " .. z.area end
  return z.top .. " in " .. where .. " (" .. z.spawns .. " spawns)" .. (z.note and (", " .. z.note) or "")
end

function BC.PrintWhere()
  local level = UnitLevel("player") or 1
  local here, status = BC.Here(level)
  if here then
    local verdict = ({ good = "good for you", green = "easy for you, fine while they give XP", grey = RED .. "grey: no XP, time to move" .. END,
      hard = "above your level, careful" })[status] or ""
    BC.Print("boars in " .. WHITE .. (GetZoneText() or "?") .. END .. ": " .. here .. GREY .. " - " .. END .. verdict .. ".")
  else
    BC.Print("no boars known in " .. WHITE .. (GetZoneText() or "?") .. END .. ".")
  end
  local list = BC.NextSpots(level, nil)
  if table.getn(list) == 0 then
    BC.Print("nothing known at level " .. level .. ". Say " .. GOLD .. "/boar route" .. END .. " for the whole list.")
    return
  end
  BC.Print("best boars for level " .. level .. " (your level or a few below, most spawns first):")
  for i = 1, math.min(4, table.getn(list)) do
    local z = list[i]
    local where = z.zone
    if z.area then where = where .. " around " .. z.area end
    DEFAULT_CHAT_FRAME:AddMessage("  " .. WHITE .. where .. END .. GREY .. " (" .. z.x .. ", " .. z.y .. ")" .. END .. ": " .. z.boars ..
      GREY .. ", " .. z.spawns .. " spawns" .. (z.note and (", " .. z.note) or "") .. END)
  end
  BC.Print(GREY .. (BC.RowsAreLive() and "from pfQuest's database on this server." or "from the built-in list (vanilla and Turtle WoW); install pfQuest for this server's own.") .. END)
end

-- The whole road, low to high: every boar, its levels and zone.
function BC.PrintRoute()
  local level = UnitLevel("player") or 1
  local rows = {}
  for i = 1, table.getn(BC.BoarRows()) do table.insert(rows, BC.BoarRows()[i]) end
  table.sort(rows, function(a, b)
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[8] > b[8]
  end)
  BC.Print("every boar known, low to high (" .. table.getn(rows) .. "):")
  for i = 1, table.getn(rows) do
    local r = rows[i]
    local where = r[4]
    if r[5] then where = where .. ", " .. r[5] end
    DEFAULT_CHAT_FRAME:AddMessage("  " .. Coloured(BC.LevelColour(r[3], level)) .. GREY .. " " .. r[2] .. "-" .. r[3] .. END .. "  " .. WHITE .. r[1] .. END ..
      GREY .. "  " .. where .. " (" .. r[6] .. ", " .. r[7] .. "), " .. r[8] .. " spawns" .. (DUNGEONS[r[4]] and ", dungeon" or "") .. END)
  end
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
