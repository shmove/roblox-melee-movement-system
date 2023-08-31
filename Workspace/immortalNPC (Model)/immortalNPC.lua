-- immortalNPC (Script)

local Humanoid = script.parent.Humanoid
local HumanoidRootPart = script.parent.HumanoidRootPart

--
-- Health
--

local maxHealth = Humanoid.MaxHealth
local realHealth = maxHealth
local lastHealth = maxHealth

Humanoid.HealthChanged:Connect(function(health)
	
	if health == maxHealth then return end
	if health == lastHealth then return end
	
	realHealth += health - lastHealth
	lastHealth = health
	
	if realHealth > 31 then print("NPC has ", realHealth, "health.")
	else print("NPC has died!")
		realHealth = maxHealth
		Humanoid.Health = realHealth
		lastHealth = realHealth
		 print("NPC has ", realHealth, "health.")
	end
	
end)

--
-- Fight back (debug)
--

local debugFight = true

spawn(function()
	while true do
		wait(7)
		print("Attacking in 3...")
		wait(1)
		print("Attacking in 2...")
		wait(1)
		print("Attacking in 1...")
		wait(1)
		if not debugFight then return end
		for i,v in ipairs(workspace:GetChildren()) do
			local foundHumanoid = v:FindFirstChild("Humanoid")
			local foundHumanoidRootPart = v:FindFirstChild("HumanoidRootPart")
			if foundHumanoid and v.Name ~= script.Parent.Name then
				if (HumanoidRootPart.Position - foundHumanoidRootPart.Position).Magnitude < 20 and foundHumanoid.Health > 0 then

					local targetHandler = foundHumanoid.Parent:WaitForChild("DamageHandler")
					
					----[[
					targetHandler.Damage.Value = 15
					targetHandler.Knockback.Value = 8
					targetHandler.KnockbackVector.Value = HumanoidRootPart.CFrame.LookVector
					targetHandler.Stun.Value = .03
					
					wait(.15)
					
					targetHandler.Damage.Value = 15
					targetHandler.Knockback.Value = 8
					targetHandler.KnockbackVector.Value = HumanoidRootPart.CFrame.LookVector
					targetHandler.Stun.Value = .05
					
					wait(.15)
					
					targetHandler.Damage.Value = 10
					targetHandler.Knockback.Value = 5
					targetHandler.KnockbackVector.Value = HumanoidRootPart.CFrame.LookVector
					targetHandler.Stun.Value = .03
					
					wait(.15)
					--]]
					
					targetHandler.Damage.Value = 30
					targetHandler.Knockback.Value = 45
					targetHandler.KnockbackVector.Value = HumanoidRootPart.CFrame.LookVector
					targetHandler.Stun.Value = .15

				end
			end
		end
	end
end)