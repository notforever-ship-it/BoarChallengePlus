-- Boar Challenge +: the panel on screen, and the window for changing the numbers.
--
-- The panel leads with the number that matters, boars left to the next level, then an XP bar, then
-- the rest as label / value / note rows.

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WIDTH = 262
local ROW_H, ROWS_Y, VALUE_X, NOTE_X = 16, -96, 152, 160
local ROWS = {
  { key = "kills", label = "Boars killed" },
  { key = "xph", label = "XP per hour" },
  { key = "bph", label = "Boars per hour" },
  { key = "xpb", label = "XP per boar" },
  { key = "played", label = "Played" },
  { key = "deaths", label = "Deaths" },
}
local HEIGHT = -ROWS_Y + table.getn(ROWS) * ROW_H + 10

local panel, nameText, bigText, paceText, bar, barText
local rows = {}
local elapsed = 0

local function Row(row, value, note)
  row.value:SetText(value)
  row.note:SetText(note and (GREY .. note .. END) or "")
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

  Row(rows.kills, BC.Num(st.kills), (st.sessionKills > 0) and ("+" .. BC.Num(st.sessionKills) .. " this session") or "none this session yet")
  Row(rows.xph, BC.Num(st.xpHour), (st.xpHourRecent > 0) and ("last 30 min " .. BC.Num(st.xpHourRecent)) or nil)
  Row(rows.bph, BC.Num(st.killsHour), (st.killsHourRecent > 0) and ("last 30 min " .. BC.Num(st.killsHourRecent)) or nil)
  Row(rows.xpb, (st.xpPerBoar > 0) and BC.Num(st.xpPerBoar) or "?", nil)
  Row(rows.played, BC.Time(st.played), "this session " .. BC.Time(st.sessionPlayed))
  Row(rows.deaths, tostring(st.deaths), st.boarShare and (st.boarShare .. "% of your XP is boar") or nil)
end

function BC.Refresh()
  Draw()
end

local function Build()
  panel = CreateFrame("Frame", "BoarChallengePlusPanel", UIParent)
  panel:SetWidth(WIDTH)
  panel:SetHeight(HEIGHT)
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
    panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -220)
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
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Boar Challenge +")
    GameTooltip:AddLine("Right-click to change the numbers. Shift-drag to move. /boar hides it.", 0.8, 0.8, 0.8, 1)
    GameTooltip:AddLine("XP per hour and boars per hour count this session; the last 30 minutes are in the notes.", 0.8, 0.8, 0.8, 1)
    GameTooltip:Show()
  end)
  panel:SetScript("OnLeave", function() GameTooltip:Hide() end)
  panel:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 1 then return end
    elapsed = 0
    Draw()
  end)

  -- Title and character
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
  title:SetText(GOLD .. "Boar Challenge +" .. END)
  nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nameText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -12)
  nameText:SetText(GREY .. (UnitName("player") or "") .. END)

  -- The headline: boars to the next level, and the time that takes
  bigText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  bigText:SetPoint("TOP", panel, "TOP", 0, -30)
  bigText:SetWidth(WIDTH - 24)
  bigText:SetJustifyH("CENTER")
  paceText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  paceText:SetPoint("TOP", bigText, "BOTTOM", 0, -2)
  paceText:SetWidth(WIDTH - 24)
  paceText:SetJustifyH("CENTER")

  -- XP bar, in the game's XP purple
  bar = CreateFrame("StatusBar", nil, panel)
  bar:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -70)
  bar:SetWidth(WIDTH - 24)
  bar:SetHeight(14)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.58, 0.1, 0.62)
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(bar)
  bg:SetTexture(0, 0, 0, 0.6)
  barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  barText:SetPoint("CENTER", bar, "CENTER", 0, 0)

  -- A thin line, then the rows
  local line = panel:CreateTexture(nil, "ARTWORK")
  line:SetTexture(0.7, 0.5, 0.3, 0.5)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -90)
  line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -90)

  for i = 1, table.getn(ROWS) do
    local y = ROWS_Y - (i - 1) * ROW_H
    local r = {}
    r.label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.label:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y - 2)
    r.label:SetText(GREY .. ROWS[i].label .. END)
    r.value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.value:SetPoint("TOPRIGHT", panel, "TOPLEFT", VALUE_X, y)
    r.value:SetJustifyH("RIGHT")
    r.note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.note:SetPoint("TOPLEFT", panel, "TOPLEFT", NOTE_X, y - 2)
    r.note:SetWidth(WIDTH - NOTE_X - 10)
    r.note:SetJustifyH("LEFT")
    rows[ROWS[i].key] = r
  end

  if not BC.db.shown then panel:Hide() end
end

function BC.InitPanel()
  if not panel then Build() end
  Draw()
end

function BC.TogglePanel()
  if not panel then Build() end
  if panel:IsShown() then
    panel:Hide()
    BC.db.shown = false
  else
    panel:Show()
    BC.db.shown = true
    Draw()
  end
end

------------------------------------------------------------------------------------------------------
-- The edit window: type the numbers you already have
------------------------------------------------------------------------------------------------------

local edit
local boxes = {}
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
  edit:SetWidth(340)
  edit:SetHeight(290)
  edit:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
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
  sub:SetText(GREY .. "Change the numbers for " .. (UnitName("player") or "this character") .. END)

  local close = CreateFrame("Button", "BoarChallengePlusEditClose", edit, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -6, -6)

  for i = 1, table.getn(FIELDS) do
    local f = FIELDS[i]
    local y = -66 - (i - 1) * 30
    local label = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", edit, "TOPLEFT", 28, y - 4)
    label:SetText(f.label)
    local box = CreateFrame("EditBox", "BoarChallengePlusEdit" .. f.key, edit, "InputBoxTemplate")
    box:SetWidth(120)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", edit, "TOPLEFT", 180, y)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() Save() end)
    Explain(box, f.label, f.tip)
    boxes[f.key] = box
  end

  local save = CreateFrame("Button", "BoarChallengePlusEditSave", edit, "UIPanelButtonTemplate")
  save:SetWidth(100)
  save:SetHeight(22)
  save:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -24, 20)
  save:SetText("Save")
  save:SetScript("OnClick", Save)

  local cancel = CreateFrame("Button", "BoarChallengePlusEditCancel", edit, "UIPanelButtonTemplate")
  cancel:SetWidth(80)
  cancel:SetHeight(22)
  cancel:SetPoint("RIGHT", save, "LEFT", -6, 0)
  cancel:SetText("Cancel")
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
