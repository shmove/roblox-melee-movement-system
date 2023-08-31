-- Run (LocalScript)
-- -- highFriction (BindableEvent)
-- -- interruptRun (BindableEvent)
-- -- Run (Animation)

local Player = game.Players.LocalPlayer
local Humanoid = Player.Character:WaitForChild("Humanoid")
local UIS = game:GetService('UserInputService')
local LastTapped,Tapped = false,false
local Run = Humanoid:LoadAnimation(script:WaitForChild("Run"))
local runService = game:GetService("RunService")

local HttpService = game:GetService("HttpService")

local interruptRun = script:WaitForChild("interruptRun")
local highFriction = script:WaitForChild("highFriction")
local movementOverride = script.Parent.Roll:WaitForChild("movementOverride") 	-- event fired when an action starts/stops overriding movement options

local animInterrupts = 0 -- counts how many animations are interrupting the run anim
local frictionCount = 0 -- counts how many animations are causing high friction

--
-- Overrides
--

local override = false
local movementOverrides = 0

movementOverride.Event:Connect(function(originName, bool)
	if originName == "Run" then return end
	if bool then movementOverrides+=1
	else		 movementOverrides-=1 
	end

	if movementOverrides > 0 then override = true
	else override = false end
end)

--
-- Run
--

local running = false -- keeps track of when the player is still running during other anims
local runSpeed = 28
local walkSpeed = 16
local highFrictionSpeed = 12

local isAirborne = false -- keeps track of when the player is mid jump

-- Keeps speed accurate to state
spawn(function()
	while true do
		wait()
		if frictionCount > 0 and Humanoid.WalkSpeed > highFrictionSpeed then
			Humanoid.WalkSpeed -= 4
			if Humanoid.WalkSpeed < highFrictionSpeed then Humanoid.WalkSpeed = highFrictionSpeed end
		else
			if animInterrupts == 0 then
				if running and Humanoid.WalkSpeed < runSpeed then
					Humanoid.WalkSpeed += 2
					if Humanoid.WalkSpeed > runSpeed then Humanoid.WalkSpeed = runSpeed end
				elseif Humanoid.WalkSpeed < walkSpeed then
					Humanoid.WalkSpeed += 2
					if Humanoid.WalkSpeed > walkSpeed then Humanoid.WalkSpeed = walkSpeed end
				end
			end
		end
	end
end)

local function handleRunInterrupt(bool)
	if bool then 
		animInterrupts+=1
		Run:Stop()
	else animInterrupts-=1 end
	if animInterrupts == 0 and running then startRun() end
	--print("animInterrupts:", animInterrupts)
end

local function handleHighFriction(originName, bool)
	if bool then
		frictionCount += 1
		handleRunInterrupt(true)
	else
		frictionCount -= 1
		handleRunInterrupt(false)
	end
	--print(Player.Name, "highFriction", frictionCount)
end

interruptRun.Event:Connect(handleRunInterrupt) -- keep track of how many anim interrupts are active (fire with true when interrupting, false when ending interrupting anim)
highFriction.Event:Connect(handleHighFriction)

function startRun()
	running = true
	Run:Play()
end

function stopRun()
	running = false
	Run:Stop()
	Humanoid.WalkSpeed = walkSpeed
end

UIS.InputBegan:Connect(function(Input, IsTyping)
	if IsTyping then return end
	if Input.KeyCode == Enum.KeyCode.W then
		if Tapped == false then
			Tapped = true
		else
			if override then return end
			LastTapped = true
			Tapped = false
			
			-- If player is falling/jumping when starting the run, acknowledge the run has started but also that they are airborne and the anim should be interrupted
			if Humanoid.FloorMaterial == Enum.Material.Air and running == false then
				running = true
				Humanoid.WalkSpeed = runSpeed
			else startRun() end
			
			runService.RenderStepped:Connect(function() -- Stops running if the user comes to a halt
				if not running then return end
				if Humanoid.MoveDirection.Magnitude == 0 then stopRun() end
			end)
			
			Humanoid.StateChanged:Connect(function(oldState, newState) -- checks for jumps/falls and handles them accordingly
				if (newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall) and isAirborne == false then
					isAirborne = true
					interruptRun:Fire(true)
				elseif newState == Enum.HumanoidStateType.Landed and isAirborne == true then
					isAirborne = false
					interruptRun:Fire(false)
				end
			end)			
			
		end

		delay(.4, function()
			if Tapped then
				Tapped = false
			end
		end)

	end
end)

UIS.InputEnded:Connect(function(Input, IsTyping)
	if IsTyping then return end
	if Input.KeyCode == Enum.KeyCode.W and LastTapped and not Tapped then
		stopRun()
	end
end)
