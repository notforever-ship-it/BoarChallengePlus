-- Boar Challenge +: the panel on screen, and the window for changing the numbers and the rows.
--
-- The panel is wide rather than tall: the headline (boars to the next level) and the XP bar across
-- the top, then the number rows in two columns, then the "here" and "next" lines across the bottom.
-- Every row can be switched off; the panel closes up around what is left.

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WIDTH = 444
local COLS = { 12, 228 }          -- x of the two columns of number rows
local VALUE_W, NOTE_W = 104, 100  -- the value ends at col + VALUE_W, the note starts just after
local ROW_H, WIDE_H = 15, 26
local ROWS_Y = -68                -- where the rows start, under the bar

-- Every row the panel can show, in the order it shows them. "num" rows take half a line.
BC.ROWS = {
  { key = "kills", label = "Boars killed", kind = "num", tip = "Every boar this character has killed, and this session's." },
  { key = "xph", label = "XP per hour", kind = "num", tip = "This session's rate, with the last 30 minutes after it." },
  { key = "bph", label = "Boars per hour", kind = "num", tip = "This session's rate, with the last 30 minutes after it." },
  { key = "xpb", label = "XP per boar", kind = "num", tip = "What a boar gives on average this session." },
  { key = "played", label = "Played", kind = "num", tip = "Time on the challenge, and this session. Not counted while AFK." },
  { key = "deaths", label = "Deaths", kind = "num", tip = "Deaths, and how much of your XP came from boars." },
  { key = "thisLevel", label = "Boars this level", kind = "num", tip = "Boars killed since you reached this level." },
  { key = "lastLevel", label = "Last level took", kind = "num", tip = "Boars and time from the level before to this one." },
  { key = "rested", label = "Rested XP", kind = "num", tip = "Rested XP left (boars give double until it runs out), and how many boars that covers." },
  { key = "best", label = "Best XP per hour", kind = "num", tip = "The best session rate you have had, after 10 minutes of a session." },
  { key = "sessionXP", label = "XP this session", kind = "num", tip = "All XP gained this session." },
  { key = "here", label = "Here", kind = "wide", tip = "The boars in the zone you are in, coloured by level like the game does." },
  { key = "next", label = "Next", kind = "wide", tip = "The best zone for your level that is not this one: boars at your level or a few below, most spawns. /boar where says more." },
}

local panel, bigText, paceText, bar, barText
local rows = {}
local elapsed = 0
local cache = { key = nil, here = nil, next = nil }

local function Coloured(text, colour)
  return (colour or WHITE) .. text .. END
end

-- What each row says right now: value and note for number rows, one text for wide rows.
local function Content(key, st)
  if key == "kills" then
    return BC.Num(st.kills), (st.sessionKills > 0) and ("+" .. BC.Num(st.sessionKills) .. " this session") or "none this session"
  elseif key == "xph" then
    return BC.Num(st.xpHour), (st.xpHourRecent > 0) and ("last 30 min " .. BC.Num(st.xpHourRecent)) or nil
  elseif key == "bph" then
    return BC.Num(st.killsHour), (st.killsHourRecent > 0) and ("last 30 min " .. BC.Num(st.killsHourRecent)) or nil
  elseif key == "xpb" then
    return (st.xpPerBoar > 0) and BC.Num(st.xpPerBoar) or "?", nil
  elseif key == "played" then
    return BC.Time(st.played), "this session " .. BC.Time(st.sessionPlayed)
  elseif key == "deaths" then
    return tostring(st.deaths), st.boarShare and (st.boarShare .. "% of XP is boar") or nil
  elseif key == "thisLevel" then
    return BC.Num(st.thisLevelKills), "at level " .. st.level
  elseif key == "lastLevel" then
    if not st.lastLevel then return "?", "no level-up seen yet" end
    if not st.lastLevelFull then return "level " .. st.lastLevel, "reached at " .. BC.Num(st.lastLevelKills) .. " boars" end
    return BC.Num(st.lastLevelKills) .. " boars", BC.Time(st.lastLevelTime) .. " to level " .. st.lastLevel
  elseif key == "rested" then
    if st.rested <= 0 then return "none", "rest in an inn or city" end
    return BC.Num(st.rested), st.restedBoars and ("double XP for ~" .. BC.Num(st.restedBoars) .. " boars") or nil
  elseif key == "best" then
    return (st.bestXPHour > 0) and BC.Num(st.bestXPHour) or "?", "best session rate so far"
  elseif key == "sessionXP" then
    return BC.Num(st.sessionXP), nil
  elseif key == "here" or key == "next" then
    -- worked out again only when the level or the zone changes
    local ck = st.level .. "|" .. (GetZoneText() or "")
    if cache.key ~= ck then
      cache.key = ck
      local here, status = BC.Here(st.level)
      if here then
        local verdict = ({ good = "", green = "", grey = RED .. " - no XP, move on" .. END, hard = GREY .. " - above you" .. END })[status] or ""
        cache.here = here .. verdict
      else
        cache.here = GREY .. "no boars known in " .. (GetZoneText() or "this zone") .. END
      end
      local nxt = BC.NextLine(st.level)
      cache.next = nxt and (WHITE .. nxt .. END) or (GREY .. "nothing known for level " .. st.level .. END)
    end
    if key == "here" then return cache.here end
    return cache.next
  end
  return "", nil
end

-- Puts the switched-on rows in place, two number rows to a line, and sizes the panel to fit.
function BC.Layout()
  if not panel or not BC.char then return end
  local y, col = ROWS_Y, 1
  for i = 1, table.getn(BC.ROWS) do
    local def, r = BC.ROWS[i], rows[BC.ROWS[i].key]
    if BC.char.show[def.key] then
      r.on = true
      if def.kind == "num" then
        local x = COLS[col]
        r.label:ClearAllPoints()
        r.label:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y - 2)
        r.value:ClearAllPoints()
        r.value:SetPoint("TOPRIGHT", panel, "TOPLEFT", x + VALUE_W, y)
        r.note:ClearAllPoints()
        r.note:SetPoint("TOPLEFT", panel, "TOPLEFT", x + VALUE_W + 6, y - 2)
        r.label:Show()
        r.value:Show()
        r.note:Show()
        if col == 1 then col = 2 else col = 1; y = y - ROW_H end
      else
        if col == 2 then col = 1; y = y - ROW_H end
        r.label:ClearAllPoints()
        r.label:SetPoint("TOPLEFT", panel, "TOPLEFT", COLS[1], y - 2)
        r.value:ClearAllPoints()
        r.value:SetPoint("TOPLEFT", panel, "TOPLEFT", COLS[1] + 36, y - 2)
        r.label:Show()
        r.value:Show()
        r.note:Hide()
        y = y - WIDE_H
      end
    else
      r.on = false
      r.label:Hide()
      r.value:Hide()
      r.note:Hide()
    end
  end
  if col == 2 then y = y - ROW_H end
  panel:SetHeight(-y + 8)
  BC.Refresh()
end

local function Draw()
  if not panel or not panel:IsShown() or not BC.char then return end
  local st = BC.Stats()

  if st.boarsToLevel then
    bigText:SetText(WHITE .. BC.Num(st.boarsToLevel) .. END .. GOLD .. " boars to level " .. (st.level + 1) .. END)
  else
    bigText:SetText(GOLD .. "Kill a boar to see how many to level " .. (st.level + 1) .. END)
  end
  if st.secondsToLevel then
    paceText:SetText(GREY .. "about " .. BC.Time(st.secondsToLevel) .. " at this pace" .. END)
  else
    paceText:SetText(GREY .. "the pace shows after a few minutes" .. END)
  end
  bar:SetMinMaxValues(0, st.xpMax)
  bar:SetValue(st.xp)
  barText:SetText("Level " .. st.level .. "   " .. BC.Num(st.xp) .. " / " .. BC.Num(st.xpMax) .. " XP   " .. st.pct .. "%")

  for i = 1, table.getn(BC.ROWS) do
    local def, r = BC.ROWS[i], rows[BC.ROWS[i].key]
    if r.on then
      local value, note = Content(def.key, st)
      if def.kind == "num" then
        r.value:SetText(value)
        r.note:SetText(note and (GREY .. note .. END) or "")
      else
        r.value:SetText(value)
      end
    end
  end
end

function BC.Refresh()
  Draw()
end

local function Build()
  panel = CreateFrame("Frame", "BoarChallengePlusPanel", UIParent)
  panel:SetWidth(WIDTH)
  panel:SetHeight(200)
  panel:SetFrameStrata("MEDIUM")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  panel:SetBackdropColor(0.04, 0.03, 0.03, 0.9)
  panel:SetBackdropBorderColor(0.7, 0.5, 0.3, 1)

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
  panel:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Boar Challenge +")
    GameTooltip:AddLine("Right-click to change the numbers and pick the rows. Shift-drag to move. /boar hides it.", 0.8, 0.8, 0.8, 1)
    GameTooltip:AddLine("/boar where lists the boars in this zone and the best zones for your level.", 0.8, 0.8, 0.8, 1)
    GameTooltip:Show()
  end)
  panel:SetScript("OnLeave", function() GameTooltip:Hide() end)
  panel:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 1 then return end
    elapsed = 0
    Draw()
  end)

  -- Title left, character right
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -9)
  title:SetText(GOLD .. "Boar Challenge +" .. END)
  local nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nameText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -11)
  nameText:SetText(GREY .. (UnitName("player") or "") .. END)

  -- The headline and its pace, on one line
  bigText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  bigText:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -26)
  paceText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  paceText:SetPoint("LEFT", bigText, "RIGHT", 10, -1)

  -- XP bar across the panel, in the game's XP purple
  bar = CreateFrame("StatusBar", nil, panel)
  bar:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
  bar:SetWidth(WIDTH - 24)
  bar:SetHeight(13)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.58, 0.1, 0.62)
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(bar)
  bg:SetTexture(0, 0, 0, 0.6)
  barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  barText:SetPoint("CENTER", bar, "CENTER", 0, 0)

  for i = 1, table.getn(BC.ROWS) do
    local def = BC.ROWS[i]
    local r = {}
    r.label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.label:SetText(GREY .. def.label .. END)
    if def.kind == "num" then
      r.value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.value:SetJustifyH("RIGHT")
      r.note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.note:SetWidth(NOTE_W)
      r.note:SetJustifyH("LEFT")
    else
      r.value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.value:SetWidth(WIDTH - COLS[1] - 36 - 12)
      r.value:SetHeight(WIDE_H - 2)
      r.value:SetJustifyH("LEFT")
      r.value:SetJustifyV("TOP")
      r.note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    end
    rows[def.key] = r
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
    Draw()
  end
end

------------------------------------------------------------------------------------------------------
-- The edit window: the numbers you already have, and which rows to show
------------------------------------------------------------------------------------------------------

local edit
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

local function Explain(widget, title, tip)
  widget:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(tip, 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Fill()
  local c = BC.char
  filled.kills, filled.deaths, filled.played = tostring(c.kills), tostring(c.deaths), BC.Time(c.played)
  filled.boarXP, filled.otherXP = tostring(c.boarXP), tostring(c.otherXP)
  for key, text in pairs(filled) do boxes[key]:SetText(text) end
  for key, check in pairs(checks) do check:SetChecked(c.show[key] and 1 or nil) end
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
    local lower = string.lower(t)
    local _, _, h, m = string.find(lower, "^(%d+)h%s*(%d*)m?$")
    local _, _, mins = string.find(lower, "^(%d+)m$")
    if h then
      c.played = tonumber(h) * 3600 + (tonumber(m) or 0) * 60
    elseif mins then
      c.played = tonumber(mins) * 60
    elseif tonumber(t) then
      c.played = tonumber(t) * 3600
    end
  end
  BC.Print("numbers saved: " .. BC.Num(c.kills) .. " boars, " .. c.deaths .. " deaths, " .. BC.Time(c.played) .. " played.")
  edit:Hide()
  Draw()
end

local resetClicks = 0

local function BuildEdit()
  edit = CreateFrame("Frame", "BoarChallengePlusEdit", UIParent)
  edit:SetWidth(380)
  edit:SetHeight(468)
  edit:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
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

  local title = edit:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", edit, "TOP", 0, -18)
  title:SetText("Boar Challenge +")
  local sub = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
  sub:SetText(GREY .. "The numbers for " .. (UnitName("player") or "this character") .. ", and what the panel shows" .. END)

  local close = CreateFrame("Button", "BoarChallengePlusEditClose", edit, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -6, -6)

  for i = 1, table.getn(FIELDS) do
    local f = FIELDS[i]
    local y = -62 - (i - 1) * 28
    local label = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", edit, "TOPLEFT", 28, y - 4)
    label:SetText(f.label)
    local box = CreateFrame("EditBox", "BoarChallengePlusEdit" .. f.key, edit, "InputBoxTemplate")
    box:SetWidth(120)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", edit, "TOPLEFT", 200, y)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() Save() end)
    Explain(box, f.label, f.tip)
    boxes[f.key] = box
  end

  -- Which rows the panel shows: one checkbox each, two columns, working at once.
  local head = edit:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  head:SetPoint("TOPLEFT", edit, "TOPLEFT", 28, -210)
  head:SetText("Rows on the panel")
  for i = 1, table.getn(BC.ROWS) do
    local def = BC.ROWS[i]
    local col = math.mod(i - 1, 2)
    local row = math.floor((i - 1) / 2)
    local check = CreateFrame("CheckButton", "BoarChallengePlusShow" .. def.key, edit, "UICheckButtonTemplate")
    check:SetWidth(22)
    check:SetHeight(22)
    check:SetPoint("TOPLEFT", edit, "TOPLEFT", 26 + col * 170, -228 - row * 22)
    getglobal(check:GetName() .. "Text"):SetText(def.label)
    check.key = def.key
    check:SetScript("OnClick", function()
      BC.char.show[this.key] = this:GetChecked() and true or false
      BC.Layout()
    end)
    Explain(check, def.label, def.tip)
    checks[def.key] = check
  end

  local save = CreateFrame("Button", "BoarChallengePlusEditSave", edit, "UIPanelButtonTemplate")
  save:SetWidth(100)
  save:SetHeight(22)
  save:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -24, 20)
  save:SetText("Save")
  save:SetScript("OnClick", Save)
  Explain(save, "Save", "Keeps the numbers you typed. The row checkboxes work as soon as you click them.")

  local cancel = CreateFrame("Button", "BoarChallengePlusEditCancel", edit, "UIPanelButtonTemplate")
  cancel:SetWidth(80)
  cancel:SetHeight(22)
  cancel:SetPoint("RIGHT", save, "LEFT", -6, 0)
  cancel:SetText("Close")
  cancel:SetScript("OnClick", function() edit:Hide() end)

  local session = CreateFrame("Button", "BoarChallengePlusEditSession", edit, "UIPanelButtonTemplate")
  session:SetWidth(110)
  session:SetHeight(22)
  session:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 24, 20)
  session:SetText("New session")
  session:SetScript("OnClick", function() BC.ResetSession() end)
  Explain(session, "New session", "Starts the session counters (this session's boars, XP per hour) again. The totals stay.")

  local reset = CreateFrame("Button", "BoarChallengePlusEditReset", edit, "UIPanelButtonTemplate")
  reset:SetWidth(110)
  reset:SetHeight(22)
  reset:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 24, 46)
  reset:SetText("Reset all")
  reset:SetScript("OnClick", function()
    if GetTime() - resetClicks < 10 then
      BC.ResetAll()
      Fill()
      BC.Layout()
      this:SetText("Reset all")
    else
      resetClicks = GetTime()
      this:SetText(RED .. "Really? Click again" .. END)
    end
  end)
  Explain(reset, "Reset all", "Every number for this character back to zero. Click twice.")
end

function BC.ShowEdit()
  if not edit then BuildEdit() end
  Fill()
  edit:Show()
end
