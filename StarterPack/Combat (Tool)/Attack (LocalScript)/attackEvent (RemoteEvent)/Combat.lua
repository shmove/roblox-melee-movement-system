-- Combat (Script)
-- -- Anims (Folder)
-- -- -- Combo1 (Animation)
-- -- -- Combo2 (Animation)
-- -- -- Combo3 (Animation)
-- -- -- Combo4 (Animation)
-- -- -- Idle (Animation)

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Player
local Character

if script.Parent.Parent.Parent.Parent.Name == "Backpack" then
	Player = script.Parent.Parent.Parent.Parent.Parent
	Character = Player.Character
else
	Character = script.Parent.Parent.Parent.Parent.Parent:WaitForChild("Character", 5)
	Player = Players:GetPlayerFromCharacter(Character)
end

if not Character then return end

local stunImmune = Character.DamageHandler.Stun:WaitForChild("StunImmune")
local knockbackImmune = Character.DamageHandler.Knockback:WaitForChild("KnockbackImmune")

--
-- Vars
--

local Anim = nil

local tryCooldown = false 	 	-- tracks if player is ATTEMPTING attacking
local tryCooldownTime = .01 	-- time allowed between acknowledged attack attempts (lower = more events running on server BUT more responsive)

local cooldown = false 			-- tracks if player CAN DO next move in combo

local attackOverrides = 0		-- tracks number of actions overriding attacks
local canAttack = true			-- tracks if another action is overriding attack

local rollOverrides = 0			-- tracks number of actions from Roll script overriding attacks
local isRollOverridden = false	-- tracks if there is currently an override from a roll

local comboIndex = 0	-- Current index in combo (0: not active)
local comboWindow = .8 	-- time between attacks to not result in combo ending

local hitboxActive = false		-- tracks if attack hitbox should still be active

local isStunned = false			-- tracks if player has been stunned
local stunCount = 0				-- yet another counter to track overriding stuns (is this a bad way to do it?)

--
-- Override Events
--

local attackOverride = Character.RemoteEvents:WaitForChild("attackOverride")
local movementOverride = Character.RemoteEvents:WaitForChild("movementOverride")
local highFriction = Character.RemoteEvents:WaitForChild("highFriction")

attackOverride.onServerEvent:Connect(function(plr, originName, bool)
	if originName == "Combat" then return end
	if bool then wait() attackOverrides+=1
	else		 attackOverrides-=1 
	end
	
	if originName == "Roll" then
		if bool then rollOverrides+=1
		else		 rollOverrides-=1
		end
	end

	if attackOverrides > 0 then canAttack = false
	else canAttack = true end
	
	if rollOverrides > 0 then isRollOverridden = true
	else isRollOverridden = false end
end)

local StunEvent = Character.DamageHandler:WaitForChild("BindableStunEvent")

StunEvent.Event:Connect(function(bool)
	--print("stunStart", isStunned, stunCount, "(bool passed in:",bool,") (isAttacking:",isAttacking,")")
	if bool then
		if Anim then if Anim.isPlaying then Anim:Stop() end end
		stunCount+=1
		hitboxActive = false
		comboIndex = 0
	else
		if stunCount > 0 then stunCount-=1 end
	end
	
	if stunCount == 0 then isStunned = false else isStunned = true end
	--print(Player.Name, "- Stun:", isStunned, stunCount)
	--print(Player.Name, "- Was stun handled mid-attack?",midAttackHandled)
end)


--
-- Class Declaration
--

local attackData = {} -- stores info on different attacks in combo

function attackData:new (animName, windUp, hitboxTime, windDown, dmg, range, stun, knockback, arc, dir, stunImmune, canSlide, isFinal)
	
	local attack = {}
	
	attack.animName = animName or "err"		-- Name of this attack's animation
	attack.windUp = windUp or 0				-- Time before attack hitbox activates
	
	attack.hitboxTime = hitboxTime or 0		-- Amount of time following windUp that the hitbox is active (cancelled if next move starts)
	
	attack.windDown = windDown or 1			-- Amount of time passed AFTER windUp at which new attack can be made.
											-- This is also time for finishing a combo and starting over again (if isFinal).
	
	attack.dmg = dmg or 0					-- Damage done by the attack (once)
	attack.range = range or 0				-- Range the attack hits at
	attack.stun = stun or 0					-- How long the enemy will be stunned for (should be less than windDown)
	attack.knockback = knockback or 0		-- How far back the enemy will be launched following stun
	
	attack.arc = arc or 90					-- Angle of how wide the attack can hit things (ie dir of 90 & arc of 100 = dmg in range 40 to 140)
	attack.dir = dir or 0					-- Direction the attack is pointed in (0-359) relative to player facing angle
	
	attack.stunImmune = stunImmune or false	-- Whether or not the user is immune to stun/knockback (not damage!!) while this move is winding up
	
	attack.canSlide = canSlide or false		-- Whether this attack can perform the mythical roll+attack combo (TO BE IMPLEMENTED)
	
	attack.isFinal = isFinal or false		-- If this attack is the final attack in the combo
	
	return attack
	
end

--
-- Attack Info
--

local Combo = {}
--							animName		windUp		hitboxTime		windDown	dmg			range		stun		knockback		arc			dir			stunImmune		canSlide	isFinal
Combo[1] = 	attackData:new(	"Combo1",		.07, 		.25,			.08, 		15, 		8, 			.03,		8,				110, 		0,			false,			true)
Combo[2] = 	attackData:new(	"Combo2",		.07, 		.25,			.1, 		15, 		8, 			.05,		8,				110			)
Combo[3] =	attackData:new(	"Combo3",		.05, 		.2,				.1, 		10, 		7.75, 		.03,		5,				90			)
Combo[4] = 	attackData:new(	"Combo4",		.3, 		.25,			.5,			30,			10,			.15,		45,				150,		0, 			true,			true,		true)

--
-- Attack Event
--

script.Parent.OnServerEvent:Connect(function()
	
	if not canAttack then return end
	if tryCooldown then return end
	if cooldown then return end
	if isStunned then return end
	
	local Humanoid = Character.Humanoid

	-- this is placeholder, ideally there'd be a rising punch for jumping + downwards for falling
	local currentState = Humanoid:GetState()
	if currentState == Enum.HumanoidStateType.Jumping or currentState == Enum.HumanoidStateType.Freefall then return end
	
	tryCooldown = true
	local stunInterrupt = false
	
	comboIndex+=1 -- increments comboIndex
	
	spawn(function()
		while cooldown do
			wait()
			if isStunned then --[[print(Player.Name, "- Stunned mid-attack.")]] stunInterrupt = true end
		end
	end)

	spawn(function()
		wait(tryCooldownTime)
		tryCooldown = false
	end)
	
	local Attack = Combo[comboIndex]
	
	--print(Player.Name, "- Setting cooldown & movementOverride.")
	cooldown = true -- set cooldown; next move in combo cannot be performed until this is false
	highFriction:FireClient(Player, script.Name, true)
	if Attack.canSlide then movementOverride:FireClient(Player, script.Name, true, true)
	else					movementOverride:FireClient(Player, script.Name, true)
	end
	
	Anim = Humanoid:LoadAnimation(script.Anims[Attack.animName])
	
	if Attack.stunImmune then stunImmune.Value += 1 knockbackImmune.Value +=1 end
	
	local function resetAttackVars()
		--print(Player.Name, "- Resetting cooldown & movementOverride.")
		cooldown = false
		highFriction:FireClient(Player, script.Name, false)
		if Attack.canSlide then movementOverride:FireClient(Player, script.Name, false, false)
		else					movementOverride:FireClient(Player, script.Name, false)
		end
		if Attack.stunImmune then stunImmune.Value -= 1 knockbackImmune.Value -= 1 end
	end

	--[[
	local Anim = {}
	
	for i,v in pairs(Combo) do
		Anim[i] = Humanoid:LoadAnimation(script.Anims[v.animName])
	end
	--]]
	
	Anim:Play() -- play attack anim
	
	wait(Attack.windUp) -- waits windUp time before checking for enemy hit
	
	if stunInterrupt then --[[print(Player.Name, "- Escaped on line 203")]] resetAttackVars() return end -- cancel attack if stunned
	
	hitboxActive = true
	
	spawn(function()						--
		wait(Attack.hitboxTime)				-- Spawn Function
		if stunInterrupt then return end	-- 
		hitboxActive = false				-- Disables hitbox after set time.
	end)									--
	
	spawn(function()
		
		local enemiesHit = {}
		
		local currentCombo = comboIndex
		
		local realRange			-- Range can be increased by sliding during the move
		local realKnockback		-- Knockback can be increased by sliding during the move

		if isRollOverridden and Attack.canSlide then
			print("Applying slide bonus...")
			realRange = Attack.range + 8
			realKnockback = Attack.knockback + 30
		else
			realRange = Attack.range
			realKnockback = Attack.knockback
		end
		
		while hitboxActive and currentCombo == comboIndex do
			if stunInterrupt then --[[print("Escaping during hitbox check")]] break end
			for i,v in pairs(game.Workspace:GetChildren()) do
				local m = (v:IsA("Model") and v) or nil
				if m and m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m ~= Character then

					if (Character.HumanoidRootPart.Position - m.HumanoidRootPart.Position).magnitude <= realRange then

						local hitUUID = m.Humanoid:GetAttribute("UUID")
						local alreadyHit = false

						for n, e in ipairs(enemiesHit) do
							if e == hitUUID then
								alreadyHit = true
							end
						end

						if not alreadyHit then

							-- mafs
							--[[
							local vector = m.HumanoidRootPart.Position - Character.HumanoidRootPart.Position		-- get the vector between the player's pos & the enemy
							local lookVector = Character.HumanoidRootPart.CFrame.lookVector
							local dot = vector:Dot(lookVector)														-- get the dot product of vector and the player's facing angle
							local angle = ( dot / vector.magnitude ) / lookVector.magnitude							-- get the angle between these two vectors
								  angle = math.acos(angle)*100
							
							local cross = vector:Cross(lookVector)													-- get the cross product of these two vectors, in order to know exact facing angle
							local isClockwise = cross.Y > 0
							
							if not isClockwise then angle = 360 - angle end
							--]]
							
							-- new mafs
							local vector = m.HumanoidRootPart.Position - Character.HumanoidRootPart.Position							-- get the vector between the player's pos & the enemy
							local projectedVector = Character.HumanoidRootPart.CFrame:VectorToObjectSpace(vector) * Vector3.new(1,0,1)	-- get a "projected vector" perpendicular to the upvector of the cframe
							local angle = math.atan2(projectedVector.Z, projectedVector.X)												-- calculate the angle between these two vectors on that plane
								  angle = math.deg(angle)																				-- convert to degrees
							
							-- Convert to clockwise system
							if angle < -90 then angle = 360 + angle end -- tysm glen :)
							angle += 90
							
							-- Redirect angle based on dir
							local relativeAngle = angle + Attack.dir
							if relativeAngle > 360 then relativeAngle -= 360 end
							
							local arcMin = 360-(Attack.arc / 2)
							local arcMax = Attack.arc / 2

							if relativeAngle > arcMin or relativeAngle < arcMax then
								
								----[[
								local distance = (Character.HumanoidRootPart.Position - m.HumanoidRootPart.Position).Magnitude
								local hitboxVisual = Instance.new("Part")
								hitboxVisual.CanCollide = false
								hitboxVisual.Anchored = true
								hitboxVisual.BrickColor = BrickColor.new("Crimson")
								hitboxVisual.Transparency = .4
								hitboxVisual.Name = "Ray"
								hitboxVisual.Size = Vector3.new(0.1,0.1,Attack.range)
								hitboxVisual.CFrame = CFrame.lookAt(m.HumanoidRootPart.Position, Character.HumanoidRootPart.Position) * CFrame.new(0,0, ((-Attack.range/2) - (distance-Attack.range)) )
								hitboxVisual.Parent = workspace
								Debris:AddItem(hitboxVisual, Attack.hitboxTime)
								--]]
								
								local enemy = m:WaitForChild("DamageHandler",0.5)
								if not enemy then --[[print(Player.Name, "- Attempted combat with improper enemy.")]] continue end -- debug, should never actually happen in practice
								
								enemy.Damage.Value = Attack.dmg
								enemy.Knockback.Value = realKnockback
								enemy.KnockbackVector.Value = Character.HumanoidRootPart.CFrame.lookVector
								enemy.Stun.Value = Attack.stun -- Sets last, as is what triggers event
								
								table.insert(enemiesHit, hitUUID)

							end

						end

					end

				end
			end
			wait()
		end
		
	end)
	
	spawn(function()
		local oldIndex = comboIndex
		wait(comboWindow)
		if stunInterrupt then return end
		if comboIndex == oldIndex then comboIndex = 0 end
	end)
	
	if stunInterrupt then print(Player.Name, "- Exited at line 313") resetAttackVars() return end -- cancel attack if stunned
	if Attack.isFinal then comboIndex = 0 end -- reset combo
	
	wait(Attack.windDown)
	
	resetAttackVars()
	
end)
