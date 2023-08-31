-- LocalDamageHandler (LocalScript)

local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer

local Character = script.Parent.Parent
local Humanoid = Character.Humanoid
local HumanoidRootPart = Character.HumanoidRootPart

local interruptRun = Character.Run:WaitForChild("interruptRun")
local attackOverride = Character.Roll:WaitForChild("attackOverride")
local movementOverride = Character.Roll:WaitForChild("movementOverride")

--
-- Stun
--

local StunEvent = script.Parent:WaitForChild("StunEvent")
local StunImmune = script.Parent.Stun:WaitForChild("StunImmune")
local KnockbackImmune = script.Parent.Knockback:WaitForChild("KnockbackImmune")

local DamageEvent = script.Parent:WaitForChild("DamageEvent")

local stunned = false
local experiencingKnockback = false

local blockBroken = false
local blockBrokenTime = 3

local lastStunID

StunEvent.OnClientEvent:Connect(function(stunID, currentStun, currentDamage, currentKnockback, currentKnockbackVector, wasBlockBroken)
	
	if currentDamage > 0 then DamageEvent:FireServer(currentDamage) end
	
	if wasBlockBroken and blockBroken ~= true then
		blockBroken = true
		print("Block broken!")
		spawn(function()
			wait(blockBrokenTime)
			blockBroken = false
		end)
	end
	
	if blockBroken then
		currentStun = blockBrokenTime
	end
	
	local function doKnockback()
		--
		-- Knockback (seperate thread)
		--

		spawn(function()
			--
			-- Handle knockback
			--

			if currentKnockback <= 0 or currentKnockbackVector.Magnitude == 0 then return end		-- End early if there is no knockback to apply

			local knockbackForce = HumanoidRootPart:FindFirstChildWhichIsA("BodyVelocity")
			if not knockbackForce then
				knockbackForce = Instance.new("BodyVelocity")
			end

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
	end
	
	if StunImmune.Value == 0 or blockBroken then
		
		lastStunID = stunID
		
		--
		-- Remote Events (stop all movement/attack options)
		--

		if not stunned then 
			interruptRun:Fire(true)
			attackOverride:Fire(script.Name, true)
			movementOverride:Fire(script.Name, true)
		end
		
		--
		-- Knockback
		--
		
		doKnockback()

		--
		-- Handle stun
		--

		stunned = true
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)

		wait(currentStun)

		if lastStunID ~= stunID then return end 		-- Escapes if another stun has overwritten this one

		stunned = false
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)

		--
		-- Remote Events (allow movement/attack options again)
		--

		interruptRun:Fire(false)
		attackOverride:Fire(script.Name, false)
		movementOverride:Fire(script.Name, false)
		
	elseif KnockbackImmune.Value == 0 then
		doKnockback()
	end
	
end)

--
-- Stun Visual Indicator
--

--[[

spawn(function() -- debug
	while true do
		wait()
		if stunned then
			Character.Head.Color = Color3.fromRGB(196, 40, 28)
		else
			Character.Head.Color = Color3.fromRGB(163, 162, 165)
		end
	end
end)

--]]