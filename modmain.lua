if GLOBAL.TheNet:IsDedicated() then return end
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
local TheInput = GLOBAL.TheInput
local require = GLOBAL.require

--[[
Note to modders who want to add support for custom announcements for their character:

If you just have the normal stats, just add your strings to GLOBAL.STRINGS_STATUS_ANNOUNCEMENTS,
in the format shown in announcestrings.lua

If you have a custom stat (like Woodie has beaverness), here's what you should do:
in a postinit on statusdisplays/controls, set status._custombadge = your_custom_badge
(for example, I do status._custombadge = status.wereness for Woodie)
This will make it show/hide the controller button prompt for you custom badge

Then, add onto PlayerHud's SetMainCharacter function to register your custom stat with StatusAnnouncer:

local ControllerAnnounceHUDControl = nil
local PlayerHud = require("screens/playerhud")
local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
function PlayerHud:SetMainCharacter(maincharacter, ...)
	PlayerHud_SetMainCharacter(self, maincharacter, ...)
	self.inst:DoTaskInTime(0, function()
		if self._StatusAnnouncer then
			self._StatusAnnouncer:RegisterStat(
				"My Stat's Display Name",
				HUD.controls.status._custombadge, -- you could also give it your_custom_badge
				CONTROL_ROTATE_LEFT, -- Left Bumper; keep this as-is
				{     .15,    .35,   .55,    .75      }, -- you can also set custom thresholds
				{"EMPTY", "LOW", "MID", "HIGH", "FULL"}, -- or custom category names, just match them with your strings table
				function(ThePlayer)
					return	something_that_gets_your_stats_current_value,
							something_that_gets_your_stats_max_value
				end,
				nil -- you can give this a function if your character has multiple modes with different strings, see Woodie and StatusAnnouncer:RegisterCommonStats
			)
		end
	end)
end

]]

-- Mods that are already enabled
local LANGUAGES = {
	BRAZIL = {
		"499547543",
		"383128216",
		"628971544",
		"629042840",
	},
	CHINESE = {
		"367546858",
		"624759018",
		"757621274",
		"572538624",
		"460972875",
		"609429306",
		"803906762",
	},
	GERMAN = {
		"1537789714",
		"880105914",
		"685854724",
	},
	KOREAN = {
		"1984386976",
		"1984403138",
		"2391246365",
		"2391292843",
	},
	RUSSIAN = {
		"1240565842",
		"354836336",
	},
	SPANISH = {
		"944738665",
		"1098843500",
		"885290954",
		"356494979",
	},
}
local CHECK_MODS = {
	["workshop-346479579"] = "WHISPER_ONLY",
	["workshop-376333686"] = "COMBINED_STATUS",
	["CombinedStatus"] = "COMBINED_STATUS",
}
for lang,ids in pairs(LANGUAGES) do
	for _, id in ipairs(ids) do
		CHECK_MODS["workshop-"..id] = lang:upper()
	end
end
local HAS_MOD = {}
-- If the mod is a]ready loaded at this point
for mod_name, key in pairs(CHECK_MODS) do
	HAS_MOD[key] = HAS_MOD[key] or (GLOBAL.KnownModIndex:IsModEnabled(mod_name) and mod_name)
end
-- If the mod hasn't loaded yet
for k,v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	local mod_type = CHECK_MODS[v]
	if mod_type then
		HAS_MOD[mod_type] = v
	end
end

local LANGUAGE = GetModConfigData("LANGUAGE")
if LANGUAGE == "detect" then -- We should try to detect the language
	LANGUAGE = "chinese" -- Default to chinese, but then try to detect
	for language,_ in pairs(LANGUAGES) do
		if HAS_MOD[language:upper()] then
			LANGUAGE = language:lower()
		end
	end
end
if not GLOBAL.kleifileexists(MODROOT.."announcestrings/"..LANGUAGE..".lua") then LANGUAGE = "english" end -- failsafe
modimport("announcestrings/"..LANGUAGE..".lua") -- creates the ANNOUNCE_STRINGS table

ANNOUNCE_STRINGS._.LANGUAGE = LANGUAGE -- attach it here so mods can check it if they want to provide translations
-- as emoji these are translation-independent, so add it here instead of in the language files
ANNOUNCE_STRINGS._.STAT_EMOJI = {
	Hunger = "hunger",
	Sanity = "sanity",
	Health = "heart",
	Abigail = "abigail",
	Might = "flex",
	Electric = "lightbulb",
	-- no emoji for these (yet)
	-- Wetness = "Wetness",
	-- Boat = "Boat",
	-- ["Log Meter"] = "Log Meter",
	-- Age = "Age",
	-- Inspiration = "Inspiration",
}

-- Merge the global table into ANNOUNCE_STRINGS (in case other mods run before)
if type(GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS) == "table" then
	local function merge(target, strings)
		for k, v in pairs(strings) do
			if type(v) == "table" then
				if not target[k] then
					target[k] = {}
				end
				merge(target[k], v)
			else
				target[k] = v
			end
		end
	end
	merge(ANNOUNCE_STRINGS, GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS)
end

for k in pairs(ANNOUNCE_STRINGS) do
	if k ~= "UNKNOWN" and k ~= "_" and GetModConfigData(k) == false then
		ANNOUNCE_STRINGS[k] = ANNOUNCE_STRINGS.UNKNOWN
	end
end

-- Store the merged ANNOUNCE_STRINGS in the global table (so mods that run after can add to / change it)
GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS = ANNOUNCE_STRINGS

-- This is kind of gross, but seems like the least-problematic solution
-- Mod characters aren't allowed in The Forge, so we don't have to worry about those
-- And Woodie is the only dual-form vanilla character, so we just collapse his table for The Forge
if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
	GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS.WOODIE = GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS.WOODIE.HUMAN
end

local StatusAnnouncer = require("statusannouncer")()

-- actually need this one locally to add the controller button hint
local OVERRIDEB = false
local OVERRIDESELECT = false
if HAS_MOD.COMBINED_STATUS then
	if GetModConfigData("OVERRIDEB") then
		-- Only try to do temperature if they have it configured to show temperature
		OVERRIDEB = GLOBAL.GetModConfigData("SHOWTEMPERATURE", HAS_MOD.COMBINED_STATUS)
	end
	if GetModConfigData("OVERRIDESELECT") then
		-- Only try to do temperature if they have it configured to show temperature
		OVERRIDESELECT = GLOBAL.GetModConfigData("SEASONOPTIONS", HAS_MOD.COMBINED_STATUS) ~= ""
	end
end
local HIDEANNOUNCEMENTS = GetModConfigData("HIDEANNOUNCEMENTS")
StatusAnnouncer:SetLocalParameter("WHISPER", GetModConfigData("WHISPER"))
StatusAnnouncer:SetLocalParameter("WHISPER_ONLY", HAS_MOD.WHISPER_ONLY)
StatusAnnouncer:SetLocalParameter("EXPLICIT", GetModConfigData("EXPLICIT"))
StatusAnnouncer:SetLocalParameter("TIME_STYLE", GetModConfigData("TIMESTYLE"))
StatusAnnouncer:SetLocalParameter("OVERRIDEB", OVERRIDEB)
StatusAnnouncer:SetLocalParameter("OVERRIDESELECT", OVERRIDESELECT)
StatusAnnouncer:SetLocalParameter("SHOWDURABILITY", GetModConfigData("SHOWDURABILITY"))
StatusAnnouncer:SetLocalParameter("SHOWPROTOTYPER", GetModConfigData("SHOWPROTOTYPER"))
StatusAnnouncer:SetLocalParameter("SHOWEMOJI", GetModConfigData("SHOWEMOJI"))

local PlayerHud = require("screens/playerhud")
local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
function PlayerHud:SetMainCharacter(maincharacter, ...)
	PlayerHud_SetMainCharacter(self, maincharacter, ...)
	self._StatusAnnouncer = StatusAnnouncer
	if maincharacter then
		-- Note that this also clears out the stats and cooldowns, so we have to re-register them
		StatusAnnouncer:SetCharacter(maincharacter.prefab)
		StatusAnnouncer:RegisterCommonStats(self, maincharacter.prefab)
	end
end
local PlayerHud_OnMouseButton = PlayerHud.OnMouseButton
function PlayerHud:OnMouseButton(button, down, ...)
	if button == GLOBAL.MOUSEBUTTON_LEFT and down and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		if StatusAnnouncer:OnHUDMouseButton(self) then
			return true
		end
	end
	if type(PlayerHud_OnMouseButton) == "function" then
		return PlayerHud_OnMouseButton(self, button, down, ...)
	end
end
local PlayerHud_OnControl = PlayerHud.OnControl
function PlayerHud:OnControl(control, down, ...)
	if ControllerAnnounceHUDControl and ControllerAnnounceHUDControl(control, down) then
		return true
	end
	if not down and self.owner ~= nil and self.shown and StatusAnnouncer:OnHUDControl(self, control) then
		return true
	end
	if not down and control == GLOBAL.CONTROL_OPEN_INVENTORY and self.controls.status._weremode then
		if self._statuscontrollerbuttonhintsshown then
			self:HideStatusControllerButtonHints()
		else
			self:ShowStatusControllerButtonHints()
		end
	end
	return PlayerHud_OnControl(self, control, down, ...)

end

local function find_season_badge(HUD)
	HUD = HUD or GLOBAL.ThePlayer.HUD
	if HUD.controls.seasonclock then
		return HUD.controls.seasonclock, "Clock"
	elseif HUD.controls.season then -- actually needs to get checked before Compact because they both get attached to status
		return HUD.controls.season, "Micro"
	elseif HUD.controls.status.season then
		return HUD.controls.status.season, "Compact"
	end
end

-- Hook into the controller open/close inventory to display the controller button hints
local PlayerHud_OpenControllerInventory = PlayerHud.OpenControllerInventory
function PlayerHud:OpenControllerInventory(...)
	PlayerHud_OpenControllerInventory(self, ...)
	self:ShowStatusControllerButtonHints()
end
function PlayerHud:ShowStatusControllerButtonHints()
	self._statuscontrollerbuttonhintsshown = true
	if self.controls.status._weremode then
		SetModHUDFocus("StatusAnnouncements", true)
	end
	local controller_id = TheInput:GetControllerID()
	if self.controls.status.stomach then
		self.controls.status.stomach.announce_text:Show()
		self.controls.status.stomach.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_INVENTORY_USEONSCENE))
	end
	if self.controls.status.brain then
		self.controls.status.brain.announce_text:Show()
		self.controls.status.brain.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_INVENTORY_EXAMINE))
	end
	if self.controls.status.heart then
		self.controls.status.heart.announce_text:Show()
		self.controls.status.heart.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_INVENTORY_USEONSELF))
	end
	if self.controls.status._custombadge then
		self.controls.status._custombadge.announce_text:Show()
		self.controls.status._custombadge.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_ROTATE_LEFT))
	end
	if self.controls.status.moisturemeter then
		self.controls.status.moisturemeter.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_ROTATE_RIGHT))
		self.controls.status.moisturemeter.controller_crafting_open = true
		if self.controls.status.moisturemeter.active then
			self.controls.status.moisturemeter.announce_text:Show()
		end
	end
	if self.controls.status.boatmeter and self.controls.status.boatmeter.boat ~= nil then
		self.controls.status.boatmeter.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_ROTATE_LEFT))
		self.controls.status.boatmeter.announce_text:Show()
	end
	if OVERRIDEB and self.controls.status.temperature then
		self.controls.status.temperature.announce_text:Show()
		self.controls.status.temperature.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CANCEL))
	end
	local season, _ = find_season_badge(self)
	if OVERRIDESELECT and season then
		season.announce_text:Show()
		season.announce_text:SetString(
			TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_MAP))
	end
end
local PlayerHud_CloseControllerInventory = PlayerHud.CloseControllerInventory
function PlayerHud:CloseControllerInventory(...)
	PlayerHud_CloseControllerInventory(self, ...)
	self:HideStatusControllerButtonHints()
end
function PlayerHud:HideStatusControllerButtonHints()
	self._statuscontrollerbuttonhintsshown = false
	SetModHUDFocus("StatusAnnouncements", false)
	if self.controls.status.stomach then
		self.controls.status.stomach.announce_text:Hide()
	end
	if self.controls.status.brain then
		self.controls.status.brain.announce_text:Hide()
	end
	if self.controls.status.heart then
		self.controls.status.heart.announce_text:Hide()
	end
	if self.controls.status._custombadge then
		self.controls.status._custombadge.announce_text:Hide()
	end
	if self.controls.status.moisturemeter then
		self.controls.status.moisturemeter.controller_crafting_open = false
		self.controls.status.moisturemeter.announce_text:Hide()
	end
	if self.controls.status.boatmeter then
		self.controls.status.boatmeter.announce_text:Hide()
	end
	if OVERRIDEB and self.controls.status.temperature then
		self.controls.status.temperature.announce_text:Hide()
	end
	local season, _ = find_season_badge(self)
	if OVERRIDESELECT and season then
		season.announce_text:Hide()
	end
end

-- Adds the controller button hints to the stat badges
local Text = GLOBAL.require("widgets/text")
AddClassPostConstruct("widgets/statusdisplays", function(self)
	if self.stomach then
		self.stomach.announce_text = self.stomach:AddChild(Text(GLOBAL.UIFONT, 30))
		self.stomach.announce_text:SetPosition(-30, 0)
		self.stomach.announce_text:Hide()
	end
	if self.brain then
		self.brain.announce_text = self.brain:AddChild(Text(GLOBAL.UIFONT, 30))
		self.brain.announce_text:SetPosition(0, 30)
		self.brain.announce_text:Hide()
	end
	if self.heart then
		self.heart.announce_text = self.heart:AddChild(Text(GLOBAL.UIFONT, 30))
		self.heart.announce_text:SetPosition(30, 0)
		self.heart.announce_text:Hide()
	end
	if self.wereness then
		self._custombadge = self.wereness
	end
	if self.inspirationbadge then
		self._custombadge = self.inspirationbadge
	end
	-- This was mainly to set up controller button hints, but we no longer have a spare button for these
	-- (it was given away to announcing boat health)
	-- I'm leaving the _custombadge code around in case I find another solution that could use this
	self._custombadge = nil
	self.inst:DoTaskInTime(0, function()
		if self._custombadge then
			self._custombadge.announce_text = self._custombadge:AddChild(Text(GLOBAL.UIFONT, 30))
			self._custombadge.announce_text:SetPosition(30*math.cos(math.pi*.6), 30*math.sin(math.pi*.6))
			self._custombadge.announce_text:Hide()
		end
	end)
	if self.moisturemeter then
		self.moisturemeter.announce_text = self.moisturemeter:AddChild(Text(GLOBAL.UIFONT, 30))
		self.moisturemeter.announce_text:SetPosition(30*math.cos(math.pi*.4), 30*math.sin(math.pi*.4))
		self.moisturemeter.announce_text:Hide()
		local _Activate = self.moisturemeter.Activate
		function self.moisturemeter:Activate(...)
			_Activate(self, ...)
			self.activated = true
			if self.controller_crafting_open then
				self.announce_text:Show()
			end
		end
		local _Deactivate = self.moisturemeter.Deactivate
		function self.moisturemeter:Deactivate(...)
			_Deactivate(self, ...)
			self.activated = false
			if self.controller_crafting_open then
				self.announce_text:Hide()
			end
		end
	end
	if self.boatmeter then
		self.boatmeter.announce_text = self.boatmeter:AddChild(Text(GLOBAL.UIFONT, 30))
		self.boatmeter.announce_text:SetPosition(30*math.cos(math.pi*.6), 30*math.sin(math.pi*.6))
		self.boatmeter.announce_text:Hide()
	end
	if OVERRIDEB then
		-- delay it until Combined Status loads
		self._override_b_task = self.inst:DoPeriodicTask(0, function()
			if self.temperature then -- If Combined Status has loaded, add the button hint
				self.temperature.announce_text = self.temperature:AddChild(Text(GLOBAL.UIFONT, 30))
				self.temperature.announce_text:SetPosition(25, -50)
				self.temperature.announce_text:Hide()
				-- We succeeded, clear the task
				self._override_b_task:Cancel()
				self._override_b_task = nil
			end
		end)
	end
	if OVERRIDESELECT then
		-- delay it until Combined Status loads
		self._override_select_task = self.inst:DoPeriodicTask(0, function()
			local season, season_type = find_season_badge()
			if season then -- If Combined Status has loaded, add the button hint
				season.announce_text = season:AddChild(Text(GLOBAL.UIFONT, 30))
				if season_type == "Clock" then
					season.announce_text:SetPosition(0, -52)
				elseif season_type == "Compact" then
					season.announce_text:SetPosition(0, -75)
				elseif season_type == "Micro" then
					season.announce_text:SetPosition(40, -30)
				end
				season.announce_text:Hide()
				-- We succeeded, clear the task
				self._override_select_task:Cancel()
				self._override_select_task = nil
			end
		end)
	end
	local _SetWereMode = self.SetWereMode
	function self:SetWereMode(weremode, ...)
		self._weremode = weremode
		-- if self.isghostmode or self.wereness == nil then return end
		_SetWereMode(self, weremode, ...)
	end
end)

local function GetIngredientName(NAMES, prefabname)
	if type(prefabname) ~= "string" then return "UNKNOWN INGREDIENT" end
	return NAMES[prefabname:upper()] or prefabname
end

-- Capture mouse clicks on recipes
local function GetClickedIngredient(recipe, craftingmenu_ingredients)
	if recipe == nil or craftingmenu_ingredients == nil then
		return nil
	end
	local _, ingredient_root = GLOBAL.next(craftingmenu_ingredients.children)
	if ingredient_root == nil then
		-- this occurs if the ingredients have never been expanded on a pinned item
		return nil
	end
	local ingredient = nil
	local NAMES = GLOBAL.STRINGS.NAMES
	local name_to_ingredient = {}
	for i, v in ipairs(recipe.tech_ingredients) do
		name_to_ingredient[GetIngredientName(NAMES, v.type)] = v.type
	end
	for i, v in ipairs(recipe.ingredients) do
		name_to_ingredient[GetIngredientName(NAMES, v.type)] = v.type
	end
	for i, v in ipairs(recipe.character_ingredients) do
		name_to_ingredient[GetIngredientName(NAMES, v.type)] = v.type
	end
	local focused_ingredient = nil
	for k,v in pairs(ingredient_root.children) do
		if v.focus then
			focused_ingredient = v
		end
	end
	if focused_ingredient then
		ingredient = name_to_ingredient[focused_ingredient.tooltip]
	end
	return ingredient
end
local CraftingMenuHUD = require("widgets/redux/craftingmenu_hud")
local CraftingMenuHUD_OnControl = CraftingMenuHUD.OnControl
function CraftingMenuHUD:OnControl(control, down, ...)
	if down and control == GLOBAL.CONTROL_ACCEPT
	and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT)
	and self.owner then

		-- Check if we're clicking on a pinned recipe or its ingredient
		if self.pinbar.focus then
			for _,slot in ipairs(self.pinbar.pin_slots) do
				if slot.focus then
					local recipe = GLOBAL.AllRecipes[slot.recipe_name]
					local ingredient = GetClickedIngredient(recipe, slot.recipe_popup.ingredients)
					return StatusAnnouncer:AnnounceRecipe(recipe, ingredient)
				end
			end
			return false
		end

		-- Only the pinbar can get clicked without crafting being open.
		-- If we don't short-circuit here then it will announce whatever the last displayed recipe was,
		-- even if we just click on the sliver of the menu on the edge
		if not self:IsCraftingOpen() then
			return false
		end

		-- Check to see if we're clicking on a recipe tile in the grid
		local recipe_grid = self.craftingmenu.recipe_grid
		local last_focused_recipe = recipe_grid.widgets_to_update[recipe_grid.focused_widget_index]
		if last_focused_recipe.focus then
			-- The mouse was over this recipe when it clicked
			return StatusAnnouncer:AnnounceRecipe(last_focused_recipe.data.recipe)
		end

		local crafting_details = self.craftingmenu.details_root
		local recipe = type(crafting_details.data) == "table" and crafting_details.data.recipe
		if not recipe then return false end
		-- Check if we clicked on a skin
		if crafting_details.skins_spinner.focus then
			local skin = crafting_details.skins_spinner:GetItem()
			if skin then
				return StatusAnnouncer:AnnounceSkin(recipe, skin)
			end
			-- If it was set to default, consider this a normal "announce item"
		end

		-- Check if an ingredient in the description got clicked
		local ingredient = GetClickedIngredient(recipe, crafting_details.ingredients)

		-- Default to announcing the current selected recipe, passing in ingredient if found
		return StatusAnnouncer:AnnounceRecipe(recipe, ingredient)
	elseif not TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		return CraftingMenuHUD_OnControl(self, control, down, ...)
	end
end
local CraftingMenuHUD_RefreshCraftingHelpText = CraftingMenuHUD.RefreshCraftingHelpText
function CraftingMenuHUD:RefreshCraftingHelpText(...)
	CraftingMenuHUD_RefreshCraftingHelpText(self, ...)
	if self.is_open then
		local hint = self.nav_hint:GetString()
		hint = hint .. "  " .. TheInput:GetLocalizedControl(TheInput:GetControllerID(), GLOBAL.CONTROL_CANCEL) .. " " .. ANNOUNCE_STRINGS._.ANNOUNCE_HINT
		self.nav_hint:SetString(hint)
	end
end

-- Captures mouse clicks on inventory items, and prevents them from doing other stuff if we announced
for _,classname in pairs({"invslot", "equipslot"}) do
	local SlotClass = require("widgets/"..classname)
	local SlotClass_OnControl = SlotClass.OnControl
	function SlotClass:OnControl(control, down, ...)
		if down and control == GLOBAL.CONTROL_ACCEPT
			and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT)
			and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE)
			and self.tile then -- ignore empty slots
			return StatusAnnouncer:AnnounceItem(self)
		else
			return SlotClass_OnControl(self, control, down, ...)
		end
	end
end

local InventoryBar = require("widgets/inventorybar")
-- Captures controller input for inventory
local InventoryBar_OnControl = InventoryBar.OnControl
function InventoryBar:OnControl(control, down, ...)
	if InventoryBar_OnControl(self, control, down, ...) then return true end -- prioritize normal controls
	-- catch a few other "do nothing" scenarios
	if down or not self.open then return end

	local inv_item = self:GetCursorItem() -- this is the active inventory tile item
	if control == GLOBAL.CONTROL_USE_ITEM_ON_ITEM and inv_item then -- Y button
		-- We shouldn't actually need to check if it's the other scenario for this,
		-- because it would've returned true above
		-- also, GetCursorItem() returns nil if there's no active slot, so we know it exists
		return StatusAnnouncer:AnnounceItem(self.active_slot)
	end
end
-- Add the Announce hint text
local InventoryBar_UpdateCursorText = InventoryBar.UpdateCursorText
function InventoryBar:UpdateCursorText(...)
	InventoryBar_UpdateCursorText(self, ...)
	if TheInput:ControllerAttached() and self.open then
		if self:GetCursorItem() and not self.owner.replica.inventory:GetActiveItem() then
			self.actionstringbody:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), GLOBAL.CONTROL_USE_ITEM_ON_ITEM)
				.." "..ANNOUNCE_STRINGS._.ANNOUNCE_HINT.."\n"..self.actionstringbody:GetString())
		end
	end
end

AddClassPostConstruct("widgets/giftitemtoast", function(self)
	local _OnMouseButton = self.OnMouseButton
	function self:OnMouseButton(button, down, ...)
		local ret = _OnMouseButton(self, button, down, ...)
		if button == GLOBAL.MOUSEBUTTON_LEFT and down and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
			StatusAnnouncer:Announce(self.enabled
								and ANNOUNCE_STRINGS._.ANNOUNCE_GIFT.CAN_OPEN
								or ANNOUNCE_STRINGS._.ANNOUNCE_GIFT.NEED_SCIENCE)
		end
	end
end)

local UpgradeModulesDisplay = require("widgets/upgrademodulesdisplay")
local UpgradeModulesDisplay_OnControl = UpgradeModulesDisplay.OnControl
function UpgradeModulesDisplay:OnControl(control, down, ...)
	local ret = UpgradeModulesDisplay_OnControl(self, control, down, ...)
	if control == GLOBAL.CONTROL_ACCEPT and down and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		StatusAnnouncer:AnnounceWxCircuits(self)
	end
	return ret
end

if HIDEANNOUNCEMENTS then
	local function IsStatusAnnouncementMessage(message)
		return type(message) == "string" and message:len() > 3 and message:sub(1,3) == GLOBAL.STRINGS.LMB
	end
	local ChatHistory = GLOBAL.ChatHistory
	-- Don't add new messages if they're announcements
	local _ChatHistory_AddToHistory = ChatHistory.AddToHistory
	function ChatHistory:AddToHistory(type, sender_userid, sender_netid, sender_name, message, ...)
		if IsStatusAnnouncementMessage(message) then
			return
		end
		return _ChatHistory_AddToHistory(self, type, sender_userid, sender_netid, sender_name, message, ...)
	end
	-- Don't add historical messages if they're announcements
	local _ChatHistory_AddToHistoryAtIndex = ChatHistory.AddToHistoryAtIndex
	function ChatHistory:AddToHistoryAtIndex(chat_message, ...)
		if type(chat_message) == "table" then
			local new_chat_message = {}
			local count = math.max(#chat_message, 1)
			if count > 1 then
				for i, v in ipairs(chat_message) do
					if not IsStatusAnnouncementMessage(v.message) then
						table.insert(new_chat_message, v)
					end
					-- Otherwise, we don't copy it over to new_chat_message
				end
			else
				if not IsStatusAnnouncementMessage(chat_message.message) then
					new_chat_message = chat_message
				end
				-- Otherwise, we leave new_chat_message an empty table, which it does handle
			end
			chat_message = new_chat_message
		end
		return _ChatHistory_AddToHistoryAtIndex(self, chat_message, ...)
	end
	-- Don't activate the overhead text and "blah blah blah" animation/sounds if it's an announcement
	local Talker = require("components/talker")
	local _Talker_Say = Talker.Say
	function Talker:Say(script, ...)
		if IsStatusAnnouncementMessage(script) then
			return
		end
		return _Talker_Say(self, script, ...)
	end
end

--同屏宣告，来自某位大佬
local function InGame()
    return GLOBAL.ThePlayer and  GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

local function IsMissingDisplayName(name)
	return type(name) ~= "string"
		or name:find("^%s*$") ~= nil
		or name:upper():find("MISSING NAME", 1, true) ~= nil
end

local function GetFallbackName(item)
	local prefab = item and item.prefab
	if type(prefab) ~= "string" then
		return ""
	end
	local name = GLOBAL.STRINGS.NAMES[prefab:upper()]
	return not IsMissingDisplayName(name) and name or prefab:gsub("_", " ")
end

local function GetBasicName(item)
	local name = item and item.GetBasicDisplayName and item:GetBasicDisplayName() or nil
	return not IsMissingDisplayName(name) and name or GetFallbackName(item)
end

local function GetDescriptionString(item)
    if item == nil then
        return ""
    end
	local name = item.GetDisplayName and item:GetDisplayName() or GetBasicName(item)
	if IsMissingDisplayName(name) then
		name = GetFallbackName(item)
	end
    local adjective = item:GetAdjective()
    return adjective ~= nil and (adjective.." "..name) or name
end

local function AnnounceWorldEntity(ent, player, single)
	if not ent or not ent:IsValid() or not ent.prefab then
		return false
	end
	if ent == player then
		return false
	end
	if ent:HasTag("player") and ent.name then
		return StatusAnnouncer:AnnouncePeople(ent)
	end

	local x, y, z = player.Transform:GetWorldPosition()
	local distance = math.floor(ent:GetDistanceSqToPoint(x, y, z)^0.5 / 4 * 10) / 10
	local name2 = GetDescriptionString(ent)
	if single then
		return StatusAnnouncer:AnnounceSingle(name2, distance, ent)
	end

	local count1 = 0
	local count2 = 0
	local name1 = GLOBAL.STRINGS.NAMES[ent.prefab:upper()]
	if IsMissingDisplayName(name1) then
		name1 = GetBasicName(ent)
	end
	name1 = name1:gsub("{item}", ""):gsub("^%s+", ""):gsub("%s+$", "")

	local ents = GLOBAL.TheSim:FindEntities(x, 0, z, 80, nil, {"FX", "DECOR", "INLIMBO", "NOCLICK"})
	for _, v in pairs(ents) do
		if v.prefab == ent.prefab and v ~= player then
			local stackable = v.replica and v.replica.stackable
			local stack_size = stackable and stackable:StackSize() or 1
			count1 = count1 + stack_size
			if GetDescriptionString(v) == name2 then
				count2 = count2 + stack_size
			end
		end
	end

	return StatusAnnouncer:AnnounceCount(count1, name1, count2, name2, distance, ent)
end

local cooldown = false
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= GLOBAL.ThePlayer then return end
    local PlayerControllerOnControl = self.OnControl

	local function CancelControllerHoldTask()
		if self._statusannounce_hold_task then
			self._statusannounce_hold_task:Cancel()
			self._statusannounce_hold_task = nil
		end
	end

	local function ClearControllerTarget()
		local highlight = self._statusannounce_highlight
		if highlight and highlight:IsValid() and highlight.AnimState then
			highlight.AnimState:SetHighlightColour()
		end
		self._statusannounce_highlight = nil
		self._statusannounce_target = nil
		if self._statusannounce_list then
			self._statusannounce_list:Hide()
		end
	end

	local function ExitControllerAnnounceMode()
		CancelControllerHoldTask()
		ClearControllerTarget()
		SetModHUDFocus("ControllerAnnounce", false)
		self._statusannounce_mode = false
		self._statusannounce_hold_elapsed = nil
		self._statusannounce_targets = nil
		self._statusannounce_target_index = nil
	end

	local function IsControllerTargetOnScreen(ent)
		if not ent or not ent.Transform then
			return false
		end
		local world_x, world_y, world_z
		if ent.AnimState then
			world_x, world_y, world_z = ent.AnimState:GetSymbolPosition("", 0, 0, 0)
		else
			world_x, world_y, world_z = ent.Transform:GetWorldPosition()
		end
		local screen_x, screen_y = GLOBAL.TheSim:GetScreenPos(world_x, world_y, world_z)
		local screen_width, screen_height = GLOBAL.TheSim:GetScreenSize()
		local min_x = screen_width * .25
		local max_x = screen_width * .75
		local min_y = screen_height * .25
		local max_y = screen_height * .75
		return screen_x ~= nil
			and screen_y ~= nil
			and screen_x >= min_x
			and screen_x <= max_x
			and screen_y >= min_y
			and screen_y <= max_y
	end

	local function IsControllerAnnounceTarget(ent)
		return ent ~= nil
			and ent ~= inst
			and ent:IsValid()
			and type(ent.prefab) == "string"
			and ent.Transform ~= nil
			and ent.AnimState ~= nil
			and not ent:HasTag("FX")
			and not ent:HasTag("DECOR")
			and not ent:HasTag("INLIMBO")
			and not ent:HasTag("NOCLICK")
			and IsControllerTargetOnScreen(ent)
			and (GLOBAL.CanEntitySeeTarget == nil or GLOBAL.CanEntitySeeTarget(inst, ent))
	end

	local function GetControllerAnnounceTargets()
		local x, y, z = inst.Transform:GetWorldPosition()
		local targets = GLOBAL.TheSim:FindEntities(x, y, z, 80, nil, {"FX", "DECOR", "INLIMBO", "NOCLICK"})
		local grouped = {}
		local keys = {}
		for _, ent in ipairs(targets) do
			if IsControllerAnnounceTarget(ent) then
				local name = GetDescriptionString(ent):gsub("[\r\n]+", " ")
				local key = ent.prefab .. "\0" .. name
				local entry = grouped[key]
				local stackable = ent.replica and ent.replica.stackable
				local stack_size = stackable and stackable:StackSize() or 1
				local distance_sq = inst:GetDistanceSqToInst(ent)
				if entry then
					entry.count = entry.count + stack_size
					if distance_sq < entry.distance_sq then
						entry.target = ent
						entry.distance_sq = distance_sq
					end
				else
					entry = {
						target = ent,
						name = name,
						count = stack_size,
						distance_sq = distance_sq,
					}
					grouped[key] = entry
					table.insert(keys, key)
				end
			end
		end
		local entries = {}
		for _, key in ipairs(keys) do
			table.insert(entries, grouped[key])
		end
		table.sort(entries, function(a, b)
			return a.distance_sq < b.distance_sq
		end)
		return entries
	end

	local CONTROLLER_LIST_ROWS = 9

	local function EnsureControllerList()
		if self._statusannounce_list or not inst.HUD or not inst.HUD.controls then
			return
		end
		local Widget = require("widgets/widget")
		local Image = require("widgets/image")
		local Text = require("widgets/text")
		local root = inst.HUD.controls:AddChild(Widget("statusannounce_controller_list"))
		root:SetPosition(320, 30)
		root.bg = root:AddChild(Image("images/global.xml", "square.tex"))
		root.bg:SetSize(610, 430)
		root.bg:SetTint(0, 0, 0, .78)
		root.title = root:AddChild(Text(GLOBAL.HEADERFONT, 34, ""))
		root.title:SetPosition(0, 175)
		root.rows = {}
		for i = 1, CONTROLLER_LIST_ROWS do
			local row = root:AddChild(Text(GLOBAL.BODYTEXTFONT, 27, ""))
			row:SetRegionSize(550, 34)
			row:SetHAlign(GLOBAL.ANCHOR_LEFT)
			row:SetPosition(0, 132 - (i - 1) * 34)
			row:Hide()
			root.rows[i] = row
		end
		root.footer = root:AddChild(Text(GLOBAL.BODYTEXTFONT, 25, ""))
		root.footer:SetRegionSize(560, 60)
		root.footer:SetPosition(0, -165)
		self._statusannounce_list = root
		root:Hide()
	end

	local function UpdateControllerList()
		EnsureControllerList()
		local root = self._statusannounce_list
		local entries = self._statusannounce_targets or {}
		local selected = self._statusannounce_target_index or 1
		if not root or #entries == 0 then
			return
		end

		local strings = ANNOUNCE_STRINGS._.CONTROLLER_MODE
		root.title:SetString(string.format("%s  %d/%d", strings.TITLE, selected, #entries))
		local first = math.max(1, math.min(selected - math.floor(CONTROLLER_LIST_ROWS / 2), #entries - CONTROLLER_LIST_ROWS + 1))
		for row_index, row in ipairs(root.rows) do
			local entry_index = first + row_index - 1
			local entry = entries[entry_index]
			if entry then
				local marker = entry_index == selected and "> " or "  "
				local count = entry.count > 1 and ("  x" .. tostring(entry.count)) or ""
				local distance = math.floor(math.sqrt(entry.distance_sq) / 4 * 10) / 10
				row:SetString(string.format("%s%s%s  [%.1f]", marker, entry.name, count, distance))
				if entry_index == selected then
					row:SetColour(1, .82, .25, 1)
				else
					row:SetColour(.9, .9, .9, 1)
				end
				row:Show()
			else
				row:Hide()
			end
		end

		local controller_id = TheInput:GetControllerID()
		local single_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION)
		local group_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ATTACK)
		local cancel_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ALTACTION)
		root.footer:SetString(string.format(
			"%s   %s %s   %s %s   %s %s",
			strings.SWITCH,
			single_control,
			strings.SINGLE,
			group_control,
			strings.GROUP,
			cancel_control,
			strings.CANCEL
		))
		root:Show()
	end

	local function SetControllerAnnounceTarget(entry)
		ClearControllerTarget()
		local target = entry and entry.target
		if not IsControllerAnnounceTarget(target) then
			return false
		end

		self._statusannounce_target = target
		local highlight = target.highlightforward or target
		if highlight.AnimState then
			highlight.AnimState:SetHighlightColour(.35, .35, .1, 0)
			self._statusannounce_highlight = highlight
		end

		UpdateControllerList()
		return true
	end

	local function EnterControllerAnnounceMode()
		self._statusannounce_hold_task = nil
		self._statusannounce_hold_elapsed = true
		if not TheInput:ControllerAttached()
			or not InGame()
			or not inst.HUD
			or (inst.HUD.IsControllerInventoryOpen and inst.HUD:IsControllerInventoryOpen()) then
			return
		end

		local targets = GetControllerAnnounceTargets()
		if #targets == 0 then
			return
		end

		self._statusannounce_mode = true
		self._statusannounce_targets = targets
		local preferred = self:GetControllerTarget() or self:GetControllerAttackTarget()
		local index = 1
		if preferred then
			for i, entry in ipairs(targets) do
				if entry.target == preferred then
					index = i
					break
				end
			end
		end
		self._statusannounce_target_index = index
		SetModHUDFocus("ControllerAnnounce", true)
		SetControllerAnnounceTarget(targets[index])
	end

	local function CycleControllerAnnounceTarget(step)
		local current = self._statusannounce_target
		local targets = GetControllerAnnounceTargets()
		if #targets == 0 then
			ExitControllerAnnounceMode()
			return
		end

		local index = 0
		for i, entry in ipairs(targets) do
			if entry.target == current then
				index = i
				break
			end
		end
		index = ((index - 1 + step) % #targets) + 1
		self._statusannounce_targets = targets
		self._statusannounce_target_index = index
		SetControllerAnnounceTarget(targets[index])
	end

	local controller_next_controls = {
		[GLOBAL.CONTROL_MOVE_DOWN] = true,
		[GLOBAL.CONTROL_MOVE_RIGHT] = true,
	}
	local controller_previous_controls = {
		[GLOBAL.CONTROL_MOVE_UP] = true,
		[GLOBAL.CONTROL_MOVE_LEFT] = true,
	}

	local function HandleControllerAnnounceControl(control, down)
		if not TheInput:ControllerAttached() then
			if self._statusannounce_mode then
				ExitControllerAnnounceMode()
			end
			return false
		elseif not self._statusannounce_mode then
			if control ~= GLOBAL.CONTROL_INSPECT then
				return false
			end
			local is_holding = self._statusannounce_hold_task ~= nil
				or self._statusannounce_hold_elapsed ~= nil
			local can_start = InGame()
				and inst.HUD ~= nil
				and (not inst.HUD.IsControllerInventoryOpen or not inst.HUD:IsControllerInventoryOpen())
			if down and can_start then
				CancelControllerHoldTask()
				self._statusannounce_hold_elapsed = false
				self._statusannounce_hold_task = inst:DoTaskInTime(.5, EnterControllerAnnounceMode)
				return true
			elseif not down and is_holding then
				local should_inspect = self._statusannounce_hold_task ~= nil
					or self._statusannounce_hold_elapsed == true
				CancelControllerHoldTask()
				self._statusannounce_hold_elapsed = nil
				if should_inspect then
					if self:GetControllerTarget() == nil and inst.HUD.InspectSelf then
						inst.HUD:InspectSelf()
					else
						PlayerControllerOnControl(self, control, true)
						PlayerControllerOnControl(self, control, false)
					end
				end
				return true
			end
			return false
		elseif controller_next_controls[control] then
			if down then
				CycleControllerAnnounceTarget(1)
			end
			return true
		elseif controller_previous_controls[control] then
			if down then
				CycleControllerAnnounceTarget(-1)
			end
			return true
		elseif control == GLOBAL.CONTROL_CONTROLLER_ACTION or control == GLOBAL.CONTROL_ACCEPT then
			if down and self._statusannounce_target then
				AnnounceWorldEntity(self._statusannounce_target, inst, true)
				ExitControllerAnnounceMode()
			end
			return true
		elseif control == GLOBAL.CONTROL_CONTROLLER_ATTACK then
			if down and self._statusannounce_target then
				AnnounceWorldEntity(self._statusannounce_target, inst, false)
				ExitControllerAnnounceMode()
			end
			return true
		elseif control == GLOBAL.CONTROL_CONTROLLER_ALTACTION or control == GLOBAL.CONTROL_CANCEL then
			if down then
				ExitControllerAnnounceMode()
			end
			return true
		elseif control == GLOBAL.CONTROL_INSPECT then
			return true
		elseif control == GLOBAL.CONTROL_OPEN_INVENTORY
			or control == GLOBAL.CONTROL_OPEN_CRAFTING
			or control == GLOBAL.CONTROL_MAP
			or control == GLOBAL.CONTROL_PAUSE then
			ExitControllerAnnounceMode()
			return false
		end
		return false
	end

	ControllerAnnounceHUDControl = HandleControllerAnnounceControl

    self.OnControl = function(self, control, down, ...)
		if TheInput:ControllerAttached() then
			if HandleControllerAnnounceControl(control, down) then
				return true
			end
		end

        if InGame() and not cooldown
		 
		and (control == GLOBAL.CONTROL_PRIMARY or  control == GLOBAL.CONTROL_SECONDARY )-- 鼠标左右键点击
		and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) -- 键盘ALT
		and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) -- 键盘SHIFT
		and not GLOBAL.TheInput:GetHUDEntityUnderMouse() -- 鼠标下不是HUD
		then
			cooldown = GLOBAL.ThePlayer:DoTaskInTime(1, function()
				cooldown = false		-- 1秒CD
			end)

			local ent = GLOBAL.TheInput:GetWorldEntityUnderMouse()
			if ent and ent.prefab then
				return AnnounceWorldEntity(ent, inst, control == GLOBAL.CONTROL_SECONDARY)
			end
        end
        return PlayerControllerOnControl(self, control, down, ...)
    end

	inst:ListenForEvent("onremove", function()
		ExitControllerAnnounceMode()
		ControllerAnnounceHUDControl = nil
	end)
end)

--ping宣告
local PlayerStatusScreen =  require("screens/playerstatusscreen")
local PlayerStatusScreen_OnControl = PlayerStatusScreen.OnControl
function PlayerStatusScreen:OnControl(control, down, ...)
    if control == GLOBAL.CONTROL_ACCEPT and down and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		for _, playerListing in pairs(self.player_widgets or {}) do
			if playerListing.perf and playerListing.perf.focus then
				StatusAnnouncer:AnnouncePing(playerListing)
				break
			end
		end
	end
    return PlayerStatusScreen_OnControl(self, control, down, ...)
end
