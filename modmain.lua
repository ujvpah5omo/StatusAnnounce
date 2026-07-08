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

local function IsEntityInAnnouncementScreenRange(ent, viewer)
	if not ent or not ent.Transform then
		return false
	end
	if GLOBAL.CanEntitySeeTarget ~= nil and viewer ~= nil and not GLOBAL.CanEntitySeeTarget(viewer, ent) then
		return false
	end
	local world_x, world_y, world_z
	if ent.AnimState then
		world_x, world_y, world_z = ent.AnimState:GetSymbolPosition("", 0, 0, 0)
	end
	if world_x == nil then
		world_x, world_y, world_z = ent.Transform:GetWorldPosition()
	end
	local screen_x, screen_y = GLOBAL.TheSim:GetScreenPos(world_x, world_y, world_z)
	local screen_width, screen_height = GLOBAL.TheSim:GetScreenSize()
	return screen_x ~= nil
		and screen_y ~= nil
		and screen_x >= 0
		and screen_x <= screen_width
		and screen_y >= 0
		and screen_y <= screen_height
end

local function AnnounceWorldEntity(ent, player, single)
	if not ent or not ent:IsValid() or not ent.prefab then
		return false
	end
	if ent == player then
		return false
	end
	if not IsEntityInAnnouncementScreenRange(ent, player) then
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
		if v.prefab == ent.prefab and v ~= player and IsEntityInAnnouncementScreenRange(v, player) then
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

	local function ExitControllerAnnounceMode(preserve_swallow_controls)
		CancelControllerHoldTask()
		ClearControllerTarget()
		SetModHUDFocus("ControllerAnnounce", false)
		self._statusannounce_mode = false
		self._statusannounce_hold_elapsed = nil
		self._statusannounce_targets = nil
		self._statusannounce_target_index = nil
		self._statusannounce_target_page = nil
		self._statusannounce_waiting_for_inspect_release = nil
		if not preserve_swallow_controls then
			self._statusannounce_swallow_controls = nil
		end
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
			and IsEntityInAnnouncementScreenRange(ent, inst)
	end

	local CONTROLLER_WHEEL_SLOTS = 8
	local CONTROLLER_WHEEL_RADIUS = 210
	local CONTROLLER_WHEEL_LABEL_WIDTH = 132
	local CONTROLLER_WHEEL_LABEL_HEIGHT = 70
	local CONTROLLER_WHEEL_TEXT_SIZE = 36
	local CONTROLLER_WHEEL_TEXT_MIN_WIDTH = 132
	local CONTROLLER_WHEEL_TEXT_MAX_WIDTH = 320
	local CONTROLLER_WHEEL_CENTER_Y_OFFSET = 70

	local function GetControllerWheelUtf8Codepoint(text, index)
		local byte1 = text:byte(index)
		if byte1 == nil then
			return nil, index + 1
		elseif byte1 < 0x80 then
			return byte1, index + 1
		elseif byte1 < 0xE0 then
			local byte2 = text:byte(index + 1) or 0
			return (byte1 - 0xC0) * 0x40 + (byte2 - 0x80), index + 2
		elseif byte1 < 0xF0 then
			local byte2 = text:byte(index + 1) or 0
			local byte3 = text:byte(index + 2) or 0
			return (byte1 - 0xE0) * 0x1000 + (byte2 - 0x80) * 0x40 + (byte3 - 0x80), index + 3
		else
			local byte2 = text:byte(index + 1) or 0
			local byte3 = text:byte(index + 2) or 0
			local byte4 = text:byte(index + 3) or 0
			return (byte1 - 0xF0) * 0x40000 + (byte2 - 0x80) * 0x1000 + (byte3 - 0x80) * 0x40 + (byte4 - 0x80), index + 4
		end
	end

	local function IsControllerWheelChineseCodepoint(codepoint)
		return codepoint ~= nil
			and ((codepoint >= 0x3400 and codepoint <= 0x4DBF) -- CJK Extension A
				or (codepoint >= 0x4E00 and codepoint <= 0x9FFF) -- CJK Unified Ideographs
				or (codepoint >= 0xF900 and codepoint <= 0xFAFF) -- CJK Compatibility Ideographs
				or (codepoint >= 0x20000 and codepoint <= 0x2A6DF)
				or (codepoint >= 0x2A700 and codepoint <= 0x2B73F)
				or (codepoint >= 0x2B740 and codepoint <= 0x2B81F)
				or (codepoint >= 0x2B820 and codepoint <= 0x2CEAF))
	end

	local function GetControllerWheelTextUnits(text)
		text = type(text) == "string" and text or ""
		local units = 0
		local index = 1
		while index <= #text do
			local codepoint
			codepoint, index = GetControllerWheelUtf8Codepoint(text, index)
			if IsControllerWheelChineseCodepoint(codepoint) then
				units = units + 1
			elseif codepoint ~= nil and codepoint < 0x80 then
				units = units + .55
			else
				units = units + 1
			end
		end
		return units
	end

	local function GetControllerWheelTextSize(text, max_size, min_size)
		local units = GetControllerWheelTextUnits(text)
		if units <= 8 then
			return max_size
		elseif units <= 14 then
			return math.max(min_size, max_size - 4)
		elseif units <= 20 then
			return math.max(min_size, max_size - 8)
		end
		return min_size
	end

	local function GetControllerWheelTextWidth(text)
		local width = 64 + GetControllerWheelTextUnits(text) * 17
		return math.max(CONTROLLER_WHEEL_TEXT_MIN_WIDTH, math.min(CONTROLLER_WHEEL_TEXT_MAX_WIDTH, width))
	end

	local function FormatControllerWheelName(name)
		name = type(name) == "string" and name or ""
		return name
	end

	local function GetControllerAnnounceIcon(ent)
		local inventoryitem = ent and ent.replica and ent.replica.inventoryitem
		local image = inventoryitem and inventoryitem.GetImage and inventoryitem:GetImage() or nil
		local atlas = inventoryitem and inventoryitem.GetAtlas and inventoryitem:GetAtlas() or nil
		if atlas == nil and image ~= nil and GLOBAL.GetInventoryItemAtlas then
			atlas = GLOBAL.GetInventoryItemAtlas(image)
		end
		return atlas, image
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
				local atlas, image = GetControllerAnnounceIcon(ent)
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
						atlas = atlas,
						image = image,
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

	local function EnsureControllerList()
		if self._statusannounce_list or not inst.HUD or not inst.HUD.controls then
			return
		end
		local Widget = require("widgets/widget")
		local Image = require("widgets/image")
		local Text = require("widgets/text")
		local root = inst.HUD.controls:AddChild(Widget("statusannounce_controller_wheel"))
		root:SetPosition(0, 0)
		root.title = root:AddChild(Text(GLOBAL.HEADERFONT, 34, ""))
		root.slots = {}
		for i = 1, CONTROLLER_WHEEL_SLOTS do
			local slot = root:AddChild(Widget("statusannounce_controller_wheel_slot"))
			slot.bg = slot:AddChild(Image("images/global.xml", "square.tex"))
			slot.bg:SetSize(CONTROLLER_WHEEL_LABEL_WIDTH, CONTROLLER_WHEEL_LABEL_HEIGHT)
			slot.bg:SetTint(0, 0, 0, .58)
			slot.icon = slot:AddChild(Image("images/global.xml", "square.tex"))
			slot.icon:SetSize(46, 46)
			slot.icon:Hide()
			slot.text = slot:AddChild(Text(GLOBAL.BODYTEXTFONT, CONTROLLER_WHEEL_TEXT_SIZE, ""))
			slot.text:SetRegionSize(CONTROLLER_WHEEL_TEXT_MIN_WIDTH, CONTROLLER_WHEEL_LABEL_HEIGHT)
			if slot.text.EnableWordWrap then
				slot.text:EnableWordWrap(false)
			end
			if slot.text.EnableWhitespaceWrap then
				slot.text:EnableWhitespaceWrap(false)
			end
			slot:Hide()
			root.slots[i] = slot
		end
		root.footer = root:AddChild(Text(GLOBAL.BODYTEXTFONT, CONTROLLER_WHEEL_TEXT_SIZE, ""))
		root.footer:SetRegionSize(720, 82)
		if root.footer.EnableWordWrap then
			root.footer:EnableWordWrap(false)
		end
		if root.footer.EnableWhitespaceWrap then
			root.footer:EnableWhitespaceWrap(false)
		end
		self._statusannounce_list = root
		root:Hide()
	end

	local function GetControllerWheelCenter(screen_width, screen_height)
		local world_x, world_y, world_z
		if inst.AnimState then
			world_x, world_y, world_z = inst.AnimState:GetSymbolPosition("head", 0, 0, 0)
		end
		if world_x == nil then
			world_x, world_y, world_z = inst.Transform:GetWorldPosition()
		end
		local screen_x, screen_y = GLOBAL.TheSim:GetScreenPos(world_x, world_y, world_z)
		local center_x = screen_x or screen_width * .5
		local center_y = (screen_y or screen_height * .5) + CONTROLLER_WHEEL_CENTER_Y_OFFSET
		local min_x = CONTROLLER_WHEEL_RADIUS + CONTROLLER_WHEEL_LABEL_WIDTH * .5
		local max_x = screen_width - CONTROLLER_WHEEL_RADIUS - CONTROLLER_WHEEL_LABEL_WIDTH * .5
		local min_y = CONTROLLER_WHEEL_RADIUS + CONTROLLER_WHEEL_LABEL_HEIGHT
		local max_y = screen_height - CONTROLLER_WHEEL_RADIUS - CONTROLLER_WHEEL_LABEL_HEIGHT
		if min_x <= max_x then
			center_x = math.max(min_x, math.min(max_x, center_x))
		else
			center_x = 0
		end
		if min_y <= max_y then
			center_y = math.max(min_y, math.min(max_y, center_y))
		else
			center_y = 0
		end
		return center_x, center_y
	end

	local function GetControllerWheelSlotAngle(index, count)
		return math.pi * .5 - (index - 1) * math.pi * 2 / count
	end

	local function GetControllerAnnouncePageCount(targets)
		return math.max(1, math.ceil(#targets / CONTROLLER_WHEEL_SLOTS))
	end

	local function GetControllerAnnouncePageStart(page)
		return (page - 1) * CONTROLLER_WHEEL_SLOTS + 1
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
		local screen_width, screen_height = GLOBAL.TheSim:GetScreenSize()
		local center_x, center_y = GetControllerWheelCenter(screen_width, screen_height)
		local page_count = GetControllerAnnouncePageCount(entries)
		local page = math.max(1, math.min(page_count, self._statusannounce_target_page or math.ceil(selected / CONTROLLER_WHEEL_SLOTS)))
		self._statusannounce_target_page = page
		local first = GetControllerAnnouncePageStart(page)
		local visible_count = math.min(CONTROLLER_WHEEL_SLOTS, #entries - first + 1)
		root.title:SetString(string.format("%s  %d/%d  %d/%d", strings.TITLE, selected, #entries, page, page_count))
		root.title:SetPosition(center_x, center_y + 4)
		for slot_index, slot in ipairs(root.slots) do
			local entry_index = first + slot_index - 1
			local entry = entries[entry_index]
			if entry then
				local angle = GetControllerWheelSlotAngle(slot_index, visible_count)
				local dir_x = math.cos(angle)
				local dir_y = math.sin(angle)
				local align_x = dir_x > .35 and GLOBAL.ANCHOR_LEFT
					or dir_x < -.35 and GLOBAL.ANCHOR_RIGHT
					or GLOBAL.ANCHOR_MIDDLE
				local count = entry.count > 1 and ("  x" .. tostring(entry.count)) or ""
				local slot_text = FormatControllerWheelName(entry.name) .. count
				local slot_width = entry.atlas ~= nil and entry.image ~= nil
					and CONTROLLER_WHEEL_LABEL_WIDTH
					or GetControllerWheelTextWidth(slot_text)
				slot:SetPosition(
					center_x + dir_x * CONTROLLER_WHEEL_RADIUS + dir_x * slot_width * .35,
					center_y + dir_y * CONTROLLER_WHEEL_RADIUS
				)
				slot.text:SetHAlign(align_x)
				if entry.atlas ~= nil and entry.image ~= nil then
					slot.bg:SetSize(CONTROLLER_WHEEL_LABEL_WIDTH, CONTROLLER_WHEEL_LABEL_HEIGHT)
					slot.icon:SetTexture(entry.atlas, entry.image)
					slot.icon:Show()
					slot.text:SetRegionSize(CONTROLLER_WHEEL_TEXT_MIN_WIDTH, CONTROLLER_WHEEL_LABEL_HEIGHT)
					slot.text:SetSize(CONTROLLER_WHEEL_TEXT_SIZE)
					slot.text:SetString(count ~= "" and count or "")
					slot.text:SetPosition(0, -34)
				else
					slot.icon:Hide()
					local text_width = slot_width
					slot.bg:SetSize(text_width, CONTROLLER_WHEEL_LABEL_HEIGHT)
					slot.text:SetRegionSize(text_width - 14, CONTROLLER_WHEEL_LABEL_HEIGHT)
					slot.text:SetPosition(dir_x > .35 and 8 or dir_x < -.35 and -8 or 0, 0)
					slot.text:SetSize(CONTROLLER_WHEEL_TEXT_SIZE)
					slot.text:SetString(slot_text)
				end
				if entry_index == selected then
					slot.bg:SetTint(.45, .30, .03, .88)
					slot.text:SetColour(1, .82, .25, 1)
					slot.icon:SetTint(1, .92, .45, 1)
				else
					slot.bg:SetTint(0, 0, 0, .58)
					slot.text:SetColour(.9, .9, .9, 1)
					slot.icon:SetTint(1, 1, 1, 1)
				end
				slot:Show()
			else
				slot:Hide()
			end
		end

		local controller_id = TheInput:GetControllerID()
		local single_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_INSPECT)
		local group_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ATTACK)
		local cancel_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ALTACTION)
		local previous_page_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_ROTATE_LEFT)
		local next_page_control = TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_ROTATE_RIGHT)
		local selected_entry = entries[selected]
		local selected_name = selected_entry and selected_entry.name or ""
		local selected_distance = selected_entry and math.floor(math.sqrt(selected_entry.distance_sq) / 4 * 10) / 10 or 0
		local page_hint = page_count > 1
			and string.format("   %s/%s %s", previous_page_control, next_page_control, strings.PAGE or "page")
			or ""
		root.footer:SetSize(GetControllerWheelTextSize(selected_name, CONTROLLER_WHEEL_TEXT_SIZE, 22))
		root.footer:SetString(string.format(
			"%s [%.1f]\n%s   %s %s   %s %s   %s %s%s",
			selected_name,
			selected_distance,
			strings.SWITCH,
			single_control,
			strings.SINGLE,
			group_control,
			strings.GROUP,
			cancel_control,
			strings.CANCEL,
			page_hint
		))
		root.footer:SetPosition(center_x, center_y - CONTROLLER_WHEEL_RADIUS - 58)
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

	local function SelectControllerAnnounceTarget(index)
		local targets = self._statusannounce_targets or {}
		while #targets > 0 do
			index = ((index - 1) % #targets) + 1
			self._statusannounce_target_index = index
			self._statusannounce_target_page = math.ceil(index / CONTROLLER_WHEEL_SLOTS)
			if SetControllerAnnounceTarget(targets[index]) then
				return true
			end
			table.remove(targets, index)
			if index > #targets then
				index = 1
			end
		end
		ExitControllerAnnounceMode()
		return false
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
		self._statusannounce_waiting_for_inspect_release = true
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
		self._statusannounce_target_page = math.ceil(index / CONTROLLER_WHEEL_SLOTS)
		SetModHUDFocus("ControllerAnnounce", true)
		SelectControllerAnnounceTarget(index)
	end

	local function SelectControllerAnnounceTargetByAngle(angle)
		local targets = self._statusannounce_targets or {}
		if #targets == 0 then
			ExitControllerAnnounceMode()
			return
		end

		local best_index = 1
		local best_dot = -math.huge
		local direction_x = math.cos(angle)
		local direction_y = math.sin(angle)
		local page = self._statusannounce_target_page or 1
		local first = GetControllerAnnouncePageStart(page)
		local visible_count = math.min(CONTROLLER_WHEEL_SLOTS, #targets - first + 1)
		for slot_index = 1, visible_count do
			local slot_angle = GetControllerWheelSlotAngle(slot_index, visible_count)
			local dot = math.cos(slot_angle) * direction_x + math.sin(slot_angle) * direction_y
			if dot > best_dot then
				best_dot = dot
				best_index = first + slot_index - 1
			end
		end
		SelectControllerAnnounceTarget(best_index)
	end

	local function ChangeControllerAnnouncePage(step)
		local targets = self._statusannounce_targets or {}
		if #targets == 0 then
			ExitControllerAnnounceMode()
			return
		end
		local page_count = GetControllerAnnouncePageCount(targets)
		local page = self._statusannounce_target_page or 1
		page = ((page - 1 + step) % page_count) + 1
		self._statusannounce_target_page = page
		SelectControllerAnnounceTarget(GetControllerAnnouncePageStart(page))
	end

	local function GetControllerMoveAngle(control)
		local up = control == GLOBAL.CONTROL_MOVE_UP or TheInput:IsControlPressed(GLOBAL.CONTROL_MOVE_UP)
		local down = control == GLOBAL.CONTROL_MOVE_DOWN or TheInput:IsControlPressed(GLOBAL.CONTROL_MOVE_DOWN)
		local right = control == GLOBAL.CONTROL_MOVE_RIGHT or TheInput:IsControlPressed(GLOBAL.CONTROL_MOVE_RIGHT)
		local left = control == GLOBAL.CONTROL_MOVE_LEFT or TheInput:IsControlPressed(GLOBAL.CONTROL_MOVE_LEFT)
		local x = (right and 1 or 0) - (left and 1 or 0)
		local y = (up and 1 or 0) - (down and 1 or 0)
		if x == 0 and y == 0 then
			return nil
		elseif x == 0 then
			return y > 0 and math.pi * .5 or -math.pi * .5
		elseif y == 0 then
			return x > 0 and 0 or math.pi
		elseif x > 0 and y > 0 then
			return math.pi * .25
		elseif x < 0 and y > 0 then
			return math.pi * .75
		elseif x < 0 and y < 0 then
			return -math.pi * .75
		else
			return -math.pi * .25
		end
	end

	local function IsAnyControl(control, ...)
		for i = 1, select("#", ...) do
			local compare_control = select(i, ...)
			if compare_control ~= nil and control == compare_control then
				return true
			end
		end
		return false
	end

	local function SwallowControllerControls(...)
		self._statusannounce_swallow_controls = self._statusannounce_swallow_controls or {}
		for i = 1, select("#", ...) do
			local control = select(i, ...)
			if control ~= nil then
				self._statusannounce_swallow_controls[control] = true
			end
		end
	end

	local function IsSwallowingControllerControl(control)
		return self._statusannounce_swallow_controls ~= nil
			and control ~= nil
			and self._statusannounce_swallow_controls[control] == true
	end

	local function ClearSwallowedControllerControl(control)
		if self._statusannounce_swallow_controls ~= nil and control ~= nil then
			self._statusannounce_swallow_controls[control] = nil
			if next(self._statusannounce_swallow_controls) == nil then
				self._statusannounce_swallow_controls = nil
			end
		end
	end

	local function ClearSwallowedControllerControls(...)
		for i = 1, select("#", ...) do
			ClearSwallowedControllerControl(select(i, ...))
		end
	end

	local function AnnounceControllerSelection(single)
		if self._statusannounce_target then
			if single then
				SwallowControllerControls(GLOBAL.CONTROL_CONTROLLER_ACTION, GLOBAL.CONTROL_ACCEPT, GLOBAL.CONTROL_ACTION)
				AnnounceWorldEntity(self._statusannounce_target, inst, true)
			else
				SwallowControllerControls(GLOBAL.CONTROL_CONTROLLER_ATTACK, GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_FORCE_ATTACK)
				AnnounceWorldEntity(self._statusannounce_target, inst, false)
			end
			ExitControllerAnnounceMode(true)
		end
	end

	local function HandleControllerAnnounceControl(control, down)
		if IsSwallowingControllerControl(control) then
			if not down then
				if IsAnyControl(control, GLOBAL.CONTROL_CONTROLLER_ACTION, GLOBAL.CONTROL_ACCEPT, GLOBAL.CONTROL_ACTION) then
					ClearSwallowedControllerControls(GLOBAL.CONTROL_CONTROLLER_ACTION, GLOBAL.CONTROL_ACCEPT, GLOBAL.CONTROL_ACTION)
				elseif IsAnyControl(control, GLOBAL.CONTROL_CONTROLLER_ATTACK, GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_FORCE_ATTACK) then
					ClearSwallowedControllerControls(GLOBAL.CONTROL_CONTROLLER_ATTACK, GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_FORCE_ATTACK)
				else
					ClearSwallowedControllerControl(control)
				end
			end
			return true
		end

		if not TheInput:ControllerAttached() then
			if self._statusannounce_mode then
				ExitControllerAnnounceMode()
			else
				self._statusannounce_swallow_controls = nil
			end
			return false
		end

		if not self._statusannounce_mode then
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
		elseif IsAnyControl(control, GLOBAL.CONTROL_MOVE_UP, GLOBAL.CONTROL_MOVE_DOWN, GLOBAL.CONTROL_MOVE_LEFT, GLOBAL.CONTROL_MOVE_RIGHT) then
			if down then
				local angle = GetControllerMoveAngle(control)
				if angle ~= nil then
					SelectControllerAnnounceTargetByAngle(angle)
				end
			end
			return true
		elseif IsAnyControl(control, GLOBAL.CONTROL_CONTROLLER_ACTION, GLOBAL.CONTROL_ACCEPT, GLOBAL.CONTROL_ACTION) then
			if down then
				SwallowControllerControls(GLOBAL.CONTROL_CONTROLLER_ACTION, GLOBAL.CONTROL_ACCEPT, GLOBAL.CONTROL_ACTION)
			end
			return true
		elseif IsAnyControl(control, GLOBAL.CONTROL_CONTROLLER_ATTACK, GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_FORCE_ATTACK) then
			if down and self._statusannounce_target then
				AnnounceControllerSelection(false)
			end
			return true
		elseif control == GLOBAL.CONTROL_ROTATE_LEFT then
			if down then
				SwallowControllerControls(GLOBAL.CONTROL_ROTATE_LEFT)
				ChangeControllerAnnouncePage(-1)
			end
			return true
		elseif control == GLOBAL.CONTROL_ROTATE_RIGHT then
			if down then
				SwallowControllerControls(GLOBAL.CONTROL_ROTATE_RIGHT)
				ChangeControllerAnnouncePage(1)
			end
			return true
		elseif control == GLOBAL.CONTROL_CONTROLLER_ALTACTION or control == GLOBAL.CONTROL_CANCEL then
			if down then
				ExitControllerAnnounceMode()
			end
			return true
		elseif control == GLOBAL.CONTROL_INSPECT then
			if self._statusannounce_waiting_for_inspect_release then
				if not down then
					self._statusannounce_waiting_for_inspect_release = nil
				end
			elseif down and self._statusannounce_target then
				SwallowControllerControls(GLOBAL.CONTROL_INSPECT)
				AnnounceControllerSelection(true)
			end
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
