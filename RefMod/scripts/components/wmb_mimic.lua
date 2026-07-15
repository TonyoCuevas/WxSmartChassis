local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local function on_mimic_prefab_change(self, value)
	if self.inst.replica.wmb_mimic and self.inst.replica.wmb_mimic.mimic_prefab then
		self.inst.replica.wmb_mimic.mimic_prefab:set(value)
	end
end

local WMB_Mimic = Class(function(self, inst)
	self.inst = inst
	self.mimic_prefab = ""
	self.mimic_activatefn = nil
	self.mimic_deactivatefn = nil
end,
nil,
{
	mimic_prefab = on_mimic_prefab_change,
})

--根据名称获取电路功能
local function GetModuFn(prefab)
	local name = string.sub(prefab, 12)
	for _,modu in pairs(module_definitions) do
		if modu.name == name then
			return modu.activatefn, modu.deactivatefn
		end
	end
	return nil,nil
end

--复制电路功能
function WMB_Mimic:Mimic(prefab)
	local activatefn, deactivatefn = GetModuFn(prefab)
	if activatefn and deactivatefn then			
		self.mimic_prefab = prefab
		self.mimic_activatefn = activatefn
		self.mimic_deactivatefn = deactivatefn
		return true
	end	
	return false
end

--清除记录
function WMB_Mimic:ClearMimic()	
	self.mimic_prefab = ""
	self.mimic_activatefn = nil
	self.mimic_deactivatefn = nil
end

--保存
function WMB_Mimic:OnSave()
	return {
		mimic_prefab = self.mimic_prefab
	}
end

--读取
function WMB_Mimic:OnLoad(data)
	if data and data.mimic_prefab then
		self:Mimic(data.mimic_prefab)
	end
end

return WMB_Mimic
