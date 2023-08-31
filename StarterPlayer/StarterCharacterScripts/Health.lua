-- Health (Script)

-- Gradually regenerates the Humanoid's Health over time.

local REGEN_RATE = 2/100	-- Regenerate this fraction of MaxHealth per second.
local REGEN_STEP = 0.5 		-- Wait this long between each regeneration step.
local REGEN_COOLDOWN = 5	-- Wait this long after taking damage to start regen

--------------------------------------------------------------------------------

local Character = script.Parent
local Humanoid = Character:WaitForChild('Humanoid')

--------------------------------------------------------------------------------

local cooldownTimer = 0
local lastHealth = Humanoid.Health

while true do
	wait(REGEN_STEP)
	
	if Humanoid.Health < Humanoid.MaxHealth and Humanoid.Health >= lastHealth then
		cooldownTimer+=REGEN_STEP
		if cooldownTimer>=REGEN_COOLDOWN then
			Humanoid.Health+=2
		end
	else
		cooldownTimer = 0
	end
	
	lastHealth = Humanoid.Health
end