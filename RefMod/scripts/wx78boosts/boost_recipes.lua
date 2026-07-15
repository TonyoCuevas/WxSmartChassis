--物品配方调整

local recipe_scanner = GetModConfigData("recipe_scanner")
local recipe_health1 = GetModConfigData("recipe_health1")
local recipe_health = GetModConfigData("recipe_health")
local recipe_sanity1 = GetModConfigData("recipe_sanity1")
local recipe_sanity = GetModConfigData("recipe_sanity")
local recipe_bee = GetModConfigData("recipe_bee")
local recipe_music = GetModConfigData("recipe_music")
local recipe_hunger1 = GetModConfigData("recipe_hunger1")
local recipe_hunger = GetModConfigData("recipe_hunger")
local recipe_heat = GetModConfigData("recipe_heat")
local recipe_cold = GetModConfigData("recipe_cold")
local recipe_taser = GetModConfigData("recipe_taser")
local recipe_night = GetModConfigData("recipe_night")
local recipe_light = GetModConfigData("recipe_light")
local recipe_light2 = GetModConfigData("recipe_light2")
local recipe_digestion = GetModConfigData("recipe_digestion")
local recipe_spin = GetModConfigData("recipe_spin")
local recipe_shielding = GetModConfigData("recipe_shielding")


--更改制作配方
local function ChangeRecipe(name, ingredients)
	AddRecipePostInit(name, function(recipe)
		for k,_ in ipairs(recipe.ingredients) do
			recipe.ingredients[k] = nil
		end
		for _,v in ipairs(ingredients) do
			table.insert(recipe.ingredients, v)
		end
	end)	
end

--扫描仪
if recipe_scanner then
	ChangeRecipe("wx78_scanner_item",
		{
			Ingredient("transistor", 1),
			Ingredient("silk", 1),
			Ingredient("gears", 1),
			Ingredient("wagpunk_bits", 1),
		}
	)
end

--强化电路
if recipe_health1 then
	ChangeRecipe("wx78module_maxhealth",
		{
			Ingredient("scandata", 3),
			Ingredient("reviver", 1),
		}
	)
end
if recipe_health then
	ChangeRecipe("wx78module_maxhealth2",
		{
			Ingredient("scandata", 8),
			Ingredient("amulet", 1),
			Ingredient("wx78module_maxhealth", 1),
		}
	)
end

--处理器电路
if recipe_sanity1 then
	ChangeRecipe("wx78module_maxsanity1",
		{
			Ingredient("scandata", 3),
			Ingredient("goldnugget", 5),
		}
	)
end
if recipe_sanity then
	ChangeRecipe("wx78module_maxsanity",
		{
			Ingredient("scandata", 8),
			Ingredient("nightmarefuel", 12),
			Ingredient("transistor", 4),
			Ingredient("wx78module_maxsanity1", 1),
		}
	)
end

--豆增压电路
if recipe_bee then	
	ChangeRecipe("wx78module_bee",
		{
			Ingredient("scandata", 20),
			Ingredient("royal_jelly", 4),
			Ingredient("wx78module_maxhealth2", 1),
			Ingredient("wx78module_maxsanity", 1),
			Ingredient("wx78module_maxhunger", 1),
		}
	)
end

--合唱盒电路
if recipe_music then
	ChangeRecipe("wx78module_music",
		{
			Ingredient("scandata", 20),
			Ingredient("singingshell_octave5", 1, nil, nil, "singingshell_octave5_3.tex"),
			Ingredient("singingshell_octave4", 1, nil, nil, "singingshell_octave4_3.tex"),
			Ingredient("singingshell_octave3", 1, nil, nil, "singingshell_octave3_3.tex"),
			Ingredient("wx78module_heat", 1),
			Ingredient("wx78module_cold", 1),
		}
	)
end

--胃增益电路
if recipe_hunger1 then
	ChangeRecipe("wx78module_maxhunger1",
		{
			Ingredient("scandata", 3),
			Ingredient("houndstooth", 3),
			Ingredient("monstermeat", 10),
		}
	)
end
if recipe_hunger then
	ChangeRecipe("wx78module_maxhunger",
		{
			Ingredient("scandata", 6),
			Ingredient("armorslurper", 1),
			Ingredient("wx78module_maxhunger1", 1),
		}
	)
end

--热能电路
if recipe_heat then
	ChangeRecipe("wx78module_heat",
		{
			Ingredient("scandata", 10),
			Ingredient("redgem", 2),
			Ingredient("dragon_scales", 1),
		}
	)
end

--制冷电路
if recipe_cold then
	ChangeRecipe("wx78module_cold",
		{
			Ingredient("scandata", 10),
			Ingredient("bluegem", 2),
			Ingredient("deerclops_eyeball", 1),
		}
	)
end

--电气化电路
if recipe_taser then	
	ChangeRecipe("wx78module_taser",
		{
			Ingredient("scandata", 10),
			Ingredient("nightstick", 1),
		}
	)
end

--光电电路
if recipe_night then
	ChangeRecipe("wx78module_nightvision",
		{
			Ingredient("scandata", 8),
			Ingredient("purplegem", 1),
			Ingredient("mole", 1),
		}
	)
end

--照明电路
if recipe_light then
	ChangeRecipe("wx78module_light",
		{
			Ingredient("scandata", 10),
			Ingredient("yellowgem", 2),
		}
	)
end
if recipe_light2 then
	ChangeRecipe("wx78module_light2",
		{
			Ingredient("scandata", 20),
			Ingredient("orangegem", 2),
			Ingredient("wx78module_light", 1),
			Ingredient("wx78module_nightvision", 1),
		}
	)
end

--再消化电路
if recipe_digestion then
	ChangeRecipe("wx78module_digestion",
		{
			Ingredient("scandata", 5),
			Ingredient("greengem", 1),
		}
	)
end

--旋转电路
if recipe_spin then
	ChangeRecipe("wx78module_spin",
		{
			Ingredient("scandata", 20),
			Ingredient("gears", 6),
			Ingredient("wx78module_movespeed2", 3),
		}
	)
end

--格挡电路
if recipe_shielding then
	ChangeRecipe("wx78module_shielding",
		{
			Ingredient("scandata", 6),
			Ingredient("armormarble", 1),
		}
	)
end


-- --猪镇配方
-- local function PorklandRecipes()
	-- if not TheWorld:HasTag("porkland") then return end
	
	-- if recipe_scanner then
		-- ChangeRecipe("wx78_scanner_item",
			-- {
				-- Ingredient("transistor", 1),
				-- Ingredient("silk", 1),
				-- Ingredient("gears", 1),
				-- Ingredient("alloy", 1),
			-- }
		-- )		
	-- end
	
	-- if recipe_music then
		-- ChangeRecipe("wx78module_music",
			-- {
				-- Ingredient("scandata", 20),
				-- Ingredient("ox_flute", 1),
				-- Ingredient("onemanband", 1),
			-- }
		-- )
	-- end
	

	-- if recipe_hunger then
		-- ChangeRecipe("wx78module_maxhunger",
			-- {
				-- Ingredient("scandata", 6),
				-- Ingredient("venus_stalk", 3),
				-- Ingredient("wx78module_maxhunger1", 1),
			-- }
		-- )
	-- end
	
	-- if recipe_taser then
		-- ChangeRecipe("wx78module_taser",
			-- {
				-- Ingredient("scandata", 10),
				-- Ingredient("thunderhat", 1),
			-- }
		-- )	
	-- end	
	
	-- if recipe_light then
		-- ChangeRecipe("wx78module_light",
			-- {
				-- Ingredient("scandata", 6),
				-- Ingredient("walkingstick", 1),
				-- Ingredient("lantern", 2),
			-- }
		-- )
	-- end
	
-- end
-- AddPrefabPostInit("porkland", PorklandRecipes)