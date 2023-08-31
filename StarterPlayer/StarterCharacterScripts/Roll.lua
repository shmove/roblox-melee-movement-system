-- Roll (LocalScript)
-- -- Invulnerability (RemoteEvent)
-- -- attackOverride (BindableEvent)
-- -- movementOverride (BindableEvent)
-- -- BackRoll (Animation)
-- -- LeftStrafe (Animation)
-- -- RightStrafe (Animation)
-- -- Roll (Animation)

local UIS = game:GetService("UserInputService")
local char = script.Parent
local plr = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local staminaFunc = char:WaitForChild("Stamina"):WaitForChild("removeStamina")

local humanoid = char.Humanoid

local interruptRun = char.Run:WaitForChild("interruptRun")
local attackOverride = script:WaitForChild("attackOverride")			-- event to fire when an action starts/stops overriding attack options
local movementOverride = script:WaitForChild("movementOverride") 		-- event fired when an action starts/stops overriding movement options

local invulnerability = script:WaitForChild("Invulnerability")

local override = false
local movementOverrides = 0 -- tracks number of actions overriding movement options

local slideAllowed = false
local slideAllowedCount = 0

local playAnim
local rollAnim = script:WaitForChild("Roll")
local backRollAnim = script:WaitForChild("BackRoll")
local leftStrafeAnim = script:WaitForChild("LeftStrafe")
local rightStrafeAnim = script:WaitForChild("RightStrafe")

local keybind = Enum.KeyCode.Q
local shiftLock = false

local canRoll = true
local noStamina = false
local rolling = false

local staminaCost = 10


--
-- Input Buffer Resources
--

local buffer = false			-- If a movement action is buffered
local bufferRequested = false	-- If there is a queued buffer request
local bufferWindow = 0.03		-- The amount of time the buffer will hold an action
local bufferedInput				-- Input to be held

--
-- Checks for actions overriding movement options
--

movementOverride.Event:Connect(function(originName, bool, permitSlide)
	if originName == "Roll" then return end
	if bool then movementOverrides+=1
	else		 movementOverrides-=1 
	end
	
	if movementOverrides > 0 then override = true
	else override = false end
	
	if permitSlide~=nil then
		if permitSlide then slideAllowedCount+=1
		else				slideAllowedCount-=1
		end

		if slideAllowedCount > 0 then slideAllowed = true
		else slideAllowed = false end
	end
end)

--
-- Checks stamina value
--

spawn(function()
	while true do
		if staminaCost > plr.Stamina.Value then noStamina = true
		else noStamina = false
		end
		wait(0.1)
	end
end)

--
-- Roll Function
--

local function handleRoll(input, gameProcessed)
	if gameProcessed then return end
	if noStamina then return end
	if not canRoll then bufferRequested = true end
	if override then bufferRequested = true end

	if input.KeyCode == keybind and not bufferRequested then

		bufferRequested = false
		buffer = false

		spawn(function()
			staminaFunc:InvokeServer(staminaCost)
		end)
		
		local movementInterrupted = false
		
		spawn(function()
			while not canRoll do
				if override then
					if not slideAllowed then
						movementInterrupted = true
						break
					end
				end
				wait()
			end
		end)

		interruptRun:Fire(true)
		attackOverride:Fire(script.Name, true)
		movementOverride:Fire(script.Name, true)
		invulnerability:FireServer(0.1)
		canRoll = false
		
		local function endMovement() -- function to be run whenever the player is finished rolling - interrupted or not
			if char.Humanoid.FloorMaterial == Enum.Material.Air then
				while char.Humanoid.FloorMaterial == Enum.Material.Air do -- waits until player is back on the ground
					wait(0.01) --sleep
				end
			end

			interruptRun:Fire(false)
			attackOverride:Fire(script.Name, false)
			movementOverride:Fire(script.Name, false)
			canRoll = true
		end

		-- Checks for mouse being locked center; ie shift lock
		-- If something else down the line locks the mouse center for a different reason, this will need to be changed
		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then shiftLock = true
		else shiftLock = false end

		local camera = workspace.CurrentCamera -- get camera			
		local moveDirection = camera.CFrame:VectorToObjectSpace(char.Humanoid.MoveDirection).Unit --get the current direction relative to the camera

		--print("x: ", moveDirection.X, ", y: ", moveDirection.Y, ", z: ", moveDirection.Z)

		if math.abs(moveDirection.X) >= 0.98 then -- if user has very sharp sideways angle (likely strafing)

			--
			-- STRAFE
			--

			--print("Strafing...")

			local strafing = true

			local speed = 75
			if moveDirection.X > 0 then
				-- speed = 75
				playAnim = char.Humanoid:LoadAnimation(rightStrafeAnim)
			else 
				speed = -speed -- if player is going left, negative speed
				playAnim = char.Humanoid:LoadAnimation(leftStrafeAnim)
			end

			local strafe = char.HumanoidRootPart:FindFirstChildWhichIsA("BodyVelocity")
			if not strafe then
				strafe = Instance.new("BodyVelocity") -- creates BodyVelocity if it does not yet exist; cancels other BodyVelocities
			end

			strafe.MaxForce = Vector3.new(1,0,1) * 25000

			local overwritten = false -- stores whether this movement was overwritten by another

			-- gets velocity perpendicular to global Up
			if shiftLock then 	strafe.Velocity = char.HumanoidRootPart.CFrame.LookVector:Cross(Vector3.new(0, 1, 0)) * speed
			else 				strafe.Velocity = camera.CFrame.LookVector:Cross(Vector3.new(0, 1, 0)) * speed	
			end

			strafe.Parent = char.HumanoidRootPart

			local lastVel = strafe.Velocity -- keeps track of velocity last applied by this movement

			-- Make a listener that turns the character to face the camera direction every frame
			local frameListener
			if not shiftLock then
				frameListener = runService.RenderStepped:Connect(function()
					-- Sets player facing angle to point where the camera is pointing
					if strafing then char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(camera.CFrame.LookVector.X * 10000, char.HumanoidRootPart.Position.Y, camera.CFrame.LookVector.Z * 10000))
					else				frameListener:Disconnect()
					end
				end)
			end
			
			playAnim:Play()
			
			if movementInterrupted then 
				playAnim:Stop() 
				playAnim:Destroy() 
				strafing = false
				strafe:Destroy()
				endMovement()
			return end

			for count = 1, 4 do
				wait(0.1)
				if strafe.Velocity ~= lastVel then
					overwritten = true
					break -- escape loop
				end
				speed *= 0.65
				
				if movementInterrupted then break end

				-- updates velocity
				if shiftLock then 	strafe.Velocity = char.HumanoidRootPart.CFrame.lookVector:Cross(Vector3.new(0, 1, 0)) * speed
				else 				strafe.Velocity = camera.CFrame.LookVector:Cross(Vector3.new(0, 1, 0)) * speed
				end

				lastVel = strafe.Velocity
			end

			playAnim:Stop()
			playAnim:Destroy()
			strafing = false
			if not overwritten then strafe:Destroy() end

		elseif moveDirection.Z <= 0 or moveDirection.Z ~= moveDirection.Z then -- checks if player is moving forward, or (if moveDirection.Z is NAN) standing still

			--
			-- FORWARD ROLL
			--

			--print("Rolling...")

			playAnim = char.Humanoid:LoadAnimation(rollAnim)

			local roll = char.HumanoidRootPart:FindFirstChildWhichIsA("BodyVelocity")
			if not roll then
				roll = Instance.new("BodyVelocity") -- creates BodyVelocity if it does not yet exist; cancels other BodyVelocities
			end

			roll.MaxForce = Vector3.new(1,0,1) * 30000 --30000

			local speed = 100 -- keeps track of speed seperately from velocity
			local overwritten = false -- stores whether this movement was overwritten by another

			roll.Velocity = char.HumanoidRootPart.CFrame.lookVector * speed
			roll.Parent = char.HumanoidRootPart

			local lastVel = roll.Velocity -- keeps track of velocity last applied by this movement
			
			playAnim:Play()
			
			if movementInterrupted then
				playAnim:Stop()
				playAnim:Destroy()
				roll:Destroy()
				endMovement()
			return end

			--for count = 1, 8 do
			for count = 1, 4 do
				wait(0.1)
				if roll.Velocity ~= lastVel then
					overwritten = true
					break -- escape loop
				end
				-- speed *= 0.8584
				speed *= 0.7
				
				if movementInterrupted then break end
				
				roll.Velocity = char.HumanoidRootPart.CFrame.lookVector * speed -- gets velocity
				lastVel = roll.Velocity
			end


			playAnim:Stop()
			playAnim:Destroy()
			if not overwritten then roll:Destroy() end

		else

			--
			-- BACK ROLL
			--

			--print("Back rolling...")

			playAnim = char.Humanoid:LoadAnimation(backRollAnim)

			local bRolling = true

			local roll = char.HumanoidRootPart:FindFirstChildWhichIsA("BodyVelocity")
			if not roll then
				roll = Instance.new("BodyVelocity") -- creates BodyVelocity if it does not yet exist; cancels other BodyVelocities
			end

			roll.MaxForce = Vector3.new(1,0,1) * 30000

			local speed = 75
			local overwritten = false -- stores whether this movement was overwritten by another

			-- Make a listener that turns the character to face the camera direction every frame
			local frameListener
			if not shiftLock then
				frameListener = runService.RenderStepped:Connect(function()
					-- Sets player facing angle to point where the camera is pointing
					if bRolling then char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(camera.CFrame.LookVector.X * 10000, char.HumanoidRootPart.Position.Y, camera.CFrame.LookVector.Z * 10000))
					else				frameListener:Disconnect()
					end
				end)
			end

			-- make char face camera initially
			if not shiftLock then char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(camera.CFrame.LookVector.X * 10000, char.HumanoidRootPart.Position.Y, camera.CFrame.LookVector.Z * 10000)) end
			roll.Velocity = char.HumanoidRootPart.CFrame.lookVector * -speed -- gets negative velocity
			roll.Parent = char.HumanoidRootPart

			local lastVel = roll.Velocity -- keeps track of velocity last applied by this movement
			
			playAnim:Play()
			
			if movementInterrupted then
				playAnim:Stop()
				playAnim:Destroy()
				bRolling = false
				roll:Destroy()
				endMovement()
			return end

			for count = 1,4 do
				wait(0.1)
				if roll.Velocity ~= lastVel then
					overwritten = true
					break -- escape loop
				end
				speed *= 0.65
				
				if movementInterrupted then break end

				roll.Velocity = char.HumanoidRootPart.CFrame.lookVector * -speed -- updates velocity
				lastVel = roll.Velocity
			end

			playAnim:Stop()
			playAnim:Destroy()
			bRolling = false
			if not overwritten then roll:Destroy() end

		end

		endMovement()

	elseif input.KeyCode == keybind then
		
		--
		-- Input Buffer
		--

		if not buffer then
			bufferedInput = input
			spawn(function()
				buffer = true -- acknowledge something is being buffered
				bufferRequested = false -- let buffer requests be made

				local timeWaited = 0
				local inputMade = false
				while timeWaited < bufferWindow do
					
					timeWaited+=0.03 -- increment timer
					wait(0.03)

					if bufferRequested then 
						timeWaited = 0 -- reset timer if another input has been made
						bufferRequested = false
					end 

					if canRoll and not override and not noStamina then
						inputMade = handleRoll(bufferedInput, false) -- Recursive function, calls itself to handle roll again, will return true or false if roll cannot be performed
						if inputMade then break end
					end

				end

				bufferRequested = false 
				buffer = false
				
				return true

			end)
		else
			bufferedInput = input -- Input has changed, overwrite
			return false -- Return false since input didnt go through yet
		end
		
	end
	
	return true -- If code reaches this point, input has gone through and so function should return true

end

--
-- Event Handling
--

UIS.InputBegan:Connect(handleRoll)