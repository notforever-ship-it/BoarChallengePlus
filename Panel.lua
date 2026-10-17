-- Boar Challenge +: the panel on screen, and the settings window (your numbers, and what the panel shows).
--
-- Everything on the panel can be switched off: the title, the name, the headline, the time to level,
-- the XP bar and its numbers, the background, every number and every advice line. Numbers sit two to
-- a line, each in its own half with the label on the left and the number on the right, so nothing can
-- run into anything else. The panel closes up around what is left. Right-click it for the settings.

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WIDTH, PAD, GAP = 460, 12, 20
local CELL_W = (WIDTH - 2 * PAD - GAP) / 2   -- each number's half of a line
local LINE_H = 18                            -- a line of numbers
local TEXT_H = 15                            -- a line of advice
local ADV_X = 52                             -- advice text starts here, after its label
local ADV_W = WIDTH - ADV_X - PAD
local STRIPES = 12
local DASH = "-"

-- Everything the panel can show, in the order it shows it: group, key, label, on at first, what it is.
BC.ITEMS = {
  { g = "top", key = "title", label = "Title", on = true, tip = "The addon name, top left." },
  { g = "top", key = "name", label = "Character name", on = true, tip = "Your name, top right." },
  { g = "top", key = "head", label = "Boars to level", on = true, tip = "Big line: boars to next level. Counts rested XP." },
  { g = "top", key = "bigKills", label = "Boars killed (big)", on = true, tip = "All your boar kills, big, top right." },
  { g = "top", key = "bar", label = "XP bar", on = true, tip = "Your XP as a bar." },
  { g = "top", key = "barText", label = "Numbers on the bar", on = true, tip = "Level, XP and percent on the bar." },
  { g = "top", key = "barRested", label = "Rested on the bar", on = true, tip = "Rested XP in blue on the bar." },
  { g = "top", key = "bg", label = "Background", on = true, tip = "Dark background and border." },

  { g = "advice", key = "here", label = "Here", on = true, tip = "Boars in this zone, biggest first. Grey gives no XP." },
  { g = "advice", key = "now", label = "Now", on = true, tip = "Stay here until a level, or go somewhere better." },
  { g = "advice", key = "next", label = "Next", on = true, tip = "Where to go after that, and when." },
  { g = "advice", key = "later", label = "Later", on = false, tip = "The stops after that. Full road: /boar route." },

  { g = "chart", key = "week", label = "Week chart", on = false, tip = "Small bars under the panel: boars per day, last 7 days. Big one: /boar week." },

  -- the numbers, in colour groups: today gold, boars orange, XP purple, time blue, rested green, deaths red, records pink
  { g = "num", c = "day", key = "today", label = "Today", on = true, tip = "Boars today, and the day's goal. The bar fills toward the goal." },
  { g = "num", c = "day", key = "yesterday", label = "Yday", long = "Yesterday", on = true, tip = "Boars yesterday." },
  { g = "num", c = "day", key = "streak", label = "Streak", on = true, tip = "Boars in a row with no break, and your best in brackets. A wait over 90 seconds, eating, drinking, AFK or dying ends it." },
  { g = "num", c = "boars", key = "kills", label = "Boars killed", on = false, tip = "All your boar kills." },
  { g = "num", c = "boars", key = "bph", label = "Boars per hour", on = true, tip = "This session's boars per hour." },
  { g = "num", c = "boars", key = "sessionKills", label = "Boars this session", on = true, tip = "Boars since login or New session." },
  { g = "num", c = "boars", key = "thisLevel", label = "Boars this level", on = false, tip = "Boars since you reached this level." },
  { g = "num", c = "boars", key = "bphRecent", label = "Boars/h last 30 min", on = false, tip = "Boars per hour, last 30 minutes." },
  { g = "num", c = "boars", key = "to60", label = "Boars to 60", on = false, tip = "About how many boars are left to level 60, by the road. Counts rested XP." },
  { g = "num", c = "boars", key = "lastBoars", label = "Boars last level", on = false, tip = "Boars the last level took. Shows after 2 level-ups." },
  { g = "num", c = "xp", key = "xph", label = "XP per hour", on = true, tip = "This session's XP per hour." },
  { g = "num", c = "xp", key = "xpb", label = "XP per boar", on = true, tip = "What the next boar gives. Double while rested." },
  { g = "num", c = "xp", key = "xphRecent", label = "XP/h last 30 min", on = false, tip = "XP per hour, last 30 minutes." },
  { g = "num", c = "xp", key = "xpLeft", label = "XP to level", on = false, tip = "XP left to the next level." },
  { g = "num", c = "xp", key = "sessionXP", label = "XP this session", on = false, tip = "XP gained this session." },
  { g = "num", c = "xp", key = "best", label = "Best XP per hour", on = false, tip = "Your best session rate (after 10 minutes)." },
  { g = "num", c = "time", key = "pace", label = "Time to level", on = true, tip = "Time to next level at your recent pace." },
  { g = "num", c = "time", key = "played", label = "Time played", on = true, tip = "Time on the challenge. Stops while AFK." },
  { g = "num", c = "time", key = "sessionPlayed", label = "Played this session", on = false, tip = "Time played this session." },
  { g = "num", c = "time", key = "lastTime", label = "Time last level", on = false, tip = "Time the last level took. Shows after 2 level-ups." },
  { g = "num", c = "rested", key = "rested", label = "Rested XP", on = false, tip = "Rested XP left. Boars give double." },
  { g = "num", c = "rested", key = "restedBoars", label = "Boars on rested", on = false, tip = "Boars left on double XP." },
  { g = "num", c = "deaths", key = "deaths", label = "Deaths", on = false, tip = "How many times this character has died." },
  { g = "num", c = "records", key = "levelPace", label = "Best level pace", on = false, tip = "Most boars per hour over a whole level. Levels 5 and up the addon saw from start to end." },
  { g = "num", c = "records", key = "bestHour", label = "Best hour", on = false, tip = "Most boars in 60 minutes in a row." },
  { g = "num", c = "records", key = "bestDay", label = "Best day", on = false, tip = "Most boars in one day." },
}

-- Each group of numbers in its own colour: the label in the colour, the number a lighter shade of it.
local COLOURS = {
  day = { label = { 1.00, 0.84, 0.20 }, value = { 1.00, 0.95, 0.75 } },
  records = { label = { 1.00, 0.50, 0.80 }, value = { 1.00, 0.85, 0.92 } },
  week = { label = { 1.00, 0.84, 0.20 } },
  boars = { label = { 1.00, 0.66, 0.34 }, value = { 1.00, 0.87, 0.70 } },
  xp = { label = { 0.78, 0.58, 1.00 }, value = { 0.92, 0.84, 1.00 } },
  time = { label = { 0.45, 0.76, 1.00 }, value = { 0.80, 0.92, 1.00 } },
  rested = { label = { 0.35, 0.85, 0.60 }, value = { 0.76, 1.00, 0.86 } },
  deaths = { label = { 1.00, 0.42, 0.42 }, value = { 1.00, 0.80, 0.80 } },
  here = { label = { 0.45, 0.95, 0.45 } },
  now = { label = { 1.00, 0.82, 0.00 } },
  next = { label = { 0.45, 0.76, 1.00 } },
  later = { label = { 0.70, 0.70, 0.95 } },
}
BC.COLOURS = COLOURS

local function Rate(n)
  if n and n > 0 then return BC.Num(n) end
  return DASH
end

-- What each number shows.
local VALUE = {
  kills = function(st) return BC.Num(st.kills) end,
  xph = function(st) return Rate(st.xpHour) end,
  sessionKills = function(st) return BC.Num(st.sessionKills) end,
  bph = function(st) return Rate(st.killsHour) end,
  xpb = function(st) return Rate(st.xpPerBoar) end,
  played = function(st) return BC.Time(st.played) end,
  pace = function(st) return st.secondsToLevel and BC.Time(st.secondsToLevel) or DASH end,
  thisLevel = function(st) return BC.Num(st.thisLevelKills) end,
  xpLeft = function(st) return BC.Num(st.xpMax - st.xp) end,
  xphRecent = function(st) return Rate(st.xpHourRecent) end,
  bphRecent = function(st) return Rate(st.killsHourRecent) end,
  sessionXP = function(st) return BC.Num(st.sessionXP) end,
  sessionPlayed = function(st) return BC.Time(st.sessionPlayed) end,
  rested = function(st) return (st.rested > 0) and BC.Num(st.rested) or "none" end,
  restedBoars = function(st) return st.restedBoars and ("~" .. BC.Num(st.restedBoars)) or "none" end,
  lastBoars = function(st) return st.lastLevelFull and BC.Num(st.lastLevelKills) or DASH end,
  lastTime = function(st) return st.lastLevelFull and BC.Time(st.lastLevelTime) or DASH end,
  deaths = function(st) return tostring(st.deaths) end,
  to60 = function(st)
    local n = BC.BoarsTo60 and BC.BoarsTo60(st.level)
    return n and ("~" .. BC.Num(n)) or DASH
  end,
  best = function(st) return Rate(st.bestXPHour) end,
  today = function()
    local goal = BC.DayGoal()
    return BC.Num(BC.TodayKills()) .. (goal and (" / " .. BC.Num(goal)) or "")
  end,
  yesterday = function() return BC.Num(BC.YesterdayKills()) end,
  streak = function()
    local best = BC.char.records.streak.n
    return BC.Num(BC.StreakNow()) .. (best and ("  (" .. BC.Num(best) .. ")") or "")
  end,
  levelPace = function()
    local r = BC.char.records.pace
    return r.bph and (BC.Num(r.bph) .. "/h, lvl " .. r.level) or DASH
  end,
  bestHour = function() return BC.char.records.hour.n and BC.Num(BC.char.records.hour.n) or DASH end,
  bestDay = function() return BC.char.records.day.n and BC.Num(BC.char.records.day.n) or DASH end,
}

-- What each advice line says.
local ADVICE = {
  here = function(level) return BC.HereLine(level) end,
  now = function(level) return BC.NowLine(level) end,
  next = function(level) return BC.NextLine(level) end,
  later = function(level) return BC.LaterLine(level) end,
}

local panel, title, nameText, bigText, killsText, bar, restBar, barText, sep1, sep2, measure
local cells, advice, stripes = {}, {}, {}
local dayTrack, dayFill        -- the thin bar under Today, toward the day's goal
local weekLabel, mini = nil, {}  -- the small week chart under the panel: { bar, num } per day
local MINI_H = 18                -- its tallest bar
local elapsed = 0
local Draw, DrawWeek

local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 14,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function Strip(s)
  s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
  s = string.gsub(s, "|r", "")
  return s
end

-- How many lines a piece of advice needs at the panel's width.
local function Lines(text)
  measure:SetText(text)
  local w = measure:GetStringWidth()
  if not w or w <= 0 then w = string.len(Strip(text)) * 6.5 end
  local n = math.ceil(w * 1.06 / ADV_W)
  if n < 1 then n = 1 end
  if n > 3 then n = 3 end
  return n
end

local function Put(region, on, point, relPoint, x, y)
  region:ClearAllPoints()
  region:SetPoint(point, panel, relPoint, x, y)
  if on then region:Show() else region:Hide() end
end

local function Rule(tex, y)
  tex:ClearAllPoints()
  tex:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
  tex:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
  tex:SetHeight(1)
  tex:Show()
end

-- Puts everything that is switched on in place, top to bottom, and sizes the panel to fit.
function BC.Layout()
  if not panel or not BC.char then return end
  local show = BC.char.show
  panel:SetScale(BC.db.scale or 1)
  if show.bg then
    panel:SetBackdrop(BACKDROP)
    panel:SetBackdropColor(0.03, 0.03, 0.04, 0.92)
    panel:SetBackdropBorderColor(0.7, 0.5, 0.3, 1)
  else
    panel:SetBackdrop(nil)
  end

  local y = -10
  Put(title, show.title, "TOPLEFT", "TOPLEFT", PAD, y)
  Put(nameText, show.name, "TOPRIGHT", "TOPRIGHT", -PAD, y - 1)
  if show.title or show.name then y = y - 18 end
  Put(bigText, show.head, "TOPLEFT", "TOPLEFT", PAD, y)
  Put(killsText, show.bigKills, "TOPRIGHT", "TOPRIGHT", -PAD, y)
  if show.head or show.bigKills then y = y - 24 end
  if show.bar then
    restBar:ClearAllPoints()
    restBar:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    restBar:Show()
    bar:Show()
    y = y - 23
  else
    restBar:Hide()
    bar:Hide()
  end
  if show.barText then barText:Show() else barText:Hide() end

  -- the numbers, two to a line; each colour group starts a line of its own, shaded in its colour
  sep1:Hide()
  sep2:Hide()
  for i = 1, STRIPES do stripes[i]:Hide() end
  dayTrack:Hide()
  dayFill:Hide()
  local on = {}
  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    if it.g == "num" then
      local c = cells[it.key]
      if show[it.key] then
        table.insert(on, c)
      else
        c.label:Hide()
        c.value:Hide()
      end
    end
  end
  local n = table.getn(on)
  if n > 0 then
    if y < -10 then
      Rule(sep1, y - 1)
      y = y - 6
    end
    local col, row, group = 0, 0, nil
    for i = 1, n do
      local c = on[i]
      if group and c.group ~= group and col == 1 then
        col, row = 0, row + 1
      end
      group = c.group
      local x = PAD + col * (CELL_W + GAP)
      local ly = y - row * LINE_H
      Put(c.label, true, "TOPLEFT", "TOPLEFT", x, ly - 3)
      Put(c.value, true, "TOPRIGHT", "TOPLEFT", x + CELL_W, ly - 3)
      if c.key == "today" then
        dayTrack:ClearAllPoints()
        dayTrack:SetPoint("TOPLEFT", panel, "TOPLEFT", x, ly - 16)
        dayFill:ClearAllPoints()
        dayFill:SetPoint("TOPLEFT", panel, "TOPLEFT", x, ly - 16)
      end
      if col == 0 and stripes[row + 1] then
        local s = stripes[row + 1]
        local rgb = COLOURS[group].label
        s:SetTexture(rgb[1], rgb[2], rgb[3], math.mod(row, 2) == 0 and 0.10 or 0.05)
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD - 4, ly)
        s:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD + 4, ly)
        s:SetHeight(LINE_H)
        s:Show()
      end
      if col == 0 then
        col = 1
      else
        col, row = 0, row + 1
      end
    end
    if col == 1 then row = row + 1 end
    y = y - row * LINE_H
  end

  -- the advice lines
  local first = true
  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    if it.g == "advice" then
      local a = advice[it.key]
      if show[it.key] then
        if first then
          if y < -10 then
            Rule(sep2, y - 3)
            y = y - 9
          end
          first = false
        end
        local h = (a.lines or 1) * TEXT_H
        Put(a.label, true, "TOPLEFT", "TOPLEFT", PAD, y)
        Put(a.text, true, "TOPLEFT", "TOPLEFT", ADV_X, y)
        a.text:SetHeight(h)
        y = y - h - 4
      else
        a.label:Hide()
        a.text:Hide()
        a.last = nil
      end
    end
  end

  -- the small week chart: a label, then 7 thin bars with their numbers, today in gold
  weekLabel:Hide()
  for i = 1, 7 do
    mini[i].bar:Hide()
    mini[i].num:Hide()
  end
  if show.week then
    if y < -10 then y = y - 2 end
    Put(weekLabel, true, "TOPLEFT", "TOPLEFT", PAD, y - 6)
    local slot = ADV_W / 7
    for i = 1, 7 do
      local m = mini[i]
      m.bar:ClearAllPoints()
      m.bar:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", ADV_X + (i - 1) * slot, y - MINI_H - 4)
      m.num:ClearAllPoints()
      m.num:SetPoint("BOTTOMLEFT", m.bar, "BOTTOMRIGHT", 3, 0)
    end
    y = y - MINI_H - 8
  end

  local height = -y + 8
  if height < 24 then height = 24 end
  panel:SetHeight(height)
  Draw()
end

Draw = function()
  if not panel or not panel:IsShown() or not BC.char then return end
  local show = BC.char.show
  local st = BC.Stats()

  if show.head then
    if st.level >= 60 then
      bigText:SetText(GOLD .. "Level 60 on boars!" .. END)
    elseif st.boarsToLevel then
      bigText:SetText(WHITE .. BC.Num(st.boarsToLevel) .. END .. GOLD .. " boars to level " .. (st.level + 1) .. END)
    else
      bigText:SetText(GOLD .. "Kill a boar to start" .. END)
    end
  end
  if show.bigKills then
    killsText:SetText("|cffffe0b8" .. BC.Num(st.kills) .. END .. "|cffffa857 boars killed" .. END)
  end
  if show.bar then
    bar:SetMinMaxValues(0, st.xpMax)
    bar:SetValue(st.xp)
    restBar:SetMinMaxValues(0, st.xpMax)
    local rested = show.barRested and st.rested or 0
    restBar:SetValue(math.min(st.xp + rested, st.xpMax))
    if show.barText then
      local text = "Level " .. st.level .. "    " .. BC.Num(st.xp) .. " / " .. BC.Num(st.xpMax) .. " XP    " .. st.pct .. "%"
      if rested > 0 then text = text .. "    |cff9ccfff+" .. BC.Num(rested) .. " rested" .. END end
      barText:SetText(text)
    end
  end

  for key, c in pairs(cells) do
    if show[key] then c.value:SetText(VALUE[key](st)) end
  end
  if show.today then
    local goal, n = BC.DayGoal(), BC.TodayKills()
    if goal then
      local part = n / goal
      if part > 1 then part = 1 end
      dayTrack:Show()
      dayFill:SetWidth(math.max(1, CELL_W * part))
      if n >= goal then dayFill:SetTexture(0.30, 0.90, 0.35, 0.9) else dayFill:SetTexture(1.00, 0.80, 0.20, 0.9) end
      dayFill:Show()
    end
  end
  if show.week then
    local days = BC.WeekDays()
    local top = 1
    for i = 1, 7 do
      if days[i].n > top then top = days[i].n end
    end
    for i = 1, 7 do
      local m, d = mini[i], days[i]
      m.bar:SetHeight(math.max(1, MINI_H * d.n / top))
      if d.today then m.bar:SetTexture(1.00, 0.84, 0.20, 0.95) else m.bar:SetTexture(1.00, 0.66, 0.34, 0.55) end
      m.num:SetText((d.today and GOLD or GREY) .. d.n .. END)
      m.bar:Show()
      m.num:Show()
    end
  end

  -- advice changes with level, zone and XP; a line that grows or shrinks moves everything under it
  local relayout = false
  for key, a in pairs(advice) do
    if show[key] then
      local text = ADVICE[key](st.level)
      if text ~= a.last then
        a.last = text
        a.text:SetText(text)
        local lines = Lines(text)
        if lines ~= (a.lines or 1) then
          a.lines = lines
          relayout = true
        end
      end
    end
  end
  if relayout then BC.Layout() end
end

function BC.Refresh()
  Draw()
  if DrawWeek then DrawWeek() end
end

local function ShowTooltip()
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
  GameTooltip:SetText("Boar Challenge +")
  local level = UnitLevel("player") or 1
  local lines = BC.RouteLines and BC.RouteLines(level) or {}
  if table.getn(lines) > 0 then
    GameTooltip:AddLine("Your road from level " .. level .. ":", 1, 0.82, 0)
    for i = 1, table.getn(lines) do
      GameTooltip:AddDoubleLine(lines[i].left, lines[i].right, 1, 1, 1, 0.7, 0.7, 0.7)
    end
    GameTooltip:AddLine(" ")
  end
  GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Shift-drag: move", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("/boar route: map positions", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end

local function Build()
  panel = CreateFrame("Frame", "BoarChallengePlusPanel", UIParent)
  panel:SetWidth(WIDTH)
  panel:SetHeight(120)
  panel:SetFrameStrata("MEDIUM")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")

  local pos = BC.db.pos
  if type(pos) == "table" and pos.point then
    panel:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
  else
    panel:SetPoint("TOP", UIParent, "TOP", 0, -30)
  end
  panel:SetScript("OnDragStart", function()
    if not BC.db.locked or IsShiftKeyDown() then this:StartMoving() end
  end)
  panel:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    BC.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
  end)
  panel:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" and BC.ShowEdit then BC.ShowEdit() end
  end)
  panel:SetScript("OnEnter", ShowTooltip)
  panel:SetScript("OnLeave", function() GameTooltip:Hide() end)
  panel:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 1 then return end
    elapsed = 0
    Draw()
  end)

  title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetText("Boar Challenge +")
  nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nameText:SetTextColor(0.85, 0.74, 0.55)
  nameText:SetText(UnitName("player") or "")

  bigText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  killsText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

  -- the XP bar: rested XP is a blue bar underneath, reaching past your XP, like the game's own
  restBar = CreateFrame("StatusBar", nil, panel)
  restBar:SetWidth(WIDTH - 2 * PAD)
  restBar:SetHeight(17)
  restBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  restBar:SetStatusBarColor(0.15, 0.45, 0.95, 0.75)
  local bg = restBar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(restBar)
  bg:SetTexture(0, 0, 0, 0.6)
  bar = CreateFrame("StatusBar", nil, restBar)
  bar:SetAllPoints(restBar)
  bar:SetFrameLevel(restBar:GetFrameLevel() + 1)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.58, 0.1, 0.62)
  barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  barText:SetPoint("CENTER", bar, "CENTER", 0, 0)

  sep1 = panel:CreateTexture(nil, "ARTWORK")
  sep1:SetTexture(0.8, 0.6, 0.35, 0.35)
  sep2 = panel:CreateTexture(nil, "ARTWORK")
  sep2:SetTexture(0.8, 0.6, 0.35, 0.35)
  for i = 1, STRIPES do
    stripes[i] = panel:CreateTexture(nil, "BORDER")
    stripes[i]:SetTexture(1, 1, 1, 0.045)
    stripes[i]:Hide()
  end
  dayTrack = panel:CreateTexture(nil, "BORDER")
  dayTrack:SetTexture(1, 1, 1, 0.12)
  dayTrack:SetWidth(CELL_W)
  dayTrack:SetHeight(2)
  dayFill = panel:CreateTexture(nil, "ARTWORK")
  dayFill:SetHeight(2)
  weekLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  weekLabel:SetTextColor(COLOURS.week.label[1], COLOURS.week.label[2], COLOURS.week.label[3])
  weekLabel:SetText("Week")
  for i = 1, 7 do
    local m = {}
    m.bar = panel:CreateTexture(nil, "ARTWORK")
    m.bar:SetWidth(8)
    m.num = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mini[i] = m
  end
  measure = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  measure:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  measure:Hide()

  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    if it.g == "num" then
      local colour = COLOURS[it.c]
      local c = { group = it.c, key = it.key }
      c.label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      c.label:SetTextColor(colour.label[1], colour.label[2], colour.label[3])
      c.label:SetText(it.label)
      c.value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      c.value:SetTextColor(colour.value[1], colour.value[2], colour.value[3])
      c.value:SetJustifyH("RIGHT")
      cells[it.key] = c
    elseif it.g == "advice" then
      local colour = COLOURS[it.key].label
      local a = { lines = 1 }
      a.label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      a.label:SetTextColor(colour[1], colour[2], colour[3])
      a.label:SetText(it.label)
      a.text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      a.text:SetWidth(ADV_W)
      a.text:SetHeight(TEXT_H)
      a.text:SetJustifyH("LEFT")
      a.text:SetJustifyV("TOP")
      advice[it.key] = a
    end
  end

  if not BC.char.shown then panel:Hide() end
  BC.Layout()
end

function BC.InitPanel()
  if not panel then Build() end
  Draw()
end

function BC.TogglePanel()
  if not panel then Build() end
  if panel:IsShown() then
    panel:Hide()
    BC.char.shown = false
  else
    panel:Show()
    BC.char.shown = true
    BC.Layout()
  end
end

function BC.SetScale(s)
  s = tonumber(s) or 1
  if s < 0.6 then s = 0.6 end
  if s > 2 then s = 2 end
  s = math.floor(s * 20 + 0.5) / 20
  BC.db.scale = s
  if panel then
    panel:SetScale(s)
    -- A report: after the size buttons the whole panel went blank until /reload. The 1.12 client can lose what a
    -- frame draws when its scale changes, so put it back the way it is built at login: anchor it again, lay
    -- everything out again, and hide and show it so it is drawn from scratch.
    local pos = BC.db.pos
    panel:ClearAllPoints()
    if type(pos) == "table" and pos.point then
      panel:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
      panel:SetPoint("TOP", UIParent, "TOP", 0, -30)
    end
    BC.Layout()
    if panel:IsShown() then
      panel:Hide()
      panel:Show()
    end
    elapsed = 1
  end
  if BC.FillEdit then BC.FillEdit() end
end

------------------------------------------------------------------------------------------------------
-- The banner: big text above the middle of the screen that fades in and out. One at a time; the rest wait.
------------------------------------------------------------------------------------------------------

local banner, bannerLines
local queue = {}         -- { title, text, foot, secs } waiting their turn
local showing = nil      -- the one on screen, with its clock: .t
local FADE_IN, FADE_OUT, QUEUE_MAX = 0.4, 0.8, 5

local function BannerStart()
  showing = table.remove(queue, 1)
  if not showing then
    banner:Hide()
    return
  end
  showing.t = 0
  -- only the lines it has, stacked from the top
  local parts = { showing.title, showing.text, showing.foot }
  local above = nil
  for i = 1, 3 do
    local fs = bannerLines[i]
    fs:ClearAllPoints()
    if parts[i] and parts[i] ~= "" then
      fs:SetText(parts[i])
      if above then
        fs:SetPoint("TOP", above, "BOTTOM", 0, -4)
      else
        fs:SetPoint("TOP", banner, "TOP", 0, 0)
      end
      fs:Show()
      above = fs
    else
      fs:SetText("")
      fs:Hide()
    end
  end
  banner:SetAlpha(0)
  banner:Show()
end

local function BuildBanner()
  banner = CreateFrame("Frame", "BoarChallengePlusBanner", UIParent)
  banner:SetWidth(600)
  banner:SetHeight(90)
  banner:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  banner:SetFrameStrata("HIGH")
  banner:Hide()
  local sizes = { 26, 18, 15 }
  local colours = { { 1.00, 0.82, 0.00 }, { 1, 1, 1 }, { 1.00, 0.88, 0.72 } }
  bannerLines = {}
  for i = 1, 3 do
    local fs = banner:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, sizes[i], "OUTLINE")
    fs:SetTextColor(colours[i][1], colours[i][2], colours[i][3])
    fs:SetShadowOffset(1, -1)
    bannerLines[i] = fs
  end
  banner:SetScript("OnUpdate", function()
    if not showing then return end
    showing.t = showing.t + arg1
    local t, hold = showing.t, showing.secs
    if t < FADE_IN then
      banner:SetAlpha(t / FADE_IN)
    elseif t < FADE_IN + hold then
      banner:SetAlpha(1)
    elseif t < FADE_IN + hold + FADE_OUT then
      banner:SetAlpha(1 - (t - FADE_IN - hold) / FADE_OUT)
    else
      BannerStart()
    end
  end)
end

-- A banner: a big gold title, a white line, a small line under it. Any of them can be left out.
function BC.Banner(title, text, foot, secs)
  if (not title or title == "") and (not text or text == "") and (not foot or foot == "") then return end
  if not banner then BuildBanner() end
  if table.getn(queue) >= QUEUE_MAX then return end
  table.insert(queue, { title = title, text = text, foot = foot, secs = secs or 4 })
  if not showing then BannerStart() end
end

function BC.BannerBusy()
  return showing ~= nil or table.getn(queue) > 0
end

------------------------------------------------------------------------------------------------------
-- The week window: boars per day for the last 7 days, as bars, today in gold
------------------------------------------------------------------------------------------------------

local week, weekBars, weekTotal
local WEEK_W, WEEK_H, WEEK_BASE, WEEK_TALL = 380, 260, -186, 120

local function BuildWeek()
  week = CreateFrame("Frame", "BoarChallengePlusWeek", UIParent)
  week:SetWidth(WEEK_W)
  week:SetHeight(WEEK_H)
  week:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  week:SetFrameStrata("DIALOG")
  week:SetClampedToScreen(true)
  week:EnableMouse(true)
  week:SetMovable(true)
  week:RegisterForDrag("LeftButton")
  week:SetScript("OnDragStart", function() this:StartMoving() end)
  week:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  week:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  local solid = week:CreateTexture(nil, "BACKGROUND")
  solid:SetTexture(0.05, 0.05, 0.07, 1)
  solid:SetPoint("TOPLEFT", week, "TOPLEFT", 11, -11)
  solid:SetPoint("BOTTOMRIGHT", week, "BOTTOMRIGHT", -11, 11)
  week:Hide()
  table.insert(UISpecialFrames, "BoarChallengePlusWeek")

  local head = week:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  head:SetPoint("TOP", week, "TOP", 0, -18)
  head:SetText("Boars per day")
  local sub = week:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOP", head, "BOTTOM", 0, -3)
  sub:SetText(GREY .. "the last 7 days, today in gold" .. END)
  local close = CreateFrame("Button", "BoarChallengePlusWeekClose", week, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", week, "TOPRIGHT", -6, -6)
  local credit = week:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("BOTTOM", week, "BOTTOM", 0, 16)
  credit:SetText(GREY .. "Made by " .. END .. "|cffabd473stealthzi" .. END .. GREY .. "   v" .. BC.VERSION .. END)

  local base = week:CreateTexture(nil, "ARTWORK")
  base:SetTexture(1, 1, 1, 0.25)
  base:SetHeight(1)
  base:SetPoint("TOPLEFT", week, "TOPLEFT", 26, WEEK_BASE)
  base:SetPoint("TOPRIGHT", week, "TOPRIGHT", -26, WEEK_BASE)
  local slot = (WEEK_W - 60) / 7
  weekBars = {}
  for i = 1, 7 do
    local b = {}
    local mid = 30 + (i - 1) * slot + slot / 2
    b.bar = week:CreateTexture(nil, "ARTWORK")
    b.bar:SetWidth(26)
    b.bar:SetPoint("BOTTOM", week, "TOPLEFT", mid, WEEK_BASE)
    b.num = week:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    b.num:SetPoint("BOTTOM", b.bar, "TOP", 0, 2)
    b.name = week:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    b.name:SetPoint("TOP", week, "TOPLEFT", mid, WEEK_BASE - 4)
    weekBars[i] = b
  end
  weekTotal = week:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  weekTotal:SetPoint("TOP", week, "TOP", 0, WEEK_BASE - 24)
end

DrawWeek = function()
  if not week or not week:IsShown() or not BC.char then return end
  local days = BC.WeekDays()
  local top, total, best = 1, 0, nil
  for i = 1, 7 do
    total = total + days[i].n
    if days[i].n > top then top = days[i].n end
    if days[i].n > 0 and (not best or days[i].n >= best.n) then best = days[i] end
  end
  for i = 1, 7 do
    local b, d = weekBars[i], days[i]
    b.bar:SetHeight(math.max(1, WEEK_TALL * d.n / top))
    if d.today then b.bar:SetTexture(1.00, 0.84, 0.20, 0.95) else b.bar:SetTexture(1.00, 0.66, 0.34, 0.60) end
    b.num:SetText((d.today and GOLD or WHITE) .. BC.Num(d.n) .. END)
    b.name:SetText((d.today and GOLD or GREY) .. d.name .. END)
  end
  local text = "This week: " .. WHITE .. BC.Num(total) .. END .. " boars"
  if best then text = text .. GREY .. "   best: " .. END .. WHITE .. BC.Num(best.n) .. END .. GREY .. " on " .. best.name .. END end
  weekTotal:SetText(text)
end

function BC.ToggleWeek()
  if not week then BuildWeek() end
  if week:IsShown() then
    week:Hide()
  else
    week:Show()
    DrawWeek()
  end
end

------------------------------------------------------------------------------------------------------
-- The settings window: the numbers you already have, what the panel shows, and its size
------------------------------------------------------------------------------------------------------

local edit, sizeText, lockCheck, linesButton
local boxes, checks, optChecks = {}, {}, {}
-- the message switches, under Messages: key, label, what it does
local OPTS = {
  { key = "levelUp", label = "Level-up summary", tip = "A banner when you level: boars, time, and faster or slower than last level." },
  { key = "milestones", label = "Milestones", tip = "A banner at 100, 250, 500, 1,000 boars and on." },
  { key = "records", label = "Records", tip = "NEW RECORD! with a sound when you beat your best. /boar records lists them." },
  { key = "goal", label = "Daily goal", tip = "A banner when you beat yesterday and when you reach the day's goal. /boar goal 200 sets one." },
  { key = "deathNotes", label = "Death notes", tip = "Notes where you died and what hit you last. /boar deaths lists them." },
  { key = "streaks", label = "Streak messages", tip = "A banner at 5, 10, 25, 50 and 100 boars in a row." },
}
local LINES_NAME = { off = "Off", rare = "Rare", normal = "Normal" }
local LINES_NEXT = { off = "rare", rare = "normal", normal = "off" }
local filled = {}        -- what each box was filled with, so an untouched box changes nothing
local FIELDS = {
  { key = "kills", label = "Boars killed", tip = "All your boar kills." },
  { key = "deaths", label = "Deaths", tip = "How many times this character has died." },
  { key = "played", label = "Time played", tip = "Like 14h30m or 90m. Stops while AFK." },
  { key = "boarXP", label = "XP from boars", tip = "All XP boars have given." },
  { key = "otherXP", label = "XP from other things", tip = "XP from quests, exploring and the rest." },
}

local function Opaque(f)
  local solid = f:CreateTexture(nil, "BACKGROUND")
  solid:SetTexture(0.05, 0.05, 0.07, 1)
  solid:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -11)
  solid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -11, 11)
end

local function Explain(widget, head, tip)
  widget:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(head)
    GameTooltip:AddLine(tip, 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function BC.FillEdit()
  if not edit then return end
  local c = BC.char
  filled.kills, filled.deaths, filled.played = tostring(c.kills), tostring(c.deaths), BC.Time(c.played)
  filled.boarXP, filled.otherXP = tostring(c.boarXP), tostring(c.otherXP)
  for key, text in pairs(filled) do boxes[key]:SetText(text) end
  for key, check in pairs(checks) do check:SetChecked(c.show[key] and 1 or nil) end
  for key, check in pairs(optChecks) do check:SetChecked(c.opt[key] and 1 or nil) end
  linesButton:SetText("Funny lines: " .. (LINES_NAME[c.opt.lines] or "Rare"))
  sizeText:SetText("Size " .. math.floor((BC.db.scale or 1) * 100 + 0.5) .. "%")
  lockCheck:SetChecked(BC.db.locked and 1 or nil)
end

local function Changed(key)
  local text = BC.Trim(boxes[key]:GetText())
  if text == filled[key] then return nil end
  return text
end

local function Save()
  local c = BC.char
  local t = Changed("kills")
  if t and tonumber(t) then c.kills = math.floor(tonumber(t)) end
  t = Changed("deaths")
  if t and tonumber(t) then c.deaths = math.floor(tonumber(t)) end
  t = Changed("boarXP")
  if t and tonumber(t) then c.boarXP = math.floor(tonumber(t)) end
  t = Changed("otherXP")
  if t and tonumber(t) then c.otherXP = math.floor(tonumber(t)) end
  t = Changed("played")
  if t then
    local secs = BC.ParseTime(t)
    if secs then c.played = secs end
  end
  BC.Print("numbers saved: " .. BC.Num(c.kills) .. " boars, " .. c.deaths .. " deaths, " .. BC.Time(c.played) .. " played.")
  edit:Hide()
  Draw()
end

local function Button(name, text, width, tip)
  local b = CreateFrame("Button", name, edit, "UIPanelButtonTemplate")
  b:SetWidth(width)
  b:SetHeight(22)
  b:SetText(text)
  if tip then Explain(b, text, tip) end
  return b
end

local function Heading(text, x, y, small)
  local h = edit:CreateFontString(nil, "ARTWORK", small and "GameFontNormalSmall" or "GameFontNormal")
  h:SetPoint("TOPLEFT", edit, "TOPLEFT", x, y)
  h:SetText(text)
  return h
end

local resetClicks = 0

local function BuildEdit()
  edit = CreateFrame("Frame", "BoarChallengePlusEdit", UIParent)
  edit:SetWidth(600)
  edit:SetHeight(710)
  edit:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  edit:SetFrameStrata("DIALOG")
  edit:SetClampedToScreen(true)
  edit:EnableMouse(true)
  edit:SetMovable(true)
  edit:RegisterForDrag("LeftButton")
  edit:SetScript("OnDragStart", function() this:StartMoving() end)
  edit:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  Opaque(edit)
  edit:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  edit:Hide()
  table.insert(UISpecialFrames, "BoarChallengePlusEdit")

  local head = edit:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  head:SetPoint("TOP", edit, "TOP", 0, -18)
  head:SetText("Boar Challenge +")
  local sub = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOP", head, "BOTTOM", 0, -3)
  sub:SetText(GREY .. "Settings for " .. (UnitName("player") or "this character") .. END)
  local credit = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("BOTTOM", edit, "BOTTOM", 0, 48)
  credit:SetText(GREY .. "Made by " .. END .. "|cffabd473stealthzi" .. END .. GREY .. "   v" .. BC.VERSION .. END)
  local close = CreateFrame("Button", "BoarChallengePlusEditClose", edit, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -6, -6)

  -- your numbers, two to a line
  Heading("Your numbers", 24, -58)
  for i = 1, table.getn(FIELDS) do
    local f = FIELDS[i]
    local col = math.mod(i - 1, 2)
    local row = math.floor((i - 1) / 2)
    local x, y = 30 + col * 290, -80 - row * 26
    local label = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", edit, "TOPLEFT", x, y - 5)
    label:SetText(f.label)
    local box = CreateFrame("EditBox", "BoarChallengePlusEdit" .. f.key, edit, "InputBoxTemplate")
    box:SetWidth(120)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", edit, "TOPLEFT", x + 130, y)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() Save() end)
    Explain(box, f.label, f.tip)
    boxes[f.key] = box
  end

  -- what the panel shows: the top and the advice in the first column, the numbers in the other two
  Heading("On the panel", 24, -166)
  local hint = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", edit, "TOPLEFT", 120, -168)
  hint:SetText(GREY .. "boxes work at once" .. END)
  local defaults = Button("BoarChallengePlusEditDefaults", "Defaults", 90, "Panel back to how it starts.")
  defaults:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -24, -162)
  defaults:SetScript("OnClick", function()
    for i = 1, table.getn(BC.ITEMS) do BC.char.show[BC.ITEMS[i].key] = BC.ITEMS[i].on end
    BC.FillEdit()
    BC.Layout()
  end)

  Heading("Top", 24, -188, true)
  Heading("Advice and chart", 24, -364, true)
  Heading("Numbers", 214, -188, true)
  Heading("Today", 214, -430, true)
  Heading("Records", 404, -390, true)
  local topRow, adviceRow, numRow, dayRow, recordRow = 0, 0, 0, 0, 0
  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    local x, y
    if it.g == "top" then
      x, y = 22, -202 - topRow * 20
      topRow = topRow + 1
    elseif it.g == "advice" or it.g == "chart" then
      x, y = 22, -378 - adviceRow * 20
      adviceRow = adviceRow + 1
    elseif it.c == "day" then
      x, y = 212, -444 - dayRow * 20
      dayRow = dayRow + 1
    elseif it.c == "records" then
      x, y = 402, -404 - recordRow * 20
      recordRow = recordRow + 1
    else
      x, y = 212 + math.floor(numRow / 11) * 190, -202 - math.mod(numRow, 11) * 20
      numRow = numRow + 1
    end
    local name = "BoarChallengePlusShow" .. it.key
    local check = CreateFrame("CheckButton", name, edit, "UICheckButtonTemplate")
    check:SetWidth(20)
    check:SetHeight(20)
    check:SetPoint("TOPLEFT", edit, "TOPLEFT", x, y)
    getglobal(name .. "Text"):SetText(it.long or it.label)
    local tint = COLOURS[it.c or it.key]
    if tint then getglobal(name .. "Text"):SetTextColor(tint.label[1], tint.label[2], tint.label[3]) end
    check.key = it.key
    check:SetScript("OnClick", function()
      BC.char.show[this.key] = this:GetChecked() and true or false
      BC.Layout()
    end)
    Explain(check, it.label, it.tip)
    checks[it.key] = check
  end

  -- the messages: funny lines, banners, records, death notes
  Heading("Messages", 24, -512)
  local hint2 = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint2:SetPoint("TOPLEFT", edit, "TOPLEFT", 112, -514)
  hint2:SetText(GREY .. "banners on screen, and a line in chat" .. END)
  linesButton = Button("BoarChallengePlusEditLines", "Funny lines: Rare", 160)
  linesButton:SetPoint("TOPLEFT", edit, "TOPLEFT", 24, -532)
  Explain(linesButton, "Funny lines", "Click to change: Off, Rare (about every 15 min) or Normal (about every 7 min) while you kill. Also on level-ups, deaths, milestones and records.")
  linesButton:SetScript("OnClick", function()
    BC.SetLines(LINES_NEXT[BC.char.opt.lines] or "rare")
    BC.FillEdit()
  end)
  -- three to a line: after the button on the first, then two full lines
  local spots = { { 212, -533 }, { 402, -533 }, { 22, -558 }, { 212, -558 }, { 402, -558 }, { 22, -583 } }
  for i = 1, table.getn(OPTS) do
    local o = OPTS[i]
    local name = "BoarChallengePlusOpt" .. o.key
    local check = CreateFrame("CheckButton", name, edit, "UICheckButtonTemplate")
    check:SetWidth(20)
    check:SetHeight(20)
    check:SetPoint("TOPLEFT", edit, "TOPLEFT", spots[i][1], spots[i][2])
    getglobal(name .. "Text"):SetText(o.label)
    check.key = o.key
    check:SetScript("OnClick", function() BC.char.opt[this.key] = this:GetChecked() and true or false end)
    Explain(check, o.label, o.tip)
    optChecks[o.key] = check
  end
  local weekButton = Button("BoarChallengePlusEditWeek", "Week chart", 120, "Boars per day, last 7 days. Also /boar week.")
  weekButton:SetPoint("TOPLEFT", edit, "TOPLEFT", 212, -582)
  weekButton:SetScript("OnClick", function() BC.ToggleWeek() end)

  -- size and lock
  Heading("Size", 24, -620)
  local smaller = Button("BoarChallengePlusEditSmaller", "-", 26, "Smaller panel.")
  smaller:SetPoint("TOPLEFT", edit, "TOPLEFT", 64, -616)
  smaller:SetScript("OnClick", function() BC.SetScale((BC.db.scale or 1) - 0.1) end)
  sizeText = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sizeText:SetPoint("LEFT", smaller, "RIGHT", 8, 0)
  sizeText:SetWidth(70)
  local bigger = Button("BoarChallengePlusEditBigger", "+", 26, "Bigger panel.")
  bigger:SetPoint("LEFT", sizeText, "RIGHT", 8, 0)
  bigger:SetScript("OnClick", function() BC.SetScale((BC.db.scale or 1) + 0.1) end)
  lockCheck = CreateFrame("CheckButton", "BoarChallengePlusEditLock", edit, "UICheckButtonTemplate")
  lockCheck:SetWidth(20)
  lockCheck:SetHeight(20)
  lockCheck:SetPoint("TOPLEFT", edit, "TOPLEFT", 290, -617)
  getglobal("BoarChallengePlusEditLockText"):SetText("Locked (Shift-drag still moves it)")
  lockCheck:SetScript("OnClick", function() BC.db.locked = this:GetChecked() and true or false end)
  Explain(lockCheck, "Locked", "Only moves with Shift held down.")

  -- the buttons along the bottom
  local reset = Button("BoarChallengePlusEditReset", "Reset all", 100, "This character back to zero. Click twice.")
  reset:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 24, 18)
  reset:SetScript("OnClick", function()
    if GetTime() - resetClicks < 10 then
      BC.ResetAll()
      BC.FillEdit()
      BC.Layout()
      this:SetText("Reset all")
    else
      resetClicks = GetTime()
      this:SetText(RED .. "Click again" .. END)
    end
  end)
  local session = Button("BoarChallengePlusEditSession", "New session", 110, "Session counters start again. Totals stay.")
  session:SetPoint("LEFT", reset, "RIGHT", 8, 0)
  session:SetScript("OnClick", function() BC.ResetSession() end)
  local save = Button("BoarChallengePlusEditSave", "Save", 100, "Keeps the numbers you typed.")
  save:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -24, 18)
  save:SetScript("OnClick", Save)
  local shut = Button("BoarChallengePlusEditCancel", "Close", 90)
  shut:SetPoint("RIGHT", save, "LEFT", -8, 0)
  shut:SetScript("OnClick", function() edit:Hide() end)
end

function BC.ShowEdit()
  if not edit then BuildEdit() end
  BC.FillEdit()
  edit:Show()
end
