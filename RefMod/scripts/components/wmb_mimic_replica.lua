local WMB_Mimic = Class(function(self, inst)
	self.inst = inst
	self.mimic_prefab = net_string(inst.GUID, "WMB_wx78module_mimic", "WMB_wx78module_mimic.dirty")
end)

function WMB_Mimic:GetMimicPrefab()
	return self.mimic_prefab:value() or ""
end

return WMB_Mimic
