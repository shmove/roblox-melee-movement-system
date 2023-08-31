-- DamageHandler (Script)
-- -- Damage (NumberValue) (Value:0)
-- -- -- DamageImmune (NumberValue) (Value:0)
-- -- Knockback (NumberValue) (Value:-1)
-- -- KnockbackVector (Vector3Value) (Value:0,0,0)
-- -- Stun (NumberValue) (Value:-1)
-- -- -- StunImmune (NumberValue) (Value:0)

local HttpService = game:GetService("HttpService")
local Humanoid = script.parent.Humanoid
local HumanoidRootPart = Humanoid.Parent.HumanoidRootPart

--
-- Unique ID
--

local UUID = HttpService:GenerateGUID(false)
Humanoid:SetAttribute("UUID", UUID)

--
-- Stun
--

local stunned = false
local experiencingKnockback = false

local StunAttribute = script:WaitForChild("Stun")
local DamageAttribute = script:WaitForChild("Damage")
local KnockbackAttribute = script:WaitForChild("Knockback")
local KnockbackVectorAttribute = script:WaitForChild("KnockbackVector")
local lastStunID

StunAttribute.Changed:Connect(function(currentStun)
	if currentStun <= 0 then StunAttribute.Value = -1 return end
	
	lastStunID = HttpService:GenerateGUID(false) 	-- Makes a UUID for this instance of the stun, can be checked against to see if another stun has overriden it
	local stunID = lastStunID
	
	local currentDamage = DamageAttribute.Value
	local currentKnockback = KnockbackAttribute.Value
	local currentKnockbackVector = KnockbackVectorAttribute.Value
	
	StunAttribute.Value = -1						-- Resets the attributes so another stun could override
	DamageAttribute.Value = -1
	KnockbackAttribute.Value = -1
	KnockbackVectorAttribute.Value = Vector3.new(0,0,0)
	
	if currentDamage > 0 then Humanoid:TakeDamage(currentDamage) end
	
	--
	-- Knockback (seperate thread)
	--
	
	spawn(function()
		if currentKnockback <= 0 or currentKnockbackVector.Magnitude == 0 then return end		-- End early if there is no knockback to apply

		local knockbackForce = Instance.new("BodyVelocity")

		local overwritten = false
		experiencingKnockback = true

		knockbackForce.MaxForce = Vector3.new(1,0,1) * 40000

		knockbackForce.Velocity = currentKnockbackVector * currentKnockback
		knockbackForce.Parent = HumanoidRootPart

		local lastVel = knockbackForce.Velocity

		for count = 1,4 do
			wait(0.1)
			if knockbackForce.Velocity ~= lastVel then
				overwritten = true
				break -- escape loop
			end
			knockbackForce.Velocity *= 0.7
			lastVel = knockbackForce.Velocity
		end

		if not overwritten then knockbackForce:Destroy() end
		experiencingKnockback = false
	end)
	
	--
	-- Handle stun
	--
	
	stunned = true
	Humanoid.WalkSpeed = 0
	
	wait(currentStun)
	
	if lastStunID ~= stunID then return end 		-- Escapes if another stun has overwritten this one
	
	stunned = false
	Humanoid.WalkSpeed = 16
	
end)

spawn(function() --debug
	while true do
		wait()
		if stunned then
			Humanoid.Parent.Head.Color = Color3.fromRGB(196, 40, 28)
		else
			Humanoid.Parent.Head.Color = Color3.fromRGB(163, 162, 165)
		end
	end
end)