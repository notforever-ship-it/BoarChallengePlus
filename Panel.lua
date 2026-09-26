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
  { g = "top", key = "title", label = "Title", on = true, tip = "Boar Challenge + at the top left." },
  { g = "top", key = "name", label = "Character name", on = true, tip = "Your character's name at the top right." },
  { g = "top", key = "head", label = "Boars to level", on = true, tip = "The big line: how many boars to the next level. Counts the rested XP you have: those boars give double." },
  { g = "top", key = "bigKills", label = "Boars killed (big)", on = true, tip = "Every boar this character has killed, big, at the right of the headline." },
  { g = "top", key = "bar", label = "XP bar", on = true, tip = "Your XP to the next level as a bar." },
  { g = "top", key = "barText", label = "Numbers on the bar", on = true, tip = "Level, XP and percent on the XP bar." },
  { g = "top", key = "barRested", label = "Rested on the bar", on = true, tip = "Rested XP as a blue stretch past your XP, like the game's own bar, and the amount on the bar." },
  { g = "top", key = "bg", label = "Background", on = true, tip = "The dark background and border. Off leaves the text on its own." },

  { g = "advice", key = "here", label = "Here", on = true, tip = "The boars in the zone you are in, biggest first, coloured the way the game colours them for you. Grey gives no XP." },
  { g = "advice", key = "now", label = "Now", on = true, tip = "Stay here until a level, or go somewhere better, and about how many boars that is. A zone with boars as good is named too." },
  { g = "advice", key = "next", label = "Next", on = true, tip = "Where to go after that, and at what level." },
  { g = "advice", key = "later", label = "Later", on = false, tip = "The stops after that. Hover the panel, or type /boar route, for the whole road." },

  -- the numbers, in colour groups: boars orange, XP purple, time blue, rested green, deaths red
  { g = "num", c = "boars", key = "kills", label = "Boars killed", on = false, tip = "Every boar this character has killed. It is also big in the headline." },
  { g = "num", c = "boars", key = "bph", label = "Boars per hour", on = true, tip = "This session's boars per hour." },
  { g = "num", c = "boars", key = "sessionKills", label = "Boars this session", on = true, tip = "Boars since you logged in, or since New session." },
  { g = "num", c = "boars", key = "thisLevel", label = "Boars this level", on = false, tip = "Boars killed since you reached this level." },
  { g = "num", c = "boars", key = "bphRecent", label = "Boars/h last 30 min", on = false, tip = "Boars per hour over the last 30 minutes only." },
  { g = "num", c = "boars", key = "lastBoars", label = "Boars last level", on = false, tip = "Boars the last level took. Shows after two level-ups with the addon." },
  { g = "num", c = "xp", key = "xph", label = "XP per hour", on = true, tip = "This session's XP per hour." },
  { g = "num", c = "xp", key = "xpb", label = "XP per boar", on = true, tip = "What the next boar gives: this session's average, doubled while rested XP lasts. Before the first kill of a session it is the last boar you killed." },
  { g = "num", c = "xp", key = "xphRecent", label = "XP/h last 30 min", on = false, tip = "XP per hour over the last 30 minutes only." },
  { g = "num", c = "xp", key = "xpLeft", label = "XP to level", on = false, tip = "XP still needed for the next level." },
  { g = "num", c = "xp", key = "sessionXP", label = "XP this session", on = false, tip = "All XP gained this session." },
  { g = "num", c = "xp", key = "best", label = "Best XP per hour", on = false, tip = "Your best session rate, counted after 10 minutes of a session." },
  { g = "num", c = "xp", key = "boarShare", label = "XP from boars", on = false, tip = "How much of all your XP came from boars." },
  { g = "num", c = "time", key = "pace", label = "Time to level", on = true, tip = "How long the next level takes at your pace: the last 30 minutes, or the pace you left with last time until then." },
  { g = "num", c = "time", key = "played", label = "Time played", on = true, tip = "Time on the challenge. It stops while you are AFK." },
  { g = "num", c = "time", key = "sessionPlayed", label = "Played this session", on = false, tip = "Time played this session." },
  { g = "num", c = "time", key = "lastTime", label = "Time last level", on = false, tip = "Time the last level took. Shows after two level-ups with the addon." },
  { g = "num", c = "rested", key = "rested", label = "Rested XP", on = false, tip = "Rested XP left. Boars give double until it runs out." },
  { g = "num", c = "rested", key = "restedBoars", label = "Boars on rested", on = false, tip = "About how many more boars get double XP from rested." },
  { g = "num", c = "deaths", key = "deaths", label = "Deaths", on = false, tip = "How many times this character has died." },
}

-- Each group of numbers in its own colour: the label in the colour, the number a lighter shade of it.
local COLOURS = {
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
  boarShare = function(st) return st.boarShare and (st.boarShare .. "%") or DASH end,
  best = function(st) return Rate(st.bestXPHour) end,
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
local elapsed = 0
local Draw

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
  GameTooltip:AddLine("Right-click: your numbers, and what the panel shows.", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Shift-drag to move. /boar route gives map positions.", 0.8, 0.8, 0.8)
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
  measure = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  measure:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  measure:Hide()

  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    if it.g == "num" then
      local colour = COLOURS[it.c]
      local c = { group = it.c }
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
  if s < 0.6 then s = 0.6 end
  if s > 2 then s = 2 end
  s = math.floor(s * 20 + 0.5) / 20
  BC.db.scale = s
  if panel then panel:SetScale(s) end
  if BC.FillEdit then BC.FillEdit() end
end

------------------------------------------------------------------------------------------------------
-- The settings window: the numbers you already have, what the panel shows, and its size
------------------------------------------------------------------------------------------------------

local edit, sizeText, lockCheck
local boxes, checks = {}, {}
local filled = {}        -- what each box was filled with, so an untouched box changes nothing
local FIELDS = {
  { key = "kills", label = "Boars killed", tip = "Every boar this character has ever killed." },
  { key = "deaths", label = "Deaths", tip = "How many times this character has died." },
  { key = "played", label = "Time played", tip = "Time on the challenge, like 14h30m or 90m. Counts while you are logged in and not AFK." },
  { key = "boarXP", label = "XP from boars", tip = "All the experience boars have given, for the boar share and XP per boar." },
  { key = "otherXP", label = "XP from other things", tip = "Experience from quests, exploring and anything that isn't a boar." },
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
  edit:SetHeight(520)
  edit:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
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
  hint:SetText(GREY .. "each box works as soon as you click it" .. END)
  local defaults = Button("BoarChallengePlusEditDefaults", "Defaults", 90, "Puts the panel back to what it shows at first.")
  defaults:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -24, -162)
  defaults:SetScript("OnClick", function()
    for i = 1, table.getn(BC.ITEMS) do BC.char.show[BC.ITEMS[i].key] = BC.ITEMS[i].on end
    BC.FillEdit()
    BC.Layout()
  end)

  Heading("Top", 24, -188, true)
  Heading("Advice", 24, -352, true)
  Heading("Numbers", 214, -188, true)
  local topRow, adviceRow, numRow = 0, 0, 0
  for i = 1, table.getn(BC.ITEMS) do
    local it = BC.ITEMS[i]
    local x, y
    if it.g == "top" then
      x, y = 22, -202 - topRow * 20
      topRow = topRow + 1
    elseif it.g == "advice" then
      x, y = 22, -366 - adviceRow * 20
      adviceRow = adviceRow + 1
    else
      x, y = 212 + math.floor(numRow / 10) * 190, -202 - math.mod(numRow, 10) * 20
      numRow = numRow + 1
    end
    local name = "BoarChallengePlusShow" .. it.key
    local check = CreateFrame("CheckButton", name, edit, "UICheckButtonTemplate")
    check:SetWidth(20)
    check:SetHeight(20)
    check:SetPoint("TOPLEFT", edit, "TOPLEFT", x, y)
    getglobal(name .. "Text"):SetText(it.label)
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

  -- size and lock
  Heading("Size", 24, -452)
  local smaller = Button("BoarChallengePlusEditSmaller", "-", 26, "Makes the panel smaller.")
  smaller:SetPoint("TOPLEFT", edit, "TOPLEFT", 64, -448)
  smaller:SetScript("OnClick", function() BC.SetScale((BC.db.scale or 1) - 0.1) end)
  sizeText = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sizeText:SetPoint("LEFT", smaller, "RIGHT", 8, 0)
  sizeText:SetWidth(70)
  local bigger = Button("BoarChallengePlusEditBigger", "+", 26, "Makes the panel bigger.")
  bigger:SetPoint("LEFT", sizeText, "RIGHT", 8, 0)
  bigger:SetScript("OnClick", function() BC.SetScale((BC.db.scale or 1) + 0.1) end)
  lockCheck = CreateFrame("CheckButton", "BoarChallengePlusEditLock", edit, "UICheckButtonTemplate")
  lockCheck:SetWidth(20)
  lockCheck:SetHeight(20)
  lockCheck:SetPoint("TOPLEFT", edit, "TOPLEFT", 290, -449)
  getglobal("BoarChallengePlusEditLockText"):SetText("Locked (Shift-drag still moves it)")
  lockCheck:SetScript("OnClick", function() BC.db.locked = this:GetChecked() and true or false end)
  Explain(lockCheck, "Locked", "When locked, the panel only moves with Shift held down, so you can't drag it by accident.")

  -- the buttons along the bottom
  local reset = Button("BoarChallengePlusEditReset", "Reset all", 100, "Every number for this character back to zero. Click twice.")
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
  local session = Button("BoarChallengePlusEditSession", "New session", 110, "Starts this session's counters (boars this session, XP per hour) again. The totals stay.")
  session:SetPoint("LEFT", reset, "RIGHT", 8, 0)
  session:SetScript("OnClick", function() BC.ResetSession() end)
  local save = Button("BoarChallengePlusEditSave", "Save", 100, "Keeps the numbers you typed. The panel boxes work as soon as you click them.")
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
