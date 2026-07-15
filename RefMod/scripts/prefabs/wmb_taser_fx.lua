--电气化跳闸特效,修改自原版主教攻击

local assets =
{
	Asset("ANIM", "anim/wagdrone_projectile.zip"),
	Asset("SOUND", "sound/chess.fsb"),
}

local FX_SCALE = 1.25

local function ShowBase(inst)
	local fx = CreateEntity()

	--[[Non-networked entity]]
	--fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")

	fx.AnimState:SetBank("wagdrone_projectile")
	fx.AnimState:SetBuild("wagdrone_projectile")
	fx.AnimState:PlayAnimation("crackle_projection")
	fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	fx.AnimState:SetLightOverride(1)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:SetSortOrder(3)
	fx.AnimState:SetScale(FX_SCALE, FX_SCALE)

	fx.entity:SetParent(inst.entity)
	fx:ListenForEvent("animover", fx.Remove)

	return fx
end

local function Base_PostUpdate_Client(fx)
	fx.AnimState:SetFrame(fx.entity:GetParent().AnimState:GetCurrentAnimationFrame())
	fx:RemoveComponent("updatelooper")
end

local function ShowBase_Client(inst)
	local fx = ShowBase(inst)
	fx:AddComponent("updatelooper")
	fx.components.updatelooper:AddPostUpdateFn(Base_PostUpdate_Client)	
end

local function OnUpdate(inst, dt)
	if not inst._soundplayed then
		inst._soundplayed = true
		inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("wagdrone_projectile")
	inst.AnimState:SetBank("wagdrone_projectile")
	inst.AnimState:PlayAnimation("crackle_hit")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetScale(FX_SCALE, FX_SCALE)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")

	inst:AddComponent("updatelooper")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.components.updatelooper:AddPostUpdateFn(ShowBase_Client)
		return inst
	end

	if not TheNet:IsDedicated() then
		ShowBase(inst)
	end

	inst.components.updatelooper:AddOnUpdateFn(OnUpdate)

	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

	inst.persists = false

	return inst
end

return Prefab("wmb_taser_fx", fn, assets)
