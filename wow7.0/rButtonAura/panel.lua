
-- rButtonAura: panel
-- zork, 2018

-----------------------------
-- Variables
-----------------------------

local A, L = ...

--panel container
L.P = {}

-----------------------------
-- Functions
-----------------------------

--CreateHeader
local function CreateHeader(frame,titleText,subtitleText,x,y)
  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", x or 0, y or 0)
  title:SetText(titleText)
  if not subtitleText then return title, nil end
  local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  subtitle:SetPoint("RIGHT", frame, -32, 0)
  subtitle:SetNonSpaceWrap(true)
  subtitle:SetJustifyH("LEFT")
  subtitle:SetJustifyV("TOP")
  subtitle:SetText(subtitleText)
  subtitle:SetHeight(subtitle:GetStringHeight())
  return title, subtitle
end

--ActionButtonOnClick
local function ActionButtonOnClick(button)
  local panel = button.__owner
  if panel.activeActionButton and panel.activeActionButton ~= button and panel.activeActionButton:GetChecked() then
    --disable the last checked action button, only one may survive
    panel.activeActionButton:SetChecked(false)
  end
  if button:GetChecked() then
    panel.activeActionButton = button
  else
    panel.activeActionButton = nil
  end
end

--CreateActionButton
local function CreateActionButton(panel,blizzardButton,i,r)
  if not blizzardButton then return end
  local k = i+NUM_ACTIONBAR_BUTTONS*r
  --"ActionButtonTemplate, SecureHandlerClickTemplate"
  local button = CreateFrame("Checkbutton", panel:GetName().."Button"..k, panel, "ActionButtonTemplate")
  button.__owner = panel
  button.blizzardButton = blizzardButton
  button:SetSize(32,32)
  if k == 1 then
    button:SetPoint("TOPLEFT", 16, -66)
  elseif i == 1 then
    local aboveButton = _G[panel:GetName().."Button"..(k-NUM_ACTIONBAR_BUTTONS)]
    button:SetPoint("TOPLEFT", aboveButton, "BOTTOMLEFT", 0, -8)
  else
    local prevButton = _G[panel:GetName().."Button"..(k-1)]
    button:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
  end
  button:HookScript("OnClick",ActionButtonOnClick)
  table.insert(panel.buttons,button)
end

--CreateActionButtons
local function CreateActionButtons(panel)
  local title, subtitle = CreateHeader(panel,"Buttons","Select the actionbutton you want to configure.",16,-16)
  panel.buttons = {}
  for i = 1, NUM_ACTIONBAR_BUTTONS do
    CreateActionButton(panel,_G["ActionButton"..i],i,0)
    CreateActionButton(panel,_G["MultiBarBottomLeftButton"..i],i,1)
    CreateActionButton(panel,_G["MultiBarBottomRightButton"..i],i,2)
    CreateActionButton(panel,_G["MultiBarRightButton"..i],i,3)
    CreateActionButton(panel,_G["MultiBarLeftButton"..i],i,4)
  end
end

--AuraButtonOnClick
local function AuraButtonOnClick(button,mouseButton)
  print(button:GetName(),mouseButton,button.spellId)
  if mouseButton == "RightButton" then
    L.F.RemoveAuraFromDBC(button.spellId)
    button.__owner:refresh()
  end
end

--CreateAuraButton
local function CreateAuraButton(panel,i)
  print("CreateAuraButton",panel:GetName(),spellId,texture,i,panel.frame.subtitle,panel.frame.title)
  local button = CreateFrame("Button", panel:GetName().."Button"..i, panel, "ActionButtonTemplate")
  button:RegisterForClicks("AnyUp")
  button.__owner = panel
  button:SetSize(32,32)
  if i == 1 then
    button:SetPoint("TOPLEFT", panel.frame.editbox, "BOTTOMLEFT", 0, -8)
  else
    local prevButton = _G[panel:GetName().."Button"..(i-1)]
    button:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
  end
  button:HookScript("OnClick",AuraButtonOnClick)
  button:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT",-6,6)
    GameTooltip:AddLine(self.spellName, 0, 1, 0.5, 1, 1, 1)
    GameTooltip:AddDoubleLine("|cff0099ffSpell ID|r",self.spellId)
    GameTooltip:AddLine("Right-click to remove.", 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  button:HookScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  return button
end

--CreateChildPanel1Frame
local function CreateChildPanel1Frame(panel)
  print(A,panel:GetName(),"create")
  local frame = CreateFrame("Frame",nil,panel)
  panel.frame = frame
  frame:SetPoint("TOPLEFT",16,-16)
  frame:SetPoint("BOTTOMRIGHT",-16,16)
  local bg = frame:CreateTexture(nil,"BACKGROUND",nil,-8)
  bg:SetAllPoints()
  bg:SetColorTexture(0,1,0,0.5)
  bg:Hide()
  frame.title, frame.subtitle = CreateHeader(frame,"Character Aura Database","Enter any aura spellid in the following search field and hit return to add it. Right-click any button to remove the aura.")
  frame.editbox = CreateFrame("EditBox", panel:GetName().."SpellSearch", frame, "SearchBoxTemplate")
  frame.editbox:SetPoint("TOPLEFT", frame.subtitle or frame.title, "BOTTOMLEFT", 0, -4)
  frame.editbox:SetSize(120,30)
  frame.editbox:SetScript("OnEnterPressed", function(self)
    local value = math.max(math.floor(self:GetNumber()),1)
    self:SetText(value)
    if value == 1 then print(A,"Bad Aura ID!") return end
    local name, rank, icon, castingTime, minRange, maxRange, spellId = GetSpellInfo(value)
    if not name then
      print(A,"Aura not found!")
      return
    end
    print(A,spellId,name,"Aura added")
    L.F.AddAuraToDBC(spellId,{name, rank, icon, castingTime, minRange, maxRange, spellId})
    panel:refresh()
  end)
end

--SubmitIOFPanel
local function SubmitIOFPanel(panel,...)
  --xpcall(function(...) print(...) end, geterrorhandler())
  print(panel:GetName(),"okay")
end

--CancelIOFPanel
local function CancelIOFPanel(panel,...)
  print(panel:GetName(),"cancel")
end

--ResetIOFPanel
local function ResetIOFPanel(panel,...)
  print(panel:GetName(),"default")
  L.F.ResetDBG()
  L.F.ResetDBC()
end

--RefreshMainPanel
local function RefreshMainPanel(panel)
  print(panel:GetName(),"refresh")
  if not panel.buttons then return end
  for i, button in next, panel.buttons do
    button:SetChecked(false)
    local type, id, subType, spellID = GetActionInfo(button.blizzardButton.action)
    --if type == "spell" or type == "macro" or type == "item" then
    if type then
      button.icon:SetTexture(button.blizzardButton.icon:GetTexture())
    else
      button.icon:SetColorTexture(0.05,0.05,0.05)
    end
  end
end

--RefreshChildPanel1
local function RefreshChildPanel1(panel)
  print(panel:GetName(),"refresh")
  if not L.DB.C then return end
  panel.buttons = panel.buttons or {}
  --print(#panel.buttons)
  local buttonIndex = 0
  print("count spells",#L.DB.C["SPELLS"])
  for key, data in next, L.DB.C["SPELLS"] do
    buttonIndex = buttonIndex+1
    print(key,unpack(data))
    panel.buttons[buttonIndex] = panel.buttons[buttonIndex] or CreateAuraButton(panel,buttonIndex)
    panel.buttons[buttonIndex].spellName = data[1]
    panel.buttons[buttonIndex].icon:SetTexture(data[3])
    panel.buttons[buttonIndex].spellId = data[7]
    panel.buttons[buttonIndex]:Show()
  end
  print("count",buttonIndex+1,#panel.buttons)
  for i = buttonIndex+1, #panel.buttons do
    panel.buttons[i]:Hide()
  end
end

-----------------------------
-- Init Panels
-----------------------------

local mainPanel = CreateFrame("Frame", A.."MainPanel", UIParent)
mainPanel.name = A
mainPanel.okay = SubmitIOFPanel
mainPanel.cancel = CancelIOFPanel
mainPanel.refresh = RefreshMainPanel
mainPanel.default = ResetIOFPanel
CreateActionButtons(mainPanel)
InterfaceOptions_AddCategory(mainPanel)

--childPanel1
local childPanel1 = CreateFrame("Frame", A.."ChildPanel1", mainPanel)
childPanel1.name = "Character Aura Database"
childPanel1.parent = mainPanel.name
childPanel1.okay = SubmitIOFPanel
childPanel1.cancel = CancelIOFPanel
childPanel1.refresh = RefreshChildPanel1
childPanel1.default = ResetIOFPanel
CreateChildPanel1Frame(childPanel1)
InterfaceOptions_AddCategory(childPanel1)









L.P.mainPanel = panel
L.P.childPanel1 = childPanel1

--[[ local radio = CreateFrame("CheckButton",A.."PanelRadio1",panel,"UIRadioButtonTemplate")
radio:SetPoint("TOPLEFT", 16, -400)
radio.text = _G[radio:GetName().."Text"]
radio.text:SetFontObject("GameFontNormal")
radio.text:SetText("Hello") ]]