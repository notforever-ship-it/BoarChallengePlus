-- Boar Tally: the panel on screen, and the window for changing the numbers.

local BC = BoarTally
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local WIDTH, HEIGHT = 250, 152
local panel, text
local elapsed = 0

local function Line(label, value)
  return GREY .. label .. END .. " " .. WHITE .. value .. END
end

local function Draw()
  if not panel or not panel:IsShown() or not BC.char then return end
  local st = BC.Stats()
  local lines = {}
  table.insert(lines, Line("Boars", BC.Num(st.kills)) .. GREY .. "  (" .. BC.Num(st.sessionKills) .. " this session)" .. END)
  table.insert(lines, Line("Level " .. st.level, st.pct .. "%") .. GREY .. "  " .. BC.Num(st.xp) .. " / " .. BC.Num(st.xpMax) .. " XP" .. END)
  local recentXP = (st.xpHourRecent > 0) and (GREY .. "  (last 30 min " .. BC.Num(st.xpHourRecent) .. ")" .. END) or ""
  table.insert(lines, Line("XP per hour", BC.Num(st.xpHour)) .. recentXP)
  local recentKills = (st.killsHourRecent > 0) and (GREY .. "  (last 30 min " .. BC.Num(st.killsHourRecent) .. ")" .. END) or ""
  table.insert(lines, Line("Boars per hour", BC.Num(st.killsHour)) .. recentKills)
  local per = (st.xpPerBoar > 0) and BC.Num(st.xpPerBoar) or "?"
  local toLevel = st.boarsToLevel and (GREY .. "  about " .. BC.Num(st.boarsToLevel) .. " more to level " .. (st.level + 1) .. END) or ""
  table.insert(lines, Line("XP per boar", per) .. toLevel)
  table.insert(lines, Line("Next level in", st.secondsToLevel and ("~" .. BC.Time(st.secondsToLevel)) or "?") ..
    GREY .. "  at this pace" .. END)
  table.insert(lines, Line("Played", BC.Time(st.played)) .. GREY .. "  this session " .. BC.Time(st.sessionPlayed) .. END)
  local share = st.boarShare and (GREY .. "  " .. st.boarShare .. "% of your XP is boar" .. END) or ""
  table.insert(lines, Line("Deaths", st.deaths) .. share)
  text:SetText(table.concat(lines, "\n"))
end

function BC.Refresh()
  Draw()
end

local function Build()
  panel = CreateFrame("Frame", "BoarTallyPanel", UIParent)
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
  panel:SetBackdropColor(0.05, 0.05, 0.07, 0.85)
  panel:SetBackdropBorderColor(0.6, 0.45, 0.3, 1)

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
    GameTooltip:SetText("Boar Tally")
    GameTooltip:AddLine("Right-click to change the numbers. Shift-drag to move. /boar hides it.", 0.8, 0.8, 0.8, 1)
    GameTooltip:AddLine("XP per hour and boars per hour count this session; the last 30 minutes are in brackets.", 0.8, 0.8, 0.8, 1)
    GameTooltip:Show()
  end)
  panel:SetScript("OnLeave", function() GameTooltip:Hide() end)
  panel:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 1 then return end
    elapsed = 0
    Draw()
  end)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
  title:SetText(GOLD .. "Boar Tally" .. END .. GREY .. "  " .. (UnitName("player") or "") .. END)

  text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -26)
  text:SetWidth(WIDTH - 20)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")

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
local FIELDS = {
  { key = "kills", label = "Boars killed", tip = "Every boar this character has ever killed. Stealthboar starts at 1000." },
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
  boxes.kills:SetText(tostring(c.kills))
  boxes.deaths:SetText(tostring(c.deaths))
  boxes.played:SetText(BC.Time(c.played))
  boxes.boarXP:SetText(tostring(c.boarXP))
  boxes.otherXP:SetText(tostring(c.otherXP))
end

local function Save()
  local c = BC.char
  local n = tonumber(BC.Trim(boxes.kills:GetText()))
  if n then c.kills = math.floor(n) end
  n = tonumber(BC.Trim(boxes.deaths:GetText()))
  if n then c.deaths = math.floor(n) end
  n = tonumber(BC.Trim(boxes.boarXP:GetText()))
  if n then c.boarXP = math.floor(n) end
  n = tonumber(BC.Trim(boxes.otherXP:GetText()))
  if n then c.otherXP = math.floor(n) end
  local t = BC.Trim(boxes.played:GetText())
  local _, _, h, m = string.find(string.lower(t), "^(%d+)h%s*(%d*)m?$")
  if h then
    c.played = tonumber(h) * 3600 + (tonumber(m) or 0) * 60
  else
    local _, _, mins = string.find(string.lower(t), "^(%d+)m$")
    if mins then c.played = tonumber(mins) * 60 elseif tonumber(t) then c.played = tonumber(t) * 3600 end
  end
  BC.Print("numbers saved: " .. BC.Num(c.kills) .. " boars, " .. c.deaths .. " deaths, " .. BC.Time(c.played) .. " played.")
  edit:Hide()
  Draw()
end

local resetClicks = 0

local function BuildEdit()
  edit = CreateFrame("Frame", "BoarTallyEdit", UIParent)
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
  table.insert(UISpecialFrames, "BoarTallyEdit")

  local title = edit:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", edit, "TOP", 0, -18)
  title:SetText("Boar Tally")
  local sub = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
  sub:SetText(GREY .. "Change the numbers for " .. (UnitName("player") or "this character") .. END)

  local close = CreateFrame("Button", "BoarTallyEditClose", edit, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", edit, "TOPRIGHT", -6, -6)

  for i = 1, table.getn(FIELDS) do
    local f = FIELDS[i]
    local y = -66 - (i - 1) * 30
    local label = edit:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", edit, "TOPLEFT", 28, y - 4)
    label:SetText(f.label)
    local box = CreateFrame("EditBox", "BoarTallyEdit" .. f.key, edit, "InputBoxTemplate")
    box:SetWidth(120)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", edit, "TOPLEFT", 180, y)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() Save() end)
    Explain(box, f.label, f.tip)
    boxes[f.key] = box
  end

  local save = CreateFrame("Button", "BoarTallyEditSave", edit, "UIPanelButtonTemplate")
  save:SetWidth(100)
  save:SetHeight(22)
  save:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -24, 20)
  save:SetText("Save")
  save:SetScript("OnClick", Save)

  local cancel = CreateFrame("Button", "BoarTallyEditCancel", edit, "UIPanelButtonTemplate")
  cancel:SetWidth(80)
  cancel:SetHeight(22)
  cancel:SetPoint("RIGHT", save, "LEFT", -6, 0)
  cancel:SetText("Cancel")
  cancel:SetScript("OnClick", function() edit:Hide() end)

  local session = CreateFrame("Button", "BoarTallyEditSession", edit, "UIPanelButtonTemplate")
  session:SetWidth(110)
  session:SetHeight(22)
  session:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 24, 20)
  session:SetText("New session")
  session:SetScript("OnClick", function() BC.ResetSession() end)
  Explain(session, "New session", "Starts the session counters (this session's boars, XP per hour) again. The totals stay.")

  local reset = CreateFrame("Button", "BoarTallyEditReset", edit, "UIPanelButtonTemplate")
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
