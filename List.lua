-- Boar Challenge +: the boar list window, and the boar dots on the world map.
--
-- The list shows every boar known (pfQuest's database, or the built-in list), grouped by zone, lowest
-- zone first. Tick a boar, or a whole zone, and its spawn points show as small dots on the world map,
-- coloured the way the game colours that boar for you. Click a boar's name to open the map there.
-- With pfQuest the dots are pfQuest pins in our colours, so they show on the minimap too. Without it the
-- dots are our own, on the world map only.

local BC = BoarChallengePlus
local GOLD, GREY, WHITE, RED, GREEN, END = BC.GOLD, BC.GREY, BC.WHITE, BC.RED, BC.GREEN, BC.END

local LIST_W, LIST_H = 480, 460
local ROWS, ROW_H = 14, 20
local TOP = -136                  -- the first row
local ROW_W = 420
local MAX_DOTS = 800              -- more than any zone needs; keeps a slow PC safe

-- the dot colours: the game's level colours, and one boar-orange when colours are off
local RGB = {
  grey = { 0.62, 0.62, 0.62 }, green = { 0.25, 1.00, 0.25 }, yellow = { 1.00, 1.00, 0.25 },
  orange = { 1.00, 0.50, 0.00 }, red = { 1.00, 0.25, 0.25 },
}
local BOAR_RGB = { 1.00, 0.66, 0.34 }

local list, scroll, emptyText, dataText
local rows, topChecks = {}, {}
local data = {}                   -- what the list shows: { kind = "zone", zone } or { kind = "boar", row }
local drawnLevel = nil

local function Key(r)
  return r[1] .. "|" .. r[4]
end

-- A boar whose dots show: ticked, and not grey when "Only boars that give me XP" is on (so the dots
-- follow you as you level).
local function Wanted(r, c, grey)
  if not c.mapBoars[Key(r)] then return false end
  return not (c.opt.listXPOnly and r[3] <= grey)
end

local function Levels(r)
  if r[2] == r[3] then return tostring(r[2]) end
  return r[2] .. "-" .. r[3]
end

-- The game's colour for this boar at your level: "grey" ... "red".
local function ColourOf(r)
  return BC.LevelColour(r[3], UnitLevel("player") or 1)
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

------------------------------------------------------------------------------------------------------
-- The dots on the world map
------------------------------------------------------------------------------------------------------

local dots, pins = nil, {}
local PfReady
local dotsDirty, dotsKey, dotsTick = true, nil, 0
local zoneCache = {}              -- [continent] = { GetMapZones(continent) }

-- The zone the world map shows now, or nil on a continent or the whole world.
local function ShownZone()
  local cont, zone = GetCurrentMapContinent(), GetCurrentMapZone()
  if not cont or not zone or cont < 1 or zone < 1 then return nil end
  if not zoneCache[cont] then zoneCache[cont] = { GetMapZones(cont) } end
  return zoneCache[cont][zone]
end

local function PinEnter()
  local tip = WorldMapTooltip or GameTooltip
  local r = this.row
  if not r then return end
  tip:SetOwner(this, "ANCHOR_LEFT")
  tip:SetText(BC.COLOUR[ColourOf(r)] .. r[1] .. " " .. Levels(r) .. END)
  if r[5] then tip:AddLine(r[5], 1, 1, 1) end
  tip:AddLine(r[8] .. " spawns in " .. r[4], 0.7, 0.7, 0.7)
  tip:Show()
end

local function PinLeave()
  local tip = WorldMapTooltip or GameTooltip
  tip:Hide()
end

local function Pin(i)
  if pins[i] then return pins[i] end
  local p = CreateFrame("Frame", nil, dots)
  p:EnableMouse(true)
  p.edge = p:CreateTexture(nil, "ARTWORK")
  p.edge:SetTexture("Interface\\Buttons\\WHITE8X8")
  p.edge:SetVertexColor(0, 0, 0, 0.9)
  p.edge:SetAllPoints(p)
  p.fill = p:CreateTexture(nil, "OVERLAY")
  p.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  p.fill:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
  p.fill:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
  p:SetScript("OnEnter", PinEnter)
  p:SetScript("OnLeave", PinLeave)
  pins[i] = p
  return p
end

local function Place(i, x, y, size, rgb, r, w, h)
  local p = Pin(i)
  p:SetWidth(size)
  p:SetHeight(size)
  p:ClearAllPoints()
  p:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x / 100 * w, -y / 100 * h)
  p.fill:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
  p.row = r
  p:Show()
end

------------------------------------------------------------------------------------------------------
-- pfQuest pins: world map and minimap
------------------------------------------------------------------------------------------------------

-- pfQuest keeps a pin's first colour for good, so each colour gets its own pin group, and a new colour
-- (after a level-up) makes a new pin instead of keeping the old one.
local PF = "BOARCHALLENGE"
local PF_GROUPS = { "grey", "green", "yellow", "orange", "red", "plain" }

PfReady = function()
  return pfMap and pfMap.AddNode and pfMap.DeleteNode and pfQuestConfig and pfQuestConfig.path
    and BC.RowsAreLive() and true or false
end

local function SyncPf()
  if not PfReady() then return end
  for i = 1, table.getn(PF_GROUPS) do pfMap:DeleteNode(PF .. PF_GROUPS[i]) end
  local c = BC.char
  if c and c.opt.mapDots then
    local tex = pfQuestConfig.path .. "\\img\\node"
    local grey = BC.GreyLevel(UnitLevel("player") or 1)
    local src = BC.BoarRows()
    for i = 1, table.getn(src) do
      local r = src[i]
      if type(r[9]) == "table" and Wanted(r, c, grey) then
        local group = c.opt.mapColours and ColourOf(r) or "plain"
        local rgb = (group == "plain") and BOAR_RGB or RGB[group]
        for j = 1, table.getn(r[9]) do
          local pt = r[9][j]
          if pt[3] then
            pfMap:AddNode({ addon = PF .. group, zone = pt[3], x = pt[1], y = pt[2], title = r[1], spawn = r[1],
              spawntype = "Unit", level = Levels(r), texture = tex, vertex = rgb })
          end
        end
      end
    end
  end
  if pfMap.UpdateNodes then pfMap:UpdateNodes() end
end

-- Every ticked boar of the zone on the map: a dot at each spawn point (live data), or one bigger dot
-- at its spot (the built-in list).
local function DrawDots()
  dotsDirty = false
  local used = 0
  local c = BC.char
  local zone = ShownZone()
  if c and c.opt.mapDots and zone and not PfReady() then
    local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
    local grey = BC.GreyLevel(UnitLevel("player") or 1)
    local src = BC.BoarRows()
    for i = 1, table.getn(src) do
      local r = src[i]
      if r[4] == zone and Wanted(r, c, grey) then
        local rgb = c.opt.mapColours and RGB[ColourOf(r)] or BOAR_RGB
        if type(r[9]) == "table" then
          for j = 1, table.getn(r[9]) do
            if used < MAX_DOTS then
              used = used + 1
              Place(used, r[9][j][1], r[9][j][2], 7, rgb, r, w, h)
            end
          end
        elseif used < MAX_DOTS then
          used = used + 1
          Place(used, r[6], r[7], 12, rgb, r, w, h)
        end
      end
    end
  end
  for i = used + 1, table.getn(pins) do pins[i]:Hide() end
end

-- Something changed (a tick, an option): the dots are drawn again the next time the map is looked at.
function BC.MapChanged()
  dotsDirty = true
  SyncPf()
  if dots and dots:IsVisible() then DrawDots() end
end

local function BuildDots()
  if dots or not WorldMapButton then return end
  dots = CreateFrame("Frame", "BoarChallengePlusMapDots", WorldMapButton)
  dots:SetAllPoints(WorldMapButton)
  dots:SetFrameLevel(WorldMapButton:GetFrameLevel() + 3)
  dots:RegisterEvent("WORLD_MAP_UPDATE")
  dots:SetScript("OnEvent", function() dotsDirty = true end)
  -- only runs while the map is open: looks a few times a second if the zone or the map size changed
  dots:SetScript("OnUpdate", function()
    dotsTick = dotsTick + arg1
    if dotsTick < 0.1 then return end
    dotsTick = 0
    local key = (GetCurrentMapContinent() or 0) .. "|" .. (GetCurrentMapZone() or 0) .. "|" ..
      math.floor(WorldMapButton:GetWidth()) .. "|" .. math.floor(WorldMapButton:GetHeight())
    if dotsDirty or key ~= dotsKey then
      dotsKey = key
      DrawDots()
    end
  end)
end

-- Opens the world map on a zone: pfQuest's way when it is there, else the game's own.
function BC.OpenMapOn(zone)
  if pfMap and pfMap.ShowMapID and pfMap.GetMapIDByName and pfDB and pfDB.zones and pfDB.zones.loc then
    local id = pfMap:GetMapIDByName(zone)
    if id and pfMap:ShowMapID(id) then
      BC.MapChanged()
      return
    end
  end
  if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end   -- it opens on your own zone
  local conts = { GetMapContinents() }
  for cont = 1, table.getn(conts) do
    local zones = { GetMapZones(cont) }
    for i = 1, table.getn(zones) do
      if zones[i] == zone then
        SetMapZoom(cont, i)
        BC.MapChanged()
        return
      end
    end
  end
  BC.Print(WHITE .. zone .. END .. " is not on this world map.")
end

------------------------------------------------------------------------------------------------------
-- The list
------------------------------------------------------------------------------------------------------

-- Every boar to show, by zone: zones low to high by their lowest boar, boars low to high.
local function BuildData()
  local c = BC.char
  local grey = BC.GreyLevel(UnitLevel("player") or 1)
  local src = BC.BoarRows()
  local zones, order = {}, {}
  for i = 1, table.getn(src) do
    local r = src[i]
    if not (c.opt.listXPOnly and r[3] <= grey) then
      local z = zones[r[4]]
      if not z then
        z = { name = r[4], lo = r[2], hi = r[3], spawns = 0, rows = {} }
        zones[r[4]] = z
        table.insert(order, z)
      end
      if r[2] < z.lo then z.lo = r[2] end
      if r[3] > z.hi then z.hi = r[3] end
      z.spawns = z.spawns + r[8]
      table.insert(z.rows, r)
    end
  end
  table.sort(order, function(a, b)
    if a.lo ~= b.lo then return a.lo < b.lo end
    return a.name < b.name
  end)
  data = {}
  for i = 1, table.getn(order) do
    local z = order[i]
    table.sort(z.rows, function(a, b)
      if a[2] ~= b[2] then return a[2] < b[2] end
      if a[3] ~= b[3] then return a[3] < b[3] end
      return a[1] < b[1]
    end)
    table.insert(data, { kind = "zone", zone = z })
    for j = 1, table.getn(z.rows) do table.insert(data, { kind = "boar", row = z.rows[j] }) end
  end
end

-- A zone is ticked when every boar it shows is ticked.
local function ZoneTicked(z)
  local m = BC.char.mapBoars
  for i = 1, table.getn(z.rows) do
    if not m[Key(z.rows[i])] then return false end
  end
  return true
end

local DrawList

local function FillRows()
  if not list or not list:IsShown() then return end
  local total = table.getn(data)
  -- the list got shorter (e.g. "Only boars that give me XP") while scrolled down: move back up, or it shows empty
  local offset = FauxScrollFrame_GetOffset(scroll) or 0
  if offset > 0 and offset > total - ROWS then
    offset = (total > ROWS) and (total - ROWS) or 0
    scroll.offset = offset
    getglobal(scroll:GetName() .. "ScrollBar"):SetValue(offset * ROW_H)
  end
  FauxScrollFrame_Update(scroll, total, ROWS, ROW_H)
  offset = FauxScrollFrame_GetOffset(scroll) or 0
  local m = BC.char.mapBoars
  for i = 1, ROWS do
    local f = rows[i]
    local e = data[i + offset]
    f.entry = e
    if not e then
      f:Hide()
    elseif e.kind == "zone" then
      local z = e.zone
      f.stripe:Show()
      f.check:SetChecked(ZoneTicked(z) and 1 or nil)
      f.name:SetText(GOLD .. z.name .. END)
      f.levels:SetText(GREY .. z.lo .. "-" .. z.hi .. END)
      f.area:SetText(GREY .. table.getn(z.rows) .. (table.getn(z.rows) == 1 and " boar" or " boars") .. END)
      f.spot:SetText("")
      f.spawns:SetText(GREY .. z.spawns .. END)
      f:Show()
    else
      local r = e.row
      f.stripe:Hide()
      f.check:SetChecked(m[Key(r)] and 1 or nil)
      f.name:SetText(WHITE .. "  " .. r[1] .. END)
      f.levels:SetText(BC.COLOUR[ColourOf(r)] .. Levels(r) .. END)
      f.area:SetText(GREY .. (r[5] or "") .. END)
      f.spot:SetText(GREY .. r[6] .. ", " .. r[7] .. END)
      f.spawns:SetText(WHITE .. r[8] .. END)
      f:Show()
    end
  end
  if total == 0 then emptyText:Show() else emptyText:Hide() end
end

DrawList = function()
  if not list or not list:IsShown() or not BC.char then return end
  drawnLevel = UnitLevel("player")
  local c = BC.char
  topChecks.listXPOnly:SetChecked(c.opt.listXPOnly and 1 or nil)
  topChecks.mapDots:SetChecked(c.opt.mapDots and 1 or nil)
  topChecks.mapColours:SetChecked(c.opt.mapColours and 1 or nil)
  dataText:SetText(GREY .. (BC.RowsAreLive() and "Data: pfQuest" or "Data: built-in list") .. END)
  BuildData()
  FillRows()
end
BC.DrawList = DrawList

local function RowClick()
  local e = this.entry
  if not e then return end
  if e.kind == "zone" then
    BC.OpenMapOn(e.zone.name)
    return
  end
  BC.char.mapBoars[Key(e.row)] = true
  FillRows()
  BC.OpenMapOn(e.row[4])
end

local function TickClick()
  local e = this:GetParent().entry
  if not e then return end
  local on = this:GetChecked() and true or nil
  local m = BC.char.mapBoars
  if e.kind == "zone" then
    for i = 1, table.getn(e.zone.rows) do m[Key(e.zone.rows[i])] = on end
  else
    m[Key(e.row)] = on
  end
  FillRows()
  BC.MapChanged()
end

local function Text(parent, x, width, justify)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", parent, "LEFT", x, 0)
  fs:SetWidth(width)
  fs:SetHeight(12)
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

-- The column x positions inside a row: tick, name, levels, area, spot, spawns.
local COL = { name = 24, levels = 184, area = 226, spot = 342, spawns = 384 }

local function BuildRow(i)
  local f = CreateFrame("Button", "BoarChallengePlusListRow" .. i, list)
  f:SetWidth(ROW_W)
  f:SetHeight(ROW_H)
  f:SetPoint("TOPLEFT", list, "TOPLEFT", 18, TOP - (i - 1) * ROW_H)
  f:SetFrameLevel(scroll:GetFrameLevel() + 2)
  f:RegisterForClicks("LeftButtonUp")
  local hl = f:CreateTexture(nil, "HIGHLIGHT")
  hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  hl:SetBlendMode("ADD")
  hl:SetAllPoints(f)
  f.stripe = f:CreateTexture(nil, "BACKGROUND")
  f.stripe:SetTexture(1.00, 0.84, 0.20, 0.08)
  f.stripe:SetAllPoints(f)
  f.check = CreateFrame("CheckButton", "BoarChallengePlusListTick" .. i, f, "UICheckButtonTemplate")
  f.check:SetWidth(20)
  f.check:SetHeight(20)
  f.check:SetPoint("LEFT", f, "LEFT", 0, 0)
  f.check:SetScript("OnClick", TickClick)
  f.check:SetScript("OnEnter", function()
    local e = this:GetParent().entry
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if e and e.kind == "zone" then
      GameTooltip:SetText("Show all boars in " .. e.zone.name .. " on the map")
    else
      GameTooltip:SetText("Show on the map")
    end
    GameTooltip:Show()
  end)
  f.check:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f.name = Text(f, COL.name, 156)
  f.levels = Text(f, COL.levels, 40)
  f.area = Text(f, COL.area, 112)
  f.spot = Text(f, COL.spot, 40)
  f.spawns = Text(f, COL.spawns, 34, "RIGHT")
  f:SetScript("OnClick", RowClick)
  f:SetScript("OnEnter", function()
    local e = this.entry
    if not e then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if e.kind == "zone" then
      GameTooltip:SetText(e.zone.name)
      GameTooltip:AddLine("Click: open the map here.", 1, 1, 1)
    else
      GameTooltip:SetText(e.row[1] .. " " .. Levels(e.row))
      GameTooltip:AddLine("Click: open the map on " .. e.row[4] .. ", dots on.", 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f:Hide()
  return f
end

local function TopCheck(key, label, tip, x, y)
  local name = "BoarChallengePlusList" .. key
  local check = CreateFrame("CheckButton", name, list, "UICheckButtonTemplate")
  check:SetWidth(20)
  check:SetHeight(20)
  check:SetPoint("TOPLEFT", list, "TOPLEFT", x, y)
  getglobal(name .. "Text"):SetText(label)
  check.key = key
  check:SetScript("OnClick", function()
    BC.char.opt[this.key] = this:GetChecked() and true or false
    DrawList()
    BC.MapChanged()
  end)
  Explain(check, label, tip)
  topChecks[key] = check
end

local function BuildList()
  list = CreateFrame("Frame", "BoarChallengePlusList", UIParent)
  list:SetWidth(LIST_W)
  list:SetHeight(LIST_H)
  list:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  list:SetFrameStrata("DIALOG")
  list:SetFrameLevel(40)        -- above the settings window and its boxes (set before the parts are made)
  list:SetClampedToScreen(true)
  list:EnableMouse(true)
  list:SetMovable(true)
  list:RegisterForDrag("LeftButton")
  list:SetScript("OnDragStart", function() this:StartMoving() end)
  list:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  list:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  local solid = list:CreateTexture(nil, "BACKGROUND")
  solid:SetTexture(0.05, 0.05, 0.07, 1)
  solid:SetPoint("TOPLEFT", list, "TOPLEFT", 11, -11)
  solid:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -11, 11)
  list:Hide()
  list:SetScript("OnShow", function() DrawList() end)
  table.insert(UISpecialFrames, "BoarChallengePlusList")

  local head = list:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  head:SetPoint("TOP", list, "TOP", 0, -18)
  head:SetText("Boar list")
  local sub = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOP", head, "BOTTOM", 0, -3)
  sub:SetText(GREY .. "tick a boar to see it on the world map" .. (PfReady() and " and the minimap" or "") .. END)
  local close = CreateFrame("Button", "BoarChallengePlusListClose", list, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, -6)
  local credit = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("BOTTOM", list, "BOTTOM", 0, 16)
  credit:SetText(GREY .. "Made by " .. END .. "|cffabd473stealthzi" .. END .. GREY .. "   v" .. BC.VERSION .. END)

  -- the switches, two to a line, and Clear map
  TopCheck("listXPOnly", "Only boars that give me XP", "Hides the grey boars (no XP at your level), in the list and on the map. Follows you as you level.", 20, -56)
  TopCheck("mapDots", "Boar dots on the map", "Dots on the world map for every boar you ticked.", 250, -56)
  TopCheck("mapColours", "Colour dots by level", "Off: every dot the same boar orange.", 20, -78)
  local clear = CreateFrame("Button", "BoarChallengePlusListClear", list, "UIPanelButtonTemplate")
  clear:SetWidth(96)
  clear:SetHeight(22)
  clear:SetPoint("TOPLEFT", list, "TOPLEFT", 252, -78)
  clear:SetText("Clear map")
  Explain(clear, "Clear map", "Unticks every boar. The dots go.")
  clear:SetScript("OnClick", function()
    BC.char.mapBoars = {}
    DrawList()
    BC.MapChanged()
  end)
  local all = CreateFrame("Button", "BoarChallengePlusListAll", list, "UIPanelButtonTemplate")
  all:SetWidth(96)
  all:SetHeight(22)
  all:SetPoint("LEFT", clear, "RIGHT", 4, 0)
  all:SetText("Tick all")
  Explain(all, "Tick all", "Ticks every boar in the list: dots for all of them.")
  all:SetScript("OnClick", function()
    for i = 1, table.getn(data) do
      if data[i].kind == "boar" then BC.char.mapBoars[Key(data[i].row)] = true end
    end
    DrawList()
    BC.MapChanged()
  end)

  -- the colour key, and where the boars come from
  local key = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  key:SetPoint("TOPLEFT", list, "TOPLEFT", 24, -106)
  key:SetText(GREY .. "Key: " .. END .. BC.COLOUR.grey .. "grey = no XP" .. END .. "   " .. BC.COLOUR.green .. "green" .. END ..
    "   " .. BC.COLOUR.yellow .. "yellow" .. END .. "   " .. BC.COLOUR.orange .. "orange" .. END .. "   " .. BC.COLOUR.red .. "red" .. END)
  dataText = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  dataText:SetPoint("TOPRIGHT", list, "TOPRIGHT", -24, -106)

  -- the column names
  local cols = { { "Map", 0 }, { "Boar", COL.name }, { "Levels", COL.levels }, { "Area", COL.area }, { "Spot", COL.spot }, { "Spawns", COL.spawns - 2 } }
  for i = 1, table.getn(cols) do
    local fs = list:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", list, "TOPLEFT", 18 + cols[i][2], -122)
    fs:SetText(cols[i][1])
  end

  scroll = CreateFrame("ScrollFrame", "BoarChallengePlusListScroll", list, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 18, TOP)
  scroll:SetWidth(ROW_W)
  scroll:SetHeight(ROWS * ROW_H)
  scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(ROW_H, FillRows) end)
  for i = 1, ROWS do rows[i] = BuildRow(i) end

  emptyText = list:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  emptyText:SetPoint("TOP", list, "TOP", 0, TOP - 40)
  emptyText:SetText(GREY .. "No boars to show. Untick \"Only boars that give me XP\"." .. END)
  emptyText:Hide()
end

function BC.ToggleList()
  if not BC.char then return end
  BuildDots()
  if not list then BuildList() end
  if list:IsShown() then
    list:Hide()
  else
    list:Show()
  end
end

-- The dots are ready from login, so ticks from last time show the first time the map opens.
local seenLevel, pfDone = nil, nil
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    BuildDots()
    seenLevel = UnitLevel("player")
  elseif event == "PLAYER_ENTERING_WORLD" then
    if not pfDone then pfDone = true SyncPf() end   -- last time's ticks on the minimap straight away
  elseif UnitLevel("player") ~= seenLevel then
    -- a new level changes the colours (and the grey boars); the game can be a moment late with it,
    -- so the XP update after a level-up looks again
    seenLevel = UnitLevel("player")
    if list and list:IsShown() and drawnLevel ~= seenLevel then DrawList() end
    BC.MapChanged()
  end
end)
