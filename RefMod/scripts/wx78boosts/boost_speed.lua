--加速电路


local speed_noquipslow = GetModConfigData("speed_noquipslow")
local speed_guarantee = GetModConfigData("speed_guarantee")

local LEAST = GetModConfigData("speed_least") or 0.1

--为加速电路设置元表,防止出现意外数量
setmetatable(TUNING.WX78_MOVESPEED_CHIPBOOSTS, {
	__index = function(t, k)
		if not (type(k) == "number" and math.floor(k) == k) then return end
		return 0.5 + LEAST*(k-4)
	end
})

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_speed_tag = net_bool(inst.GUID, "WMB_speed_tag", "WMB_speed_tag.dirty")
	inst.WMB_speed_tag:set(false)
end)
AddPrefabPostInit("wx78_classified", function(inst)
	inst.WMB_speed_tag = net_bool(inst.GUID, "WMB_speed_tag", "WMB_speed_tag.dirty")
	inst.WMB_speed_tag:set(false)
end)

local function SetSpeedModu(wx, bool)
	if wx.player_classified and wx.player_classified.WMB_speed_tag then
		wx.player_classified.WMB_speed_tag:set(bool)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_speed_tag then
		wx.wx78_classified.WMB_speed_tag:set(bool)
	end
end

local function HasSpeedModu(wx)
	if wx.player_classified
		and wx.player_classified.WMB_speed_tag
		and wx.player_classified.WMB_speed_tag:value()
	then
		return true
	end
	
	if wx.wx78_classified
		and wx.wx78_classified.WMB_speed_tag
		and wx.wx78_classified.WMB_speed_tag:value()
	then
		return true
	end
	
	return false
end

--加速电路激活
local function speed1_activate(modu, wx)
	wx.WMB_speed1num = (wx.WMB_speed1num or 0) + 1
	
	SetSpeedModu(wx, true)
end
local function speed_activate(modu, wx)
	wx.WMB_speednum = (wx.WMB_speednum or 0) + 1	
	
	SetSpeedModu(wx, true)
end

--加速电路关闭
local function speed1_deactivate(modu, wx)
	wx.WMB_speed1num = math.max(0, (wx.WMB_speed1num or 0) - 1)
	wx.WMB_speednum = wx.WMB_speednum or 0
	
	if wx.WMB_speed1num <= 0 and wx.WMB_speednum <= 0 then
		SetSpeedModu(wx, false)
	end
end
local function speed_deactivate(modu, wx)
	wx.WMB_speednum = math.max(0, (wx.WMB_speednum or 0) - 1)
	wx.WMB_speed1num = WMB_speed1num or 0

	if wx.WMB_speednum <= 0 and wx.WMB_speed1num <= 0 then
		SetSpeedModu(wx, false)
	end
end


--加速电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "movespeed" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			speed1_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			speed1_deactivate(modu, wx)
		end
	end
	if modu.name == "movespeed2" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			speed_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			speed_deactivate(modu, wx)
		end
	end
end

--移速修改
AddComponentPostInit("locomotor", function(self)

	--装备不减速
	if speed_noquipslow then
		local oldfn = self.GetSpeedMultiplier
		if self.ismastersim then
			self.GetSpeedMultiplier = function(self, ...)
				if HasSpeedModu(self.inst)
					and (self.inst.components.rider == nil or not self.inst.components.rider:IsRiding())
				then
					local mult = self:ExternalSpeedMultiplier()
					if self.inst.components.inventory ~= nil and self.inst.components.inventory.isopen then
						for k, v in pairs(self.inst.components.inventory.equipslots) do
							if v.components.equippable ~= nil then
								local item_speed_mult = v.components.equippable:GetWalkSpeedMult()
								if item_speed_mult < 1 then
									item_speed_mult = 1
								end
								mult = mult * item_speed_mult
							end
						end
					end
					return mult * (self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) * self.throttle
				elseif oldfn then
					return oldfn(self, ...)
				end
			end
		else
			self.GetSpeedMultiplier = function(self, ...)
				if HasSpeedModu(self.inst)
					and (self.inst.replica.rider == nil or not self.inst.replica.rider:IsRiding())
				then
					local mult = self:ExternalSpeedMultiplier()
					local inventory = self.inst.replica.inventory
					if inventory ~= nil then
						for k, v in pairs(inventory:GetEquips()) do
							local inventoryitem = v.replica.inventoryitem
							if inventoryitem ~= nil then
								local item_speed_mult = inventoryitem:GetWalkSpeedMult()
								if item_speed_mult < 1 then
									item_speed_mult = 1
								end
								mult = mult * item_speed_mult
							end
						end
					end
					return mult * (self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) * self.throttle
				elseif oldfn then
					return oldfn(self, ...)
				end
			end
		end
	end
	
	--移速保底
	if speed_guarantee then
		local oldwalkfn = self.GetWalkSpeed
		function self:GetWalkSpeed()
			if HasSpeedModu(self.inst) then
				return self.walkspeed * math.max(1, self:GetSpeedMultiplier())
			end
			return oldwalkfn(self)
		end
		
		local oldrunfn = self.GetRunSpeed
		function self:GetRunSpeed()
			if HasSpeedModu(self.inst) then
				return self:RunSpeed() * math.max(1, self:GetSpeedMultiplier())
			end			
			return oldrunfn(self)
		end
	end
end)

--测试用
--TheNet:Say(ThePlayer.components.locomotor:GetWalkSpeed())
--TheNet:Say(ThePlayer.components.locomotor:GetRunSpeed())

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_movespeed", function(modu)
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
AddPrefabPostInit("wx78module_movespeed2", function(modu)
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
