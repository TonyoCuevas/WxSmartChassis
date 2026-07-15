--光电电路

local nightReveal = {} --需要揭示的实体

--远古祭坛
if GetModConfigData("night_altar") then
	table.insert(nightReveal, {prefab = "ancient_altar", iconName = "tab_crafting_table.png"})
	table.insert(nightReveal, {prefab = "ancient_altar_broken", iconName = "tab_crafting_table.png"})
end

--远古合奏机
if GetModConfigData("night_archive_orchestrina") then
	table.insert(nightReveal, {prefab = "archive_orchestrina_main", iconName = "archive_orchestrina_main.png"})
end

--远古大门
if GetModConfigData("night_atrium_gate") then
	table.insert(nightReveal, {prefab = "atrium_gate", iconName = "atrium_gate_active.png"})
end

--蚁狮
if GetModConfigData("night_antlion") then
	table.insert(nightReveal, {prefab = "antlion"})
end

--皮弗娄牛
if GetModConfigData("night_beefalo") then
	table.insert(nightReveal, {prefab = "beefalo"})
	table.insert(nightReveal, {prefab = "babybeefalo"})
end

--巨大蜂窝
if GetModConfigData("night_beequeen") then
	table.insert(nightReveal, {prefab = "beequeenhive"})
	table.insert(nightReveal, {prefab = "beequeenhivegrown"})
end

--眼骨和星空
if GetModConfigData("night_chester") then
	table.insert(nightReveal, {prefab = "chester_eyebone"})
	table.insert(nightReveal, {prefab = "hutch_fishbowl"})
end

--帝王蟹
if GetModConfigData("night_crabking") then
	table.insert(nightReveal, {prefab = "crabking"})
end

--梦魇疯猪和拾荒疯猪
if GetModConfigData("night_daywalker") then
	table.insert(nightReveal, {prefab = "daywalker"})
	table.insert(nightReveal, {prefab = "junk_pile_big", iconName = "junk_pile_big.png"})
end

--齿轮生物
if GetModConfigData("night_gears") then
	table.insert(nightReveal, {prefab = "bishop"})
	table.insert(nightReveal, {prefab = "bishop_nightmare"})
	table.insert(nightReveal, {prefab = "knight"})
	table.insert(nightReveal, {prefab = "knight_nightmare"})
	table.insert(nightReveal, {prefab = "rook"})
	table.insert(nightReveal, {prefab = "rook_nightmare"})
end

--隐士之家
if GetModConfigData("night_hermithouse") then
	table.insert(nightReveal, {prefab = "hermithouse_construction1", iconName = "hermitcrab_home.png"})
	table.insert(nightReveal, {prefab = "hermithouse_construction2", iconName = "hermitcrab_home.png"})
	table.insert(nightReveal, {prefab = "hermithouse_construction3", iconName = "hermitcrab_home.png"})
	table.insert(nightReveal, {prefab = "hermithouse", iconName = "hermitcrab_home2.png"})
end

--赃物袋
if GetModConfigData("night_klaus_sack") then
	table.insert(nightReveal, {prefab = "klaus_sack", iconName = "klaus_sack.png"})
end

--伏特羊
if GetModConfigData("night_lightninggoat") then
	table.insert(nightReveal, {prefab = "lightninggoat"})
end

--曼德拉草
if GetModConfigData("night_mandrake") then
	table.insert(nightReveal, {prefab = "mandrake"})
	table.insert(nightReveal, {prefab = "mandrake_active"})
	table.insert(nightReveal, {prefab = "mandrake_planted"})
end

--月台
if GetModConfigData("night_moonbase") then
	table.insert(nightReveal, {prefab = "moonbase", iconName = "moonbase.png"})
end

--猴女王
if GetModConfigData("night_monkeyqueen") then
	table.insert(nightReveal, {prefab = "monkeyqueen", iconName = "monkey_queen.png"})
end

--猪王
if GetModConfigData("night_pigking") then
	table.insert(nightReveal, {prefab = "pigking", iconName = "pigking.png"})
end

--盐堆
if GetModConfigData("night_saltstack") then
	table.insert(nightReveal, {prefab = "saltstack", iconName = "saltstack.png"})
end

--可疑大理石
if GetModConfigData("night_sculpture") then
	table.insert(nightReveal, {prefab = "sculpture_bishophead", iconName = "sculpture_bishophead.png"})
	table.insert(nightReveal, {prefab = "sculpture_knighthead", iconName = "sculpture_knighthead.png"})
	table.insert(nightReveal, {prefab = "sculpture_rooknose", iconName = "sculpture_rooknose.png"})
	
	table.insert(nightReveal, {prefab = "sculpture_bishopbody", iconName = "sculpture_bishopbody_fixed.png"})
	table.insert(nightReveal, {prefab = "sculpture_knightbody", iconName = "sculpture_knightbody_fixed.png"})
	table.insert(nightReveal, {prefab = "sculpture_rookbody", iconName = "sculpture_rookbody_fixed.png"})
end

--毒菌蟾蜍
if GetModConfigData("night_toadstool") then
	table.insert(nightReveal, {prefab = "toadstool_cap", iconName = "toadstool_hole.png"})
end

--盒中泰拉
if GetModConfigData("night_terrarium") then
	table.insert(nightReveal, {prefab = "terrarium", iconName = "terrarium.png"})
end

--海象
if GetModConfigData("night_walrus") then
	table.insert(nightReveal, {prefab = "walrus"})
	table.insert(nightReveal, {prefab = "walrus_camp", iconName = "igloo.png"})
end

--天体部件
if GetModConfigData("night_moon_altar") then
	table.insert(nightReveal, {prefab = "moon_altar_idol", iconName = "moon_altar_idol_piece.png"})
	table.insert(nightReveal, {prefab = "moon_altar_rock_idol", iconName = "moon_altar_idol_rock.png"})
	table.insert(nightReveal, {prefab = "moon_altar_glass", iconName = "moon_altar_glass_piece.png"})
	table.insert(nightReveal, {prefab = "moon_altar_rock_glass", iconName = "moon_altar_glass_rock.png"})
	table.insert(nightReveal, {prefab = "moon_altar_seed", iconName = "moon_altar_seed_piece.png"})
	table.insert(nightReveal, {prefab = "moon_altar_rock_seed", iconName = "moon_altar_seed_rock.png"})
	
	table.insert(nightReveal, {prefab = "moon_altar_ward", iconName = "moon_altar_ward_piece.png"})
	table.insert(nightReveal, {prefab = "moon_altar_icon", iconName = "moon_altar_icon_piece.png"})

	table.insert(nightReveal, {prefab = "moon_altar_crown", iconName = "moon_altar_crown_piece.png"})
end


--需要揭示的实体初始化
if #nightReveal > 0 then
	for _,v in pairs(nightReveal) do
		AddPrefabPostInit(v.prefab, function(inst)
			if TheWorld.ismastersim then
				inst:DoTaskInTime(.1, function(inst)				
					local iconName = v.iconName or (v.prefab)..".wmb"
					inst:AddComponent("maprevealable")
					inst.components.maprevealable:SetIcon(iconName)
					inst.components.maprevealable:SetIconPriority(10)
					inst.components.maprevealable:AddRevealSource(inst, "WMB_nightreveal")
				end)
			end	
		end)
	end
end

--光电电路激活
local function night_activate(modu, wx)
	wx.WMB_nightnum = (wx.WMB_nightnum or 0) + 1
	--揭示实体位置
	wx:AddTag("WMB_nightreveal")
	
	--更新护目镜效果
	if wx.components.playervision then
		wx.components.playervision:ForceGoggleVision(true)
	end
end

--光电电路关闭
local function night_deactivate(modu, wx)
	wx.WMB_nightnum = math.max(0, (wx.WMB_nightnum or 0) - 1)
	--取消揭示实体位置
	if wx.WMB_nightnum <= 0 then
		wx:RemoveTag("WMB_nightreveal")
		
		--更新护目镜效果
		if wx.components.playervision then
			wx.components.playervision:ForceGoggleVision(false)
		end
	end
end

--光电电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "nightvision" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			night_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			night_deactivate(modu, wx)
		end
	end
end

--护目镜效果
if GetModConfigData("night_goggle") then
	AddComponentPostInit("playervision", function(PlayerVision)
		local oldfn = PlayerVision.HasGoggleVision
		function PlayerVision:HasGoggleVision(...)
			if self.inst and self.inst:HasTag("WMB_nightreveal") then
				return true
			end
			return oldfn(self, ...)
		end
	end)
end


-- AddPrefabPostInit("wx78module_nightvision", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- night_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- night_deactivate(modu, wx)
		-- end
    -- end
-- end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_nightvision", function(modu)
    if TheWorld.ismastersim  then
	
		local oldfn = modu.ListenForEvent
		function modu:ListenForEvent(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)
		end	
		
		local oldfn = modu.RemoveEventCallback
		function modu:RemoveEventCallback(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)		
		end
		
    end
end)
