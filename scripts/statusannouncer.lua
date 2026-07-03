local GetModuleDefinitionFromNetID = require("wx78_moduledefs").GetModuleDefinitionFromNetID

local WHISPER = false
local WHISPER_ONLY = false
local EXPLICIT = true
local TIME_STYLE = "smart"
local OVERRIDEB = true
local OVERRIDESELECT = true
local SHOWDURABILITY = true
local SHOWPROTOTYPER = true
local SHOWEMOJI = true

local setters = {
	WHISPER = function(v) WHISPER = v end,
	WHISPER_ONLY = function(v) WHISPER_ONLY = v end,
	EXPLICIT = function(v) EXPLICIT = v end,
	TIME_STYLE = function(v) TIME_STYLE = v end,
	OVERRIDEB = function(v) OVERRIDEB = v end,
	OVERRIDESELECT = function(v) OVERRIDESELECT = v end,
	SHOWDURABILITY = function(v) SHOWDURABILITY = v end,
	SHOWPROTOTYPER = function(v) SHOWPROTOTYPER = v end,
	SHOWEMOJI = function(v) SHOWEMOJI = v end,
}

local needs_strings = {
	NEEDSCIENCEMACHINE = "RESEARCHLAB",
	NEEDALCHEMYENGINE = "RESEARCHLAB2",
	NEEDSHADOWMANIPULATOR = "RESEARCHLAB3",
	NEEDPRESTIHATITATOR = "RESEARCHLAB4",
	NEEDSANCIENT_FOUR = "ANCIENT_ALTAR",
}

-- This just makes it so that if a message category hasn't been written for a character, it falls back to the UNKNOWN lines.
local char_messages_metatable = {
	__index = function(t, k)
		-- Putting this here so we don't copy it into every translation
		if k == "MIGHT" then
			return {
				HIGH = GetString("wolfgang", "ANNOUNCE_NORMALTOMIGHTY"),
				MID  = GetString("wolfgang", "ANNOUNCE_MIGHTYTONORMAL"),
				LOW  = GetString("wolfgang", "ANNOUNCE_NORMALTOWIMPY"),
			}
		end
		return STRINGS._STATUS_ANNOUNCEMENTS[t.prefab]
			and STRINGS._STATUS_ANNOUNCEMENTS[t.prefab][k]
			or STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN[k]
	end
}

local StatusAnnouncer = Class(function(self)
	self.cooldown = false
	self.cooldowns = {}
	self.stats = {}
	self.button_to_stat = {}
	self.char_messages = {}
	setmetatable(self.char_messages, char_messages_metatable)
	self.interceptors = {}
end,
nil,
{
})

local announce_types = {
	ITEM = true,
	RECIPE = true,
	INGREDIENT = true,
	SKIN = true,
	TEMPERATURE = true,
	SEASON = true,
	STAT = true,
	WX78CIRCUITS = true,
}

function StatusAnnouncer:RegisterInterceptor(modname, announce_type, interceptor_fn)
	if type(interceptor_fn) ~= "function" or not announce_types[announce_type] then
		return
	end
	if not self.interceptors[announce_type] then
		self.interceptors[announce_type] = {}
	end
	self.interceptors[announce_type][modname] = interceptor_fn
end

function StatusAnnouncer:ProcessInterceptors(announce_type, announce_str, data)
	local result = nil
	for _, interceptor in pairs(self.interceptors[announce_type] or {}) do
		result = interceptor(announce_str, data)
		if type(result) == "string" then
			announce_str = result
		end
	end
	return announce_str
end

function StatusAnnouncer:Announce(message, key)
	if type(key) ~= "string" then
		key = "__UNKNOWN__"
	end
	if not self.cooldown and not self.cooldowns[key] then
		local whisper = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) or TheInput:IsControlPressed(CONTROL_MENU_MISC_3)
		self.cooldown = ThePlayer:DoTaskInTime(1, function() self.cooldown = false end)
		self.cooldowns[key] = ThePlayer:DoTaskInTime(3, function() self.cooldowns[key] = nil end)
		TheNet:Say(STRINGS.LMB .. " " .. message, WHISPER_ONLY or WHISPER ~= whisper)
	end
	return true
end

-- Maps containers that are missing strings to a prefab name that should have the correct name
local container_prefab_map = {
	shadow_container = "magician_chest"
}

local function is_missing_name(name)
	return type(name) ~= "string"
		or name:find("^%s*$") ~= nil
		or name:upper():find("MISSING NAME", 1, true) ~= nil
		or name == "<missing_string>"
end

local function get_prefab_fallback(inst)
	local prefab = inst and inst.prefab
	if type(prefab) ~= "string" then
		return nil
	end
	local name = STRINGS.NAMES[prefab:upper()]
	return not is_missing_name(name) and name or prefab:gsub("_", " ")
end

local function get_basic_name(inst)
	if not inst then
		return nil
	end
	local name = inst.GetBasicDisplayName and inst:GetBasicDisplayName() or nil
	return not is_missing_name(name) and name or get_prefab_fallback(inst)
end

local function get_display_name(inst)
	if not inst then
		return nil
	end
	local name = inst.GetDisplayName and inst:GetDisplayName() or get_basic_name(inst)
	return not is_missing_name(name) and name or get_prefab_fallback(inst)
end

local function get_description_name(inst)
	local name = get_display_name(inst)
	if not name then
		return ""
	end
	local adjective = inst.GetAdjective and inst:GetAdjective() or nil
	return adjective and (adjective .. " " .. name) or name
end

local function get_container_name(container)
	if not container then return end
	if container_prefab_map[container.prefab] then
		local remapped_name = STRINGS.NAMES[container_prefab_map[container.prefab]:upper()]
		return remapped_name and remapped_name:lower()
	end
	if type(container.prefab) == "string" and container.prefab:find("^beard_sack_%d$") then
		return STRINGS.SKILLTREE.WILSON.WILSON_BEARD_7_TITLE:lower()
	end
	local container_name = get_basic_name(container)
	local container_prefab = container and container.prefab
	local underscore_index = container_prefab and container_prefab:find("_container")
	--container name was empty or blank, and matches the bundle container prefab naming system
	if type(container_name) == "string" and container_name:find("^%s*$") and underscore_index then
		container_name = STRINGS.NAMES[container_prefab:sub(1, underscore_index-1):upper()]
	end
	return container_name and container_name:lower()
end

function StatusAnnouncer:FormatSecondsAsRealTime(remaining_s)
	local remaining = ""
	local remaining_m = 0
	local remaining_h = 0
	if remaining_s >= 60 then
		remaining_m = math.floor(remaining_s / 60)
		remaining_s = remaining_s - 60 * remaining_m
	end
	if remaining_m >= 60 then
		remaining_h = math.floor(remaining_m / 60)
		remaining_m = remaining_m - 60 * remaining_h
	end
	remaining = remaining_s .. "s"
	if remaining_m > 0 then
		remaining = remaining_m .. "m" .. remaining
	end
	if remaining_h > 0 then
		remaining = remaining_h .. "h" .. remaining
	end
	return remaining
end

function StatusAnnouncer:FormatSecondsAsGameDays(seconds)
	local remaining_days = seconds / TUNING.TOTAL_DAY_TIME
	local remaining = string.format("%.2f days", remaining_days)

	return remaining
end

function StatusAnnouncer:SecondsToTimeRemainingString(seconds)
	if TIME_STYLE == "smart" then
		-- For the smart setting, short periods of time will display as real time. 
		-- Periods of time longer than a day will be converted into game days.
		if seconds < TUNING.TOTAL_DAY_TIME then
			return self:FormatSecondsAsRealTime(seconds)
		else
			return self:FormatSecondsAsGameDays(seconds)
		end
	elseif TIME_STYLE == "real" then
		return self:FormatSecondsAsRealTime(seconds)
	elseif TIME_STYLE == "game" then
		return self:FormatSecondsAsGameDays(seconds)
	else
		-- This shouldn't ever happen, but just in case...
		return string.format("(%d?)", seconds)
	end
end
	

function StatusAnnouncer:AnnounceItem(slot)
	local item = slot.tile.item
	local container = slot.container
	local percent_type = nil
	local percent = nil
	local remaining = nil
	local thermal_stone_warmth = nil
	if slot.tile.percent then
		percent_type = "DURABILITY"
		percent = slot.tile.percent:GetString()
	elseif slot.tile.hasspoilage then
		if type(item.replica) == "table"
		and type(item.replica.inventoryitem) == "table"
		and type(item.replica.inventoryitem.classified) == "table" then
			percent_type = "FRESHNESS"
			-- .62 comes from the way perish values are serialized; they presumably use a 6-bit unsigned int,
			-- and assign 63 (max value) as "default, unknown"; 0-62 span the actual perish values;
			-- so 1/62 would convert this to a fraction, and 100/62 (or 1/.62) convert to percentage points
			percent = math.floor(item.replica.inventoryitem.classified.perish:value()*(1/.62)) .. "%"
		end
	elseif item:HasTag("rechargeable") then
		percent_type = "RECHARGE"
		percent = math.floor(slot.tile.rechargepct*100) .. "%"
		local remaining_s = math.floor(slot.tile.rechargetime*(1 - slot.tile.rechargepct) + 0.5)
		remaining = self:SecondsToTimeRemainingString(remaining_s)
	end
	local S = STRINGS._STATUS_ANNOUNCEMENTS._ --To save some table lookups
	if item.prefab == "heatrock" then
		-- Try to get thermal stone temperature range to announce
		local image_hash = item.replica.inventoryitem:GetImage()
		local hash_lookup = {}
		local skin_name = item.AnimState:GetSkinBuild()
		if skin_name == "" then
			skin_name = "heat_rock"
		end
		for i = 1,5 do
			hash_lookup[hash(skin_name .. i .. ".tex")] = i
		end
		local range = hash_lookup[image_hash]
		if range ~= nil and range >= 1 and range <= 5 then
			thermal_stone_warmth = S.ANNOUNCE_ITEM.HEATROCK[range]
		end
	end
	if container == nil or (container and container.type == "pack") then
		--\equipslots/        \backpacks/
		container = ThePlayer.replica.inventory
	end
	local num_equipped = 0
	if not container.type then --this is an inventory
		--add in items in equipslots, which don't normally get counted by Has
		for _,slot in pairs(EQUIPSLOTS) do
			if container.GetEquippedItem then
				local equipped_item = container:GetEquippedItem(slot)
				if equipped_item and equipped_item.prefab == item.prefab then
					num_equipped = num_equipped + (equipped_item.replica.stackable and equipped_item.replica.stackable:StackSize() or 1)
				end
			end
		end
	end
	local container_name = get_container_name(container.type and container.inst)
	-- Try to trace the path from construction container to the constructionsite that spawned it
	if not container_name then
		local player = container.inst and container.inst.entity:GetParent()
		local constructionbuilder = player and player.components and player.components.constructionbuilder
		if constructionbuilder and constructionbuilder.constructionsite then
			container_name = get_container_name(constructionbuilder.constructionsite)
		end
	end
	local prefab_name = type(item.prefab) == "string" and STRINGS.NAMES[item.prefab:upper()] or nil
	local name = (not is_missing_name(prefab_name) and prefab_name or get_basic_name(item) or "unknown item"):lower()
	local description_name = get_description_name(item)
	local has, num_found = container:Has(item.prefab, 1)
	num_found = (num_found or 0) + num_equipped
	local i_have = ""
	local in_this = ""
	if container_name then -- this is a chest
		i_have = S.ANNOUNCE_ITEM.WE_HAVE
		in_this = S.ANNOUNCE_ITEM.IN_THIS
	else -- this is a backpack or inventory
		i_have = S.ANNOUNCE_ITEM.I_HAVE
		container_name = ""
	end
	local this_many = "" .. num_found
	local plural = num_found > 1
	local with = ""
	local durability = ""
	local item_name_intro = ""
	local item_name2 = ""
	if SHOWDURABILITY and percent then
		with = plural
				and S.ANNOUNCE_ITEM.AND_THIS_ONE_HAS
				 or S.ANNOUNCE_ITEM.WITH
		durability = percent and S.ANNOUNCE_ITEM[percent_type]
		if remaining ~= nil and percent ~= "100%" then
			local remaining_str = subfmt(S.ANNOUNCE_ITEM.REMAINING[percent_type],
										{
											AMOUNT = remaining,
										})
			percent = remaining_str .. " (" .. percent .. ")"
			durability = ""
		end
	else
		percent = ""
	end
	local a = S.getArticle(name)
	local s = S.S
	if (not plural) or string.find(name, s.."$") ~= nil then
		s = ""
	end
	if thermal_stone_warmth then
		if plural then
			with = S.ANNOUNCE_ITEM.AND_THIS_ONE_IS .. thermal_stone_warmth .. S.ANNOUNCE_ITEM.WITH
		else
			name = thermal_stone_warmth .. " " .. name
		end
	end
	if this_many == nil or this_many == "1" then this_many = a end
	local item_prefab = type(item.prefab) == "string" and item.prefab:lower() or ""
	local has_variable_name = name:find("{item}", 1, true) ~= nil
		or item_prefab == "blueprint"
		or item_prefab:find("_blueprint$", 1) ~= nil
		or item_prefab == "sketch"
		or item_prefab:find("_sketch$", 1) ~= nil
		or item:HasTag("sketch")
	if has_variable_name and description_name ~= "" and name:lower() ~= description_name:lower() then
		if plural then
			name = name:gsub("{item}", ""):gsub("^%s+", ""):gsub("%s+$", "")
			item_name_intro = S.ANNOUNCE_ITEM.AND_THIS_ONE_NAME
			item_name2 = description_name
		else
			name = description_name
		end
	end
	local announce_str = subfmt(S.ANNOUNCE_ITEM.FORMAT_STRING,
								{
									I_HAVE = i_have,
									THIS_MANY = this_many,
									ITEM = name,
									S = s,
									IN_THIS = in_this,
									CONTAINER = container_name,
									WITH = with,
									PERCENT = percent,
									DURABILITY = durability,
									ITEM_NAME_INTRO = item_name_intro,
									ITEM_NAME2 = item_name2,
								})
	local data = {
		item = item,
		container = container,
		slot = slot,
	}
	announce_str = self:ProcessInterceptors("ITEM", announce_str, data)
	return self:Announce(announce_str, "ITEM_" .. tostring(item.GUID))
end

-- Almost identical to CraftingMenuDetails:_GetHintTextForRecipe
-- copied for stability reasons, and out of respect for the naming hint that it was intended to be local
local function GetMinPrototyperTree(recipe)
	local validmachines = {}
	local adjusted_level = deepcopy(recipe.level)

	-- Adjust recipe's level for bonus so that the hint gives the right message
	local tech_bonus = ThePlayer.replica.builder:GetTechBonuses()
	for k, v in pairs(adjusted_level) do
		adjusted_level[k] = math.max(0, v - (tech_bonus[k] or 0))
	end

	for k, v in pairs(TUNING.PROTOTYPER_TREES) do
		local canbuild = CanPrototypeRecipe(adjusted_level, v)
		if canbuild then
			table.insert(validmachines, {TREE = tostring(k), SCORE = 0})
		end
	end

	if #validmachines > 0 then
		if #validmachines == 1 then
			--There's only once machine is valid. Return that one.
			return validmachines[1].TREE
		end

		--There's more than one machine that gives the valid tech level! We have to find the "lowest" one (taking bonus into account).
		for k,v in pairs(validmachines) do
			for rk,rv in pairs(adjusted_level) do
				local prototyper_level = TUNING.PROTOTYPER_TREES[v.TREE][rk]
				if prototyper_level and (rv > 0 or prototyper_level > 0) then
					if rv == prototyper_level then
						--recipe level matches, add 1 to the score
						v.SCORE = v.SCORE + 1
					elseif rv < prototyper_level then
						--recipe level is less than prototyper level, remove 1 per level the prototyper overshot the recipe
						v.SCORE = v.SCORE - (prototyper_level - rv)
					end
				end
			end
		end

		table.sort(validmachines, function(a,b) return (a.SCORE) > (b.SCORE) end)

		return validmachines[1].TREE
	end

	return "CANTRESEARCH"
end

local tree_to_prefab = {
	SCIENCEMACHINE = "RESEARCHLAB",
	ALCHEMYMACHINE = "RESEARCHLAB2",
	SHADOWMANIPULATOR = "RESEARCHLAB3",
	PRESTIHATITATOR = "RESEARCHLAB4",
	ANCIENTALTAR_LOW = "ANCIENT_ALTAR_BROKEN",
	ANCIENTALTAR_HIGH = "ANCIENT_ALTAR",
	FISHING = "TACKLESTATION",
	SEAFARING_STATION = "SEAFARING_PROTOTYPER",
	-- Spidercraft doesn't seem to correspond to any prefab, so leaving it out
	-- A bunch more from TUNING.PROTOTYPER_TREES could be added here,
	-- but these were the only ones in CraftingMenuDetails
}

local function GetMinPrototyper(recipe)
	local prefab = tree_to_prefab[GetMinPrototyperTree(recipe)]
	if prefab ~= nil then
		return STRINGS.NAMES[prefab] or prefab
	end
	return prefab
end

function StatusAnnouncer:AnnounceRecipe(recipe, ingredient)
	if recipe == nil then
		return false
	end
	local S = STRINGS._STATUS_ANNOUNCEMENTS._ --To save some table lookups
	local builder = ThePlayer.replica.builder
	local buffered = builder:IsBuildBuffered(recipe.name)
	local knows = builder:KnowsRecipe(recipe.name) or CanPrototypeRecipe(recipe.level, builder:GetTechTrees())
	local can_build = builder:HasIngredients(recipe.name)
	local recipe_product = recipe.product
	local recipe_name = recipe.nameoverride or recipe.name or recipe_product
	local strings_name = type(recipe_name) == "string" and STRINGS.NAMES[recipe_name:upper()] or nil
	if not strings_name and type(recipe_product) == "string" then
		strings_name = STRINGS.NAMES[recipe_product:upper()]
	end
	local key = "RECIPE_" .. tostring(recipe_name or recipe_product)
	local name = strings_name
		or (type(recipe_name) == "string" and recipe_name:gsub("_", " "))
		or "unknown recipe"
	name = name:lower()
	local a = S.getArticle(name)
	local prototyper = ""
	if not knows then
		prototyper = GetMinPrototyper(recipe) or prototyper
	end
	local a_proto = ""
	local proto = ""
	local data = {
		recipe = recipe,
		ingredient = ingredient,
		buffered = buffered,
		knows = knows,
		can_build = can_build,
		prototyper = prototyper,
	}
	if ingredient == nil then
		-- announce the recipe (need more x, can make x, have x ready)
		local start_q = ""
		local to_do = ""
		local s = ""
		local pre_built = ""
		local end_q = ""
		local i_need = ""
		local for_it = ""
		if buffered then
			to_do = S.ANNOUNCE_RECIPE.I_HAVE
			pre_built = S.ANNOUNCE_RECIPE.PRE_BUILT
		elseif can_build and knows then
			to_do = S.ANNOUNCE_RECIPE.ILL_MAKE
		elseif knows then
			to_do = S.ANNOUNCE_RECIPE.WE_NEED
			if S.LANGUAGE == "chinese" or S.LANGUAGE == "chinese_cht" then
				a = "更多"
				s = ""
			else
				a = ""
				s = string.find(name, S.S.."$") == nil and S.S or ""
			end
		else
			to_do = S.ANNOUNCE_RECIPE.CAN_SOMEONE
			if prototyper ~= "" and SHOWPROTOTYPER then
				i_need = S.ANNOUNCE_RECIPE.I_NEED
				a_proto = S.getArticle(prototyper) .. " "
				proto = prototyper
				for_it = S.ANNOUNCE_RECIPE.FOR_IT
			end
			start_q = S.ANNOUNCE_RECIPE.START_Q
			end_q = S.ANNOUNCE_RECIPE.END_Q
		end
		local announce_str = subfmt(S.ANNOUNCE_RECIPE.FORMAT_STRING,
									{
										START_Q = start_q,
										TO_DO = to_do,
										THIS_MANY = a,
										ITEM = name,
										S = s,
										PRE_BUILT = pre_built,
										END_Q = end_q,
										I_NEED = i_need,
										A_PROTO = a_proto,
										PROTOTYPER = proto,
										FOR_IT = for_it,
									})
		if string.find(announce_str, "%?%.$") ~= nil then
			-- In some cases (maybe only reachable through testing partial code),
			-- it ends up with ?. at the end, so trim the period
			announce_str = announce_str:sub(1, announce_str:len() - 1)
		end
		announce_str = self:ProcessInterceptors("RECIPE", announce_str, data)
		return self:Announce(announce_str, key)
	else --announce the ingredient (need more, have enough to make x of recipe)
		local num = 0
		key = key .. "_" .. ingredient
		local ing_s = S.S
		local amount_needed = 1
		-- No special handling for tech ingredients (sculpting block), but it seems to work fine anyway?
		for k,v in pairs(recipe.ingredients) do
			if ingredient == v.type then amount_needed = v.amount end
		end
		local has, num_found = ThePlayer.replica.inventory:Has(ingredient, RoundBiasedUp(amount_needed * ThePlayer.replica.builder:IngredientMod()))
		for k,v in pairs(recipe.character_ingredients) do
			if ingredient == v.type then
				amount_needed = v.amount
				has, num_found = ThePlayer.replica.builder:HasCharacterIngredient(v)
				ing_s = "" -- health and sanity are already plural
			end
		end
		num = amount_needed - num_found
		local can_make = math.floor(num_found / amount_needed)*recipe.numtogive
		local ingredient_str = (STRINGS.NAMES[ingredient:upper()] or ingredient:gsub("_", " ")):lower()
		if num == 1 or ingredient_str:find(ing_s.."$") ~= nil then ing_s = "" end
		local announce_str = "";
		if num > 0 then
			local and_str = ""
			if prototyper ~= "" and SHOWPROTOTYPER then
				and_str = S.ANNOUNCE_INGREDIENTS.AND
				a_proto = S.getArticle(prototyper) .. " "
				proto = prototyper
			end
			announce_str = subfmt(S.ANNOUNCE_INGREDIENTS.FORMAT_NEED,
									{
										NUM_ING = num,
										INGREDIENT = ingredient_str,
										S = ing_s,
										AND = and_str,
										A_PROTO = a_proto,
										PROTOTYPER = proto,
										A_REC = S.getArticle(name),
										RECIPE = name,
									})
		else
			local but_need = ""
			if prototyper ~= "" and SHOWPROTOTYPER then
				but_need = S.ANNOUNCE_INGREDIENTS.BUT_NEED
				a_proto = S.getArticle(prototyper) .. " "
				proto = prototyper
			end
			local a_rec = ""
			local rec_s = ""
			if can_make > 1 then
				a_rec = can_make .. ""
				rec_s = S.S
				if string.find(name, rec_s.."$") ~= nil then --already plural
					rec_s = ""
				end
			else
				a_rec = S.getArticle(name)
			end
			announce_str = subfmt(S.ANNOUNCE_INGREDIENTS.FORMAT_HAVE,
									{
										INGREDIENT = ingredient_str,
										ING_S = ing_s,
										A_REC = a_rec,
										RECIPE = name,
										REC_S = rec_s,
										BUT_NEED = but_need,
										A_PROTO = a_proto,
										PROTOTYPER = proto,
									})
		end
		data.num_found = num_found
		data.amount_needed = amount_needed
		announce_str = self:ProcessInterceptors("INGREDIENT", announce_str, data)
		return self:Announce(announce_str, key)
	end
end

function StatusAnnouncer:AnnounceSkin(recipe, skin)
	local recipe_name = recipe.nameoverride or recipe.name or recipe.product
	local item_name = type(recipe_name) == "string" and STRINGS.NAMES[string.upper(recipe_name)] or nil
	if not item_name then
		item_name = type(recipe.product) == "string" and STRINGS.NAMES[string.upper(recipe.product)] or nil
			or (type(recipe_name) == "string" and recipe_name:gsub("_", " "))
			or "unknown item"
	end
	if skin ~= item_name then --don't announce default skins
		local message = subfmt(STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_SKIN.FORMAT_STRING,
									{SKIN = GetSkinName(skin), ITEM = item_name})
		local data = {
			recipe = recipe,
			skin = skin,
		}
		message = self:ProcessInterceptors("SKIN", message, data)
		return self:Announce(message, "SKIN_" .. recipe_name)
	end
end

function StatusAnnouncer:AnnounceTemperature(pronoun)
	local S = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_TEMPERATURE --To save some table lookups
	local temp = tonumber(ThePlayer:GetTemperature()) or 0
	local pronoun = pronoun and S.PRONOUN[pronoun] or S.PRONOUN.DEFAULT
	local message = S.TEMPERATURE.GOOD
	local TUNING = TUNING
	if temp >= TUNING.OVERHEAT_TEMP then
		message = S.TEMPERATURE.BURNING
	elseif temp >= TUNING.OVERHEAT_TEMP - 5 then
		message = S.TEMPERATURE.HOT
	elseif temp >= TUNING.OVERHEAT_TEMP - 15 then
		message = S.TEMPERATURE.WARM
	elseif temp <= 0 then
		message = S.TEMPERATURE.FREEZING
	elseif temp <= 5 then
		message = S.TEMPERATURE.COLD
	elseif temp <= 15 then
		message = S.TEMPERATURE.COOL
	end
	message = subfmt(S.FORMAT_STRING,
						{
							PRONOUN = pronoun,
							TEMPERATURE = message,
						})
	if EXPLICIT then
		message = string.format("(%d° | %d°C) %s", temp, temp / 2, message)
	end
	local data = {
		pronoun = pronoun,
		temp = temp
	}
	message = self:ProcessInterceptors("TEMPERATURE", message, data)
	return self:Announce(message, "TEMPERATURE")
end

function StatusAnnouncer:AnnounceSeason()
	local data = {
		days_left = TheWorld.state.remainingdaysinseason,
		season = TheWorld.state.season
	}
	local message = subfmt(
		STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_SEASON,
		{
			DAYS_LEFT = data.days_left,
			SEASON = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[data.season:upper()],
		}
	)
	message = self:ProcessInterceptors("SEASON", message, data)
	return self:Announce(message, "SEASON")
end

local function FormatChipList(S, chip_order, chips, charged)
	local chips_string = ""
	for _, chip in ipairs(chip_order) do
		if chips[chip] then
			if chips_string ~= "" then
				chips_string = chips_string .. ", "
			end
			local chip_name = STRINGS.NAMES["WX78MODULE_" .. chip:upper()]
			if type(chip_name) ~= "string" then
				chip_name = chip
			else
				chip_name = S.GetCircuitName(chip_name)
			end
			chips_string = chips_string .. subfmt(
				S.FORMAT_STRING_CHIP,
				{
					COUNT = chips[chip],
					CIRCUIT_NAME = chip_name,
				})
		end
	end
	if chips_string == "" then return chips_string end
	return subfmt(
		S.FORMAT_STRING_CHARGED,
		{
			CIRCUIT_LIST = chips_string,
			CHARGE_STATE = charged and S.CHARGED or S.UNCHARGED
		})
end

function StatusAnnouncer:AnnounceWxCircuits(widget)
	local charge = widget.energy_level
	local chip_order = {}
	local charged_chips = {}
	local uncharged_chips = {}
	local modules_table = widget.owner:GetModulesData()
	for i, module_index in ipairs(modules_table) do
		if module_index ~= 0 then
			local module_def = GetModuleDefinitionFromNetID(module_index)
			local modname = module_def.name
			charge = charge - module_def.slots
			local add_to = charge < 0 and uncharged_chips or charged_chips
			if not uncharged_chips[modname] and not charged_chips[modname] then
				table.insert(chip_order, modname)
			end
			add_to[modname] = (add_to[modname] or 0) + 1
		end
	end
	local S = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_CIRCUITS
	local charged_list = FormatChipList(S, chip_order, charged_chips, true)
	local uncharged_list = FormatChipList(S, chip_order, uncharged_chips, false)
	local separator = ""
	if charged_list ~= "" and uncharged_list ~= "" then
		separator = S.SEPARATOR
	end
	local message = subfmt(
		S.FORMAT_STRING,
		{
			CIRCUITS = S.CIRCUITS,
			CHARGED = charged_list,
			SEPARATOR = separator,
			UNCHARGED = uncharged_list,
		}
	)
	local data = {
		widget = widget,
		chip_order = chip_order,
		charged_chips = charged_chips,
		uncharged_chips = uncharged_chips,
	}
	message = self:ProcessInterceptors("WX78CIRCUITS", message, data)
	return self:Announce(message, "WX78CIRCUITS")
end

--NOTE: Your mod is responsible for adding and deciding when to show/hide the controller button hint
-- look at the modmain for examples-- most stats just show/hide with controller inventory,
-- but moisture requires some special handling
function StatusAnnouncer:RegisterStat(name, widget, controller_btn,
										thresholds, category_names, value_fn, switch_fn)
	if controller_btn ~= nil then
		self.button_to_stat[controller_btn] = name
	end
	self.stats[name] = {
		--The widget that should be focused when announcing this stat
		widget = widget,
		--The button on the controller that announces this stat
		controller_btn = controller_btn,
		--the numerical thresholds at which messages change (must be sorted in increasing order!)
		thresholds = thresholds,
		--the names of the buckets between the thresholds, for looking up strings
		category_names = category_names,
		--value_fn(ThePlayer) returns the current and maximum of the stat
		value_fn = value_fn,
		--switch_fn(ThePlayer) returns the mode (e.g. HUMAN for Woodie vs WEREBEAVER for Werebeaver)
		--if this is nil, it assumes there's just one table (look at Woodie's table in announcestrings vs the others)
		switch_fn = switch_fn,
	}
end

--The other arguments are here so that mods can use them to override this function
-- and avoid some of these stats if their character doesn't have them
function StatusAnnouncer:RegisterCommonStats(
		HUD, prefab, hunger, sanity, health, moisture,
		wereness, pethealth, inspiration, boat, mightiness)
	local stat_categorynames = {"EMPTY", "LOW", "MID", "HIGH", "FULL"}
	local default_thresholds = {	.15,	.35,	.55,	.75		 }

	local status = HUD.controls.status
	local has_weremode = type(status.wereness) == "table"
	local switch_fn = has_weremode
		and function(ThePlayer) return ThePlayer.weremode:value() ~= 0 and "WEREBEAVER" or "HUMAN" end
		or nil

	-- Base stats
	if hunger ~= false and type(status.stomach) == "table" then
		self:RegisterStat(
			"Hunger",
			status.stomach,
			CONTROL_INVENTORY_USEONSCENE, -- D-Pad Left
			default_thresholds,
			stat_categorynames,
			function(ThePlayer)
				return	ThePlayer.player_classified.currenthunger:value(),
						ThePlayer.player_classified.maxhunger:value()
			end,
			switch_fn
		)
	end
	if sanity ~= false and type(status.brain) == "table" then
		self:RegisterStat(
			"Sanity",
			status.brain,
			CONTROL_INVENTORY_EXAMINE, -- D-Pad Up
			default_thresholds,
			stat_categorynames,
			function(ThePlayer)
				return	ThePlayer.player_classified.currentsanity:value(),
						ThePlayer.player_classified.maxsanity:value()
			end,
			switch_fn
		)
	end
	if health ~= false and type(status.heart) == "table" then
		self:RegisterStat(
			"Health",
			status.heart,
			CONTROL_INVENTORY_USEONSELF, -- D-Pad Right
			{.25, .5, .75, 1},
			stat_categorynames,
			function(ThePlayer)
				return	ThePlayer.player_classified.currenthealth:value(),
						ThePlayer.player_classified.maxhealth:value()
			end,
			switch_fn
		)
	end

	-- Context-specific stats that everyone has
	if moisture ~= false and type(status.moisturemeter) == "table" then
		self:RegisterStat(
			"Wetness",
			status.moisturemeter,
			CONTROL_ROTATE_RIGHT, -- Right Bumper
			default_thresholds,
			stat_categorynames,
			function(ThePlayer)
				return	ThePlayer.player_classified.moisture:value(),
						ThePlayer.player_classified.maxmoisture:value()
			end,
			switch_fn
		)
	end
	if boat ~= false and type(status.boatmeter) == "table" then
		self:RegisterStat(
			"Boat",
			status.boatmeter,
			CONTROL_ROTATE_LEFT, -- Left Bumper
			{ .0001, .35, .65, .85 },
			stat_categorynames,
			function(player)
				local boat = player.components.walkableplatformplayer and player.components.walkableplatformplayer.platform
				local healthsyncer = boat and boat.components.healthsyncer
				if not (healthsyncer and healthsyncer.max_health) then
					return 0, 0
				else
					return math.ceil(healthsyncer.max_health * healthsyncer:GetPercent()), healthsyncer.max_health -- Klei yydsb
				end
			end,
			switch_fn
		)
	end

	-- Character-specific stats
	if wereness ~= false and has_weremode then
		self:RegisterStat(
			"Wereness",
			status.wereness,
			nil,
			{ .25, .5, .7, .9 },
			stat_categorynames,
			function(ThePlayer)
				return	ThePlayer.player_classified.currentwereness:value(),
						100 -- looks like the only way is to hardcode this; not networked
			end,
			switch_fn
		)
	end
	if pethealth ~= false and ThePlayer.components.pethealthbar ~= nil and type(status.pethealthbadge) == "table" then
		self:RegisterStat(
			"Abigail",
			status.pethealthbadge,
			nil,
			{ .25, .5, .7, .9 },
			stat_categorynames,
			function(ThePlayer)
				return	math.floor(ThePlayer.components.pethealthbar:GetMaxHealth() * ThePlayer.components.pethealthbar:GetPercent() + 0.5),
						ThePlayer.components.pethealthbar:GetMaxHealth()
			end,
			switch_fn
		)
	end
	if inspiration ~= false and type(status.inspirationbadge) == "table" then
		self:RegisterStat(
			"Inspiration",
			status.inspirationbadge,
			nil,
			TUNING.BATTLESONG_THRESHOLDS,
			{"LOW", "MID", "HIGH", "FULL"},
			function(ThePlayer)
				return	ThePlayer.player_classified.currentinspiration:value(),
						TUNING.INSPIRATION_MAX or 100
			end,
			switch_fn
		)
	end
	if mightiness ~= false and type(status.mightybadge) == "table" then
		self:RegisterStat(
			"Might",
			status.mightybadge,
			nil,
			{
				(TUNING.WIMPY_THRESHOLD or 25)/100,
				(TUNING.MIGHTY_THRESHOLD or 75)/100,
			},
			{"LOW", "MID", "HIGH"},
			function(ThePlayer)
				return	ThePlayer.player_classified.currentmightiness:value(),
						TUNING.MIGHTINESS_MAX or 100
			end,
			switch_fn
		)
	end
	-- if prefab == "wx78" and HUD.controls.secondary_status and HUD.controls.secondary_status.upgrademodulesdisplay then
        -- self:RegisterStat(
			-- "Electric",
			-- HUD.controls.secondary_status.upgrademodulesdisplay,
			-- CONTROL_ROTATE_RIGHT,
			-- default_thresholds,
			-- stat_categorynames,
			-- function()
				-- return HUD.controls.secondary_status.upgrademodulesdisplay.energy_level or 0,TUNING.WX78_MAXELECTRICCHARGE or 6
			-- end,
			-- switch_fn
		-- )
    -- end
end

local function has_seasons(HUD, ignore_focus)
	return HUD.controls.seasonclock and (ignore_focus or HUD.controls.seasonclock.focus)
		or HUD.controls.status.season and (ignore_focus or HUD.controls.status.season.focus)
end

function StatusAnnouncer:AnnounceStat(stat, widget)
	local message = self:ChooseStatMessage(stat)
	local data = {
		stat = stat,
		widget = widget,
	}
	message = self:ProcessInterceptors("STAT", message, data)
	return self:Announce(message, stat)
end

function StatusAnnouncer:OnHUDMouseButton(HUD)
	for stat_name,data in pairs(self.stats) do
		if data and data.widget and data.widget.focus then
			local widget = data.widget
			if widget.name and widget.name == "BoatMeter" and widget.boat == nil then
				return false
			end
			if widget.name and widget.name:find("MoistureMeter") and not widget.active then
				return false
			end
			return self:AnnounceStat(stat_name, widget)
		end
	end
	if HUD.controls.status.temperature and HUD.controls.status.temperature.focus then
		return self:AnnounceTemperature(HUD.controls.status._weremode and "BEAST" or nil)
	end
	if has_seasons(HUD, false) then
		return self:AnnounceSeason()
	end
	--宣告世界温度与降雨
    if HUD.controls.status.worldtemp and HUD.controls.status.worldtemp.focus then
        return self:AnnounceWorldtemp(HUD.controls.status._weremode and "BEAST" or nil)
    end
end

function StatusAnnouncer:OnHUDControl(HUD, control)
	if HUD:IsCraftingOpen() and TheInput:ControllerAttached() then
		if control == CONTROL_CANCEL then
			local details = HUD.controls.craftingmenu.craftingmenu.details_root
			if details and details.data and details.data.recipe then
				return self:AnnounceRecipe(details.data.recipe)
			end
		end
	elseif HUD:IsControllerInventoryOpen()
	or (HUD.controls.status._weremode and HUD._statuscontrollerbuttonhintsshown) then
		local stat = self.button_to_stat[control]
		if stat and self.stats[stat].widget.shown then
			local widget = self.stats[stat].widget
			if widget.name and widget.name == "BoatMeter" and widget.boat == nil then
				return false
			end
			if widget.name and widget.name:find("MoistureMeter") and not widget.active then
				return false
			end
			return self:AnnounceStat(stat, widget)
		end
		if OVERRIDEB and HUD.controls.status.temperature and control == CONTROL_CANCEL then
			return self:AnnounceTemperature(HUD.controls.status._weremode and "BEAST" or nil)
		end
		if OVERRIDESELECT and control == CONTROL_MAP and has_seasons(HUD, true) then
			return self:AnnounceSeason()
		end
	end
end

local function get_category(thresholds, percent)
	local i = 1
	while thresholds[i] ~= nil and percent >= thresholds[i] do
		i = i + 1
	end
	return i
end

function StatusAnnouncer:ChooseStatMessage(stat)
	local cur, max = self.stats[stat].value_fn(ThePlayer)
	local percent = cur/max
	local stat_name = self.stat_names[stat] or stat
	if stat == "Health" and ThePlayer:HasTag("health_as_oldage") then
		stat_name = self.stat_names["Age"] or "Age"
		-- I wanted to make this more generic, but unfortunately it's encapsulated by widgets/wandaagebadge
		-- in a way that doesn't really promote extensibility
		max = TUNING.WANDA_MAX_YEARS_OLD
		cur = max - cur
		-- Conveniently, percent already makes sense because it's essentially considering Wanda to have 60 health
		-- (where 60 is Age 20 and 0 is Age 80)
	end
	local messages = self.stats[stat].switch_fn
						and self.char_messages[self.stats[stat].switch_fn(ThePlayer)]
						or self.char_messages
	local category = get_category(self.stats[stat].thresholds, percent)
	local category_name = self.stats[stat].category_names[category]
	
	if stat:upper() == "BOAT" then
		messages = self.char_messages
	end
	
	local message = messages[stat:upper()][category_name]
	if EXPLICIT then
		return string.format("(%s: %d/%d) %s", stat_name, cur, max, message)
	else
		return message
	end
end

--血量信息 nil
local function AnHPInfo(item)
	local hovered_item = ConsoleWorldEntityUnderMouse()
    if item and item.replica and hovered_item == item then
        local text = ThePlayer.HUD.controls.hover.text:GetString()
        local lines = string.split(text, '\n')
        local r = ""
		
        for i, line in ipairs(lines) do
            if r == "" then
                local matched = true
                local times = 0
                for o = 1, #line do
                    if matched == true then
                        local c = string.sub(line, o, o)
                        if c == "/" then
                            times = times + 1
                        elseif c ~= " " and c ~= "\r" and c ~= "\n" and c ~= "0" and c ~= "1" and c ~= "2" and c ~= "3" and c ~= "4" and c ~= "5" and c ~= "6" and c ~= "7" and c ~= "8" and c ~= "9" then
                            matched = false
                        end
                    end
                end
                if times == 1 and matched == true then
                    line = string.gsub(line, " ", "")
                    line = string.gsub(line, "\r", "")
                    line = string.gsub(line, "\n", "")
                    local hp = string.split(line, '/')
                    if hp[2] and tostring(tonumber(hp[1])) == hp[1] and tostring(tonumber(hp[2])) == hp[2] then
                        local cur = tonumber(hp[1])
                        local all = tonumber(hp[2])
                        local percent = string.format("%.1f", (cur / all) * 100):gsub("0+$", ""):gsub("%.$", "")
						if TheInventory:CheckOwnership("emoji_heart") then
							r = string.format("[ :heart:: %s / %s (%s%%) ]", hp[1], hp[2], percent)	--:heart:󰀍❤ 当前/最大 (100%)
						else
							r = string.format("[ HP: %s / %s (%s%%) ]", hp[1], hp[2], percent)
						end
                        
                    end
                end
            end
        end
        return r
    else
        return ""
    end
end

function StatusAnnouncer:ClearCooldowns()
	self.cooldown = false
	self.cooldowns = {}
end

function StatusAnnouncer:ClearStats()
	self.stats = {}
	self.button_to_stat = {}
end

--同屏宣告，来自某位大佬，抱歉！实在不知源自谁
function StatusAnnouncer:AnnounceCount(count1, name1, count2, name2, dis, ent)
    if type(name1) ~= "string" then
        return
    end

    local announce_str = " "
	local hover_text = AnHPInfo(ent)
	local ssa = STRINGS._STATUS_ANNOUNCEMENTS._
	
    local target = ""
    local show_target = ""
	local combat = ent.replica and ent.replica.combat
	local combat_target = combat and combat._target and combat._target:value() or nil
	if combat_target then
		target = get_display_name(combat_target) or ssa.An_null

		show_target = subfmt(ssa.ANNONCE_COUNT.SHOW_TARGET, {
			TARGET = target,
		})
	end
	
    if count1 < 2 then
        announce_str = subfmt(ssa.ANNONCE_COUNT.ONE, {
            NAME = name2,
			HOVER = hover_text,
			DISTANCE = dis,
            SHOW_TARGET = show_target
        })
    else
        local str =  " "
		
        if count2 ~= count1 and name1 ~= name2 then
            --str = "，"..count2..STRINGS._STATUS_ANNOUNCEMENTS._.S..STRINGS._STATUS_ANNOUNCEMENTS._.An_name..name2
            str = "，"..ssa.An_name..name2
		elseif count2 == count1 and name1 ~= name2 then
			name1 = name2
			str = subfmt("，"..ssa.An_distance, {
				DISTANCE = dis,
			})
		else
			str = subfmt("，"..ssa.An_distance, {
				DISTANCE = dis,
			})
        end

        announce_str = subfmt(ssa.ANNONCE_COUNT.MORE, {
            COUNT = count1,
            STRING = str,
			HOVER = hover_text,
			SHOW_TARGET = show_target,
            NAME = name1
        })
    end
    return self:Announce(announce_str)
end

function StatusAnnouncer:AnnounceSingle(name, dis, ent)
    local target = ""
    local show_target = ""
	local hover_text = AnHPInfo(ent)
	local ssa = STRINGS._STATUS_ANNOUNCEMENTS._

	local combat = ent.replica and ent.replica.combat
	local combat_target = combat and combat._target and combat._target:value() or nil
    if combat_target then
        target = get_display_name(combat_target) or ssa.An_null

        show_target = subfmt(ssa.ANNONCE_COUNT.SHOW_TARGET, {
            TARGET = target,
        })
    end
    if ent.prefab == "skeleton_player" then
        local client_obj = ent.components.playeravatardata and ent.components.playeravatardata:GetData() or {}
        if client_obj.name == ThePlayer.name then -- 没有userid
            name = ssa.ANNOUNCE_SAYHI.me
        else
            name = client_obj.name or ssa.An_null2
        end
        name = name..ssa.ANNOUNCE_SAYHI.skeleton
    end
    return self:Announce(subfmt(ssa.ANNONCE_COUNT.ONE, {
        NAME = name,
        DISTANCE = dis,
		HOVER = hover_text,
        SHOW_TARGET = show_target
    }))
end

function StatusAnnouncer:AnnouncePeople(he)
    local ssa = STRINGS._STATUS_ANNOUNCEMENTS._
    local sayHi = ssa.ANNOUNCE_SAYHI
	local hover_text = AnHPInfo(he)

    local message = sayHi.greeting

    if he:HasTag("playerghost") then
        message = sayHi.ghost_he
    end                                                -- 如果他死了
    if ThePlayer:HasTag("playerghost") then
        message = sayHi.ghost_me
    end                                         -- 如果我死了
    if he:HasTag("playerghost") and ThePlayer:HasTag("playerghost") then
        message = sayHi.ghost_we
    end            -- 如果我们都死了

    return self:Announce(subfmt(message[math.random(#message)], {
        NAME = he.name,
		HOVER = hover_text
    }))
end
--END

-- 降雨预测
local function GetWorldType()
	return TheWorld:HasTag("porkland") and "porkland"
		or TheWorld:HasTag("island") and "island"
		or TheWorld:HasTag("cave") and "Caves"
		or "Surface"
end

local function GetWorldDisplayName(world_type)
	local S = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP
	if world_type == "porkland" then
		return S.PORKLAND
	elseif world_type == "island" then
		return S.ISLAND
	elseif world_type == "Caves" then
		return S.CAVES
	end
	return S.SURFACE
end

local function GetMoistureRates(world_type)
	if world_type == "island" then
		return {
			MIN = {
				mild = 0,
				wet = 3,
				green = 3,
				dry = 0,
			},
			MAX = {
				mild = .1,
				wet = 3.75,
				green = 3.75,
				dry = -.2,
			},
		}
	elseif world_type == "porkland" then
		return {
			MIN = {
				temperate = .25,
				humid = 3,
				lush = 0,
				aporkalypse = .1,
			},
			MAX = {
				temperate = 1,
				humid = 3.75,
				lush = -.2,
				aporkalypse = .5,
			},
		}
	end
	return {
		MIN = {
			autumn = .25,
			winter = .25,
			spring = 3,
			summer = .1,
		},
		MAX = {
			autumn = 1,
			winter = 1,
			spring = 3.75,
			summer = .5,
		},
	}
end

local function PredictRainStart()
	local world_type = GetWorldType()
	local rates = GetMoistureRates(world_type)
	local state = TheWorld.state
	local season = state.season
	local seasonprogress = tonumber(state.seasonprogress) or 0
	local elapseddaysinseason = tonumber(state.elapseddaysinseason) or 0
	local remainingdaysinseason = tonumber(state.remainingdaysinseason) or 0
	local moisture = tonumber(state.moisture)
	local moistureceil = tonumber(state.moistureceil)
	local min_rate = rates.MIN[season]
	local max_rate = rates.MAX[season]
	local world_name = GetWorldDisplayName(world_type)

	if moisture == nil or moistureceil == nil or min_rate == nil or max_rate == nil then
		return world_name, 0, false, world_type
	end

	local progress_left = 1 - seasonprogress
	local totaldaysinseason = progress_left > 0 and remainingdaysinseason / progress_left
		or elapseddaysinseason + remainingdaysinseason
	if totaldaysinseason <= 0 then
		return world_name, 0, false, world_type
	end

	local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - ((tonumber(state.time) or 0) * TUNING.TOTAL_DAY_TIME)
	local final_day = elapseddaysinseason + remainingdaysinseason
	local totalseconds = 0
	local rain = false

	while elapseddaysinseason < final_day do
		local moisturerate
		if world_type == "Surface" and season == "winter" and elapseddaysinseason == 2 then
			moisturerate = 50
		elseif world_type == "island" then
			local adjusted_progress = seasonprogress
			if season == "green" then
				local greenlength = tonumber(state.greenlength) or totaldaysinseason
				adjusted_progress = greenlength > 5 and (elapseddaysinseason - 5) / (greenlength - 5) or 0
			elseif season == "wet" then
				adjusted_progress = seasonprogress * 1.5
			end
			local p = 1 - math.sin(PI * adjusted_progress)
			moisturerate = season == "green" and elapseddaysinseason <= 5 and 0
				or min_rate + p * (max_rate - min_rate)
		else
			local p = 1 - math.sin(PI * seasonprogress)
			moisturerate = min_rate + p * (max_rate - min_rate)
		end

		local next_moisture = moisture + moisturerate * remainingsecondsinday
		if moisturerate > 0 and next_moisture >= moistureceil then
			totalseconds = totalseconds + (moistureceil - moisture) / moisturerate
			rain = true
			break
		end

		moisture = next_moisture
		totalseconds = totalseconds + remainingsecondsinday
		remainingsecondsinday = TUNING.TOTAL_DAY_TIME
		elapseddaysinseason = elapseddaysinseason + 1
		remainingdaysinseason = remainingdaysinseason - 1
		seasonprogress = 1 - remainingdaysinseason / totaldaysinseason
	end

	return world_name, totalseconds, rain, world_type
end

-- 停雨预测
local function PredictRainStop()
	local PRECIP_RATE_SCALE = 10
	local MIN_PRECIP_RATE = .1
	local world_type = GetWorldType()
	local world_name = GetWorldDisplayName(world_type)
	local components = TheWorld.net and TheWorld.net.components or nil
	local weather = components and (
		components.weather
		or (world_type == "island" and components.shipwreckedweather)
		or (world_type == "Caves" and components.caveweather)
		or (world_type == "porkland" and components.plateauweather)
	)
	local dbgstr = weather and weather.GetDebugString and weather:GetDebugString() or nil
	if type(dbgstr) ~= "string" then
		return world_name, 0, world_type
	end

	dbgstr = dbgstr:gsub("%s+", "")
	local pattern = "moisture:([%-%d%.]+)%(([%-%d%.]+)/([%-%d%.]+)%).-preciprate:%(([%-%d%.]+)of([%-%d%.]+)%)"
	local moisture, moisturefloor, moistureceil, preciprate, peakprecipitationrate = dbgstr:match(pattern)
	moisture = tonumber(moisture) or 0
	moisturefloor = tonumber(moisturefloor) or 0
	moistureceil = tonumber(moistureceil) or 0
	preciprate = tonumber(preciprate) or 0
	peakprecipitationrate = tonumber(peakprecipitationrate) or 0

	local totalseconds = 0
	while moisture > moisturefloor and preciprate > 0 and moistureceil > moisturefloor do
		local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
		local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)
		preciprate = math.min(rate, peakprecipitationrate)
		if preciprate <= 0 then
			break
		end
		moisture = math.max(moisture - preciprate * FRAMES * PRECIP_RATE_SCALE, 0)
		totalseconds = totalseconds + FRAMES
	end

	return world_name, totalseconds, world_type
end

--世界温度宣告 -源自Shang
function StatusAnnouncer:AnnounceWorldtemp(pronoun)
    local S = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP or nil -- 以保存一些表查找
    if S then
        local temp = tonumber(TheWorld.state.temperature) or 0
        local message = ""
        local tshow = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.RAIN
        local season = TheWorld.state.season
		local season_keys = {
			spring = "SPRING",
			summer = "SUMMER",
			autumn = "AUTUMN",
			winter = "WINTER",
			temperate = "TEMPERATE",
			humid = "HUMID",
			lush = "LUSH",
			aporkalypse = "APORKALYPSE",
			mild = "MILD",
			wet = "WET",
			green = "GREEN",
			dry = "DRY",
		}
		local season_key = season_keys[season]
		local tseason = season_key and S[season_key] or tostring(season)
		if season_key and S[season_key .. "_RAIN"] then
			tshow = S[season_key .. "_RAIN"]
		end

        if TheWorld.state.pop ~= 1 then
            local world, totalseconds, rain, world_type = PredictRainStart()
            if world_type == "Caves" then
                tshow = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.CAVES_RAIN
            end

            if rain then
                local d = (tonumber(TheWorld.state.cycles) or 0) + 1
					+ (tonumber(TheWorld.state.time) or 0)
					+ (totalseconds / TUNING.TOTAL_DAY_TIME)
                local m = math.floor(totalseconds / 60)
                local s = totalseconds % 60

                message = string.format(STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.RAIN_START, world, d, tshow, m, s)
            else
                message = string.format(STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.RAIN_START2, world, tseason, tshow)
            end
        else
			local world, totalseconds, world_type = PredictRainStop()
            if world_type == "Caves" then
                tshow = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.CAVES_RAIN
            end

            local d = (tonumber(TheWorld.state.cycles) or 0) + 1
				+ (tonumber(TheWorld.state.time) or 0)
				+ (totalseconds / TUNING.TOTAL_DAY_TIME)
            local m = math.floor(totalseconds / 60)
            local s = totalseconds % 60

            message = string.format(STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.RAIN_STOP, world, tshow, d, m, s)
        end

        if EXPLICIT then
            return self:Announce(string.format(STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_WORLDTEMP.WT, temp, temp / 2, message))
        else
            return self:Announce(message)
        end
    end
end
--END
--ping 源自某位大佬
local PERF_LEVELS =
{
    "GOOD", --GOOD
    "OK", --OK
    "BAD", --BAD
}
function StatusAnnouncer:AnnouncePing(playerlist)
    local PingS = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_PING
    if ThePlayer.userid == playerlist.userid then
        local pingN = TheNet:GetAveragePing()
        local announce_str = ""
        if pingN <= 5 then
            --return self:Announce(PingS.BEST)
			announce_str = PingS.BEST
        elseif pingN <= 30 then
            announce_str = PingS.A
        elseif pingN <= 80 then
            announce_str = PingS.B
        elseif pingN <= 500 then
            announce_str = PingS.C
        else
            announce_str = PingS.D
        end
        if (IsSteam() or not TheWorld.ismastersim) then
			if TheInventory:CheckOwnership("emoji_web") then
				announce_str = ":web:: "..announce_str
			else
				announce_str = "Ping: "..announce_str
			end
        end
        return self:Announce(subfmt(announce_str, {
            PING = pingN,
        }))
    else
        local level
        local name
        for k, client in ipairs(TheNet:GetClientTable() or {}) do

            if playerlist.userid == client.userid then
                name = client.name
                if client.performance ~= nil then
                    name = PingS.HOST
                    level = PERF_LEVELS[math.min(client.performance + 1, #PERF_LEVELS)]
                elseif client.netscore ~= nil then
                    level = PERF_LEVELS[math.min(client.netscore + 1, #PERF_LEVELS)]
                else
                    level = "UNKNOWN"
                end
            end
        end
        return self:Announce(subfmt(PingS[level], {
            NAME = name,
        }))
    end
end
--END

function StatusAnnouncer:SetCharacter(prefab)
	self:ClearCooldowns()
	self:ClearStats()
	self.char_messages.prefab = prefab:upper()
	self.stat_names = {}
	for stat, name in pairs(STRINGS._STATUS_ANNOUNCEMENTS._.STAT_NAMES) do
		self.stat_names[stat] = name
	end
	if SHOWEMOJI then
		for stat, emoji in pairs(STRINGS._STATUS_ANNOUNCEMENTS._.STAT_EMOJI) do
			if TheInventory:CheckOwnership("emoji_"..emoji) then
				self.stat_names[stat] = ":"..emoji..":"
			end
		end
	end
end

function StatusAnnouncer:SetLocalParameter(parameter, value)
	if setters[parameter] then setters[parameter](value) end
end

return StatusAnnouncer
