-- DamageHandler (Script)
-- -- Damage (NumberValue) (Value:0)
-- -- -- DamageImmune (NumberValue) (Value:0)
-- -- Knockback (NumberValue) (Value:-1)
-- -- KnockbackVector (Vector3Value) (Value:0,0,0)
-- -- Stun (NumberValue) (Value:-1)
-- -- -- StunImmune (NumberValue) (Value:0)
-- -- LocalDamageHandler (LocalScript)
-- -- BindableStunEvent (BindableEvent)
-- -- DamageEvent (RemoteEvent)
-- -- StunEvent (RemoteEvent)

--- Services & Player ------------------------------------------------

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players:GetPlayerFromCharacter(script.Parent)
local Humanoid = script.parent.Humanoid

--- UUID -------------------------------------------------------------

local UUID = HttpService:GenerateGUID(false)
Humanoid:SetAttribute("UUID", UUID)


--- Invulnerability --------------------------------------------------

local InvulnerabilityEvent = script.Parent.Roll:WaitForChild("Invulnerability")
local DamageImmuneAttribute = script.Damage:WaitForChild("DamageImmune")

InvulnerabilityEvent.onServerEvent:Connect(function(Player, invTime)

	DamageImmuneAttribute.Value+=1

	wait(invTime)

	DamageImmuneAttribute.Value-=1

end)


--- Blocking ---------------------------------------------------------

local blocking = false
local validBlock = false

local attackOverride = script.parent.RemoteEvents:WaitForChild("attackOverride")
local highFriction = script.parent.RemoteEvents:WaitForChild("highFriction")
local movementOverride = script.parent.RemoteEvents:WaitForChild("movementOverride")

local attackOverrides = 0
local highFrictionCount = 0
local movementOverrides = 0

attackOverride.onServerEvent:Connect(function(Player, originName, bool)
	if originName ~= "Block" then return end
	if bool then attackOverrides+=1
	else 		 attackOverrides-=1
	end
end)

highFriction.onServerEvent:Connect(function(Player, originName, bool)
	if originName ~= "Block" then return end
	if bool then highFrictionCount+=1
	else 		 highFrictionCount-=1
	end
end)

movementOverride.onServerEvent:Connect(function(Player, originName, bool)
	if originName ~= "Block" then return end
	if bool then movementOverrides+=1
	else 		 movementOverrides-=1
	end
end)

spawn(function()
	while true do
		if attackOverrides > 0 and highFrictionCount > 0 and movementOverrides > 0 then validBlock = true
		else 																			validBlock = false end
		wait()
	end
end)

local blockEvent = script.Parent.Block:WaitForChild("BlockEvent")
local blockCount = 0

local StunImmuneAttribute = script.Stun:WaitForChild("StunImmune")

blockEvent.onServerEvent:Connect(function(Player, originName, bool)
	if originName ~= "Block" then return end
	if bool then blockCount+=1
	else		 blockCount-=1
	end
	
	if blockCount>0 then blocking = true
	else				 blocking = false end
	
	wait()
	
	local currentBlock = false
	
	if blocking and validBlock then
		StunImmuneAttribute.Value += 1
		while blocking and validBlock do
			currentBlock = true
			wait()
		end
	end
	
	if currentBlock then StunImmuneAttribute.Value -= 1 end
end)

--[[
spawn(function()
	while true do
		if blocking and validBlock then StunImmuneAttribute.Value += 1 end
		wait()
	end
end)
--]]


--- Stun -------------------------------------------------------------

local StunAttribute = script:WaitForChild("Stun")
local DamageAttribute = script:WaitForChild("Damage")
local KnockbackAttribute = script:WaitForChild("Knockback")
local KnockbackVectorAttribute = script:WaitForChild("KnockbackVector")

local StunEvent = script:WaitForChild("StunEvent")
local BindableStunEvent = script:WaitForChild("BindableStunEvent")

local removeStamina = script.Parent.Stamina:WaitForChild("removeStaminaBindable")

local blockBroken = false

-- Config
local blockBrokenTime = 3

StunAttribute.Changed:Connect(function(currentStun)
	if currentStun <= 0 then StunAttribute.Value = -1 return end
	
	--
	-- Stun Identifier
	--

	local stunID = HttpService:GenerateGUID(false) 	-- Makes a UUID for this instance of the stun, can be checked against to see if another stun has overriden it
	local stunImmune = StunImmuneAttribute.Value
	
	--
	-- Attribute Handling
	--
	
	local currentDamage = DamageAttribute.Value
	local currentKnockback = KnockbackAttribute.Value
	local currentKnockbackVector = KnockbackVectorAttribute.Value

	StunAttribute.Value = -1								-- Resets the attributes so another stun could override
	DamageAttribute.Value = -1
	KnockbackAttribute.Value = -1
	KnockbackVectorAttribute.Value = Vector3.new(0,0,0)
	
	--
	-- Handles Stun & Knockback
	--
	
	if DamageImmuneAttribute.Value == 0 then
		local realDamage = currentDamage
		local realKnockback = currentKnockback
		
		if blocking and validBlock and blockBroken == false then
			realKnockback*=0.4
			realDamage-=30
			if realDamage < 0 then
				realDamage = 0
			end
			
			local canRemove, remainingStam = removeStamina:Invoke(Player, currentDamage - realDamage)
			
			if canRemove == false then
				blockBroken = true
				spawn(function()
					removeStamina:Invoke(Player, remainingStam)
					wait(blockBrokenTime)
					blockBroken = false
				end)
			end
		end
		StunEvent:FireClient(Player, stunID, currentStun, realDamage, realKnockback, currentKnockbackVector, blockBroken)
		if stunImmune == 0 then BindableStunEvent:Fire(true) end
		wait(currentStun)
		if stunImmune == 0 then BindableStunEvent:Fire(false) end
	end
	
end)


--- Damage -----------------------------------------------------------

local DamageEvent = script:WaitForChild("DamageEvent")

DamageEvent.onServerEvent:Connect(function(thisPlayer, damage)
	if thisPlayer~=Player then return end
	if damage <= 0 then print("Nice try.") Humanoid:TakeDamage(Humanoid.MaxHealth) return end
	Humanoid:TakeDamage(damage)
end)