-- Block (LocalScript)
-- -- BlockEvent (RemoteEvent)
-- -- Animation (Animation)

--- Player -----------------------------------------------------------

local Player = game.Players.LocalPlayer
local Character = script.Parent
local Humanoid = Character.Humanoid


--- Services ---------------------------------------------------------

local UIS = game:GetService("UserInputService")


--- Override Events --------------------------------------------------

local attackOverride = Character.Roll:WaitForChild("attackOverride")
local movementOverride = Character.Roll:WaitForChild("movementOverride")
local highFriction = Character.Run:WaitForChild("highFriction")

local override = false
local movementOverrides = 0

movementOverride.Event:Connect(function(originName, bool)
	if originName == "Block" then return end
	if bool then movementOverrides+=1
	else		 movementOverrides-=1 
	end

	if movementOverrides > 0 then override = true
	else override = false end
end)


--- Config -----------------------------------------------------------

local keybind = Enum.KeyCode.F


--- Block ------------------------------------------------------------

local blocking = false

local blockAnimation = script:WaitForChild("Animation")
local blockAnimTrack = Humanoid:LoadAnimation(blockAnimation)

local blockEvent = script:WaitForChild("BlockEvent")

local function doBlock()
	-- Instantly start block. High friction will be applied. Player cannot roll, jump or attack.
	-- On key release, short cooldown where player is still affected by high friction & cannot roll, jump or attack.
	-- End block and allow all movement and attacks again.

	print("Started block!")

	blocking = true
	blockAnimTrack:Play()

	-- Lock player out of movement & attack options
	attackOverride:Fire(script.Name, true)
	movementOverride:Fire(script.Name, true)
	highFriction:Fire(script.Name, true)

	-- Fire block event
	blockEvent:FireServer(script.Name, true)

	-- Start check for if a movement override manages to come in
	local blockInterrupted = false
	spawn(function()
		while blocking do
			if override then
				blockInterrupted = true
			end
			wait()
		end
	end)

	local isKeyHeld = UIS:IsKeyDown(keybind)

	while (isKeyHeld) and (Humanoid.FloorMaterial ~= Enum.Material.Air) and blockInterrupted == false do
		wait()
		isKeyHeld = UIS:IsKeyDown(keybind)
	end

	-- Player is vulnerable here
	blocking = false
	blockAnimTrack:Stop()
	blockEvent:FireServer(script.Name, false)

	wait(0.1)

	print("Finished block!")

	-- Return movement & attack options to player
	attackOverride:Fire(script.Name, false)
	movementOverride:Fire(script.Name, false)
	highFriction:Fire(script.Name, false)
end

local function performBlock(input, gameProcessed)
	local buffer = false
	if gameProcessed then buffer = true end
	if override then buffer = true end
	if Humanoid.FloorMaterial == Enum.Material.Air then buffer = true end -- can't block in air
	
	if input.KeyCode == keybind and buffer == false then
		
		doBlock()
		
	end
	
	--
	-- Buffer (hold block until available)
	--
	
	if buffer then
		if input.KeyCode == keybind then
			wait()
			if override == false and Humanoid.FloorMaterial ~= Enum.Material.Air and gameProcessed == false and blocking == false then doBlock() end
		end
	end
end


--- Event Handling ---------------------------------------------------

UIS.InputBegan:Connect(performBlock)


--- Debug ------------------------------------------------------------

spawn(function()
	while true do
		wait()
		if blocking then
			Character.Head.Color = Color3.fromRGB(196, 169, 17)
		else
			Character.Head.Color = Color3.fromRGB(163, 162, 165)
		end
	end
end)