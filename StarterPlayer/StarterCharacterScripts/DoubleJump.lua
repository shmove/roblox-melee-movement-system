-- DoubleJump (LocalScript)
-- -- Animation (Animation)

local UIS = game:GetService("UserInputService")
local char = script.Parent
local plr = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local interruptRun = char.Run:WaitForChild("interruptRun")

local doubleJumpAnim = script:WaitForChild("Animation")

--
-- Overrides
--

local movementOverride = char.Roll:WaitForChild("movementOverride") 	-- event fired when an action starts/stops overriding movement options
local attackOverride = char.Roll:WaitForChild("attackOverride")			-- event to fire when an action starts/stops overriding attack options

local override = false
local movementOverrides = 0

movementOverride.Event:Connect(function(originName, bool)
	if originName == "DoubleJump" then return end
	if bool then movementOverrides+=1
	else		 movementOverrides-=1 
	end

	if movementOverrides > 0 then override = true
	else override = false end
end)

--
-- Double Jump
--

local keybind = Enum.KeyCode.Space
local canDJump = true

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not canDJump then return end
	if override then 
		local state = char.Humanoid:GetState()
		if input.KeyCode == Enum.KeyCode.Space then
			char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			while true do
				wait()
				if not override then char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) break end
			end
		end return
	end

	if input.KeyCode == keybind then
		if char.Humanoid.FloorMaterial ~= Enum.Material.Air then return end

		interruptRun:Fire(true)
		attackOverride:Fire(script.Name, true)
		canDJump = false
		
		--print("Double jumping...")
		
		local anim = char.Humanoid:LoadAnimation(doubleJumpAnim)
		
		anim:Play()
		
		local doubleJump = char.HumanoidRootPart:FindFirstChildWhichIsA("BodyVelocity")
		if not doubleJump then
			doubleJump = Instance.new("BodyVelocity") -- creates BodyVelocity if it does not yet exist; cancels other BodyVelocities
		end
		doubleJump.MaxForce = Vector3.new(0,1,0) * 25000
		
		local speed = 60
		local overwritten = false -- stores whether this movement was overwritten by another
		
		doubleJump.Velocity = Vector3.new(0, 1, 0) * speed
		doubleJump.Parent = char.HumanoidRootPart
		
		local lastVel = doubleJump.Velocity -- keeps track of velocity last applied by this movement
		
		for count = 1, 3 do
			wait(0.1)
			if doubleJump.Velocity ~= lastVel then
				overwritten = true
				break -- escape loop
			end
			speed *= 0.5
			doubleJump.Velocity = Vector3.new(0, 1, 0) * speed
			lastVel = doubleJump.Velocity
		end
		
		anim:Stop()
		anim:Destroy()
		if not overwritten then doubleJump:Destroy() end
		
		if char.Humanoid.FloorMaterial == Enum.Material.Air then
			while char.Humanoid.FloorMaterial == Enum.Material.Air do -- waits until player is back on the ground
				wait(0.01) --sleep
			end
		end
		
		canDJump = true
		interruptRun:Fire(false)
		attackOverride:Fire(script.Name, false)
			
	end
end)