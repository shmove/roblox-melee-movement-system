-- Stamina (Script)
-- -- removeStamina (RemoteFunction)
-- -- removeStaminaBindable (BindableFunction)

local Players = game:GetService("Players")

local staminaFunc = script:WaitForChild("removeStamina")
local staminaFuncBindable = script:WaitForChild("removeStaminaBindable")

--------------------------------------------------------------------------------

local Character = script.Parent
local Player = Players:GetPlayerFromCharacter(Character)
local Humanoid = Character:WaitForChild('Humanoid')

--------------------------------------------------------------------------------

--
-- General Stamina
--

-- Initialisation

local noStamina = false
local stamina
local maxStamina

if Player:FindFirstChild("Stamina") == nil then
	stamina = Instance.new("IntValue", Player)
	stamina.Name = "Stamina"
	stamina.Value = 100

	maxStamina = Instance.new("IntValue", Player)
	maxStamina.Name = "MaxStamina"
	maxStamina.Value = 100
else
	stamina = Player:WaitForChild("Stamina")
	maxStamina = Player:WaitForChild("MaxStamina")
end



-- Regen

spawn(function()
	while true do
		wait()
		
		local stamina = Player.Stamina
		local maxStamina = Player.MaxStamina
		
		if stamina.Value < maxStamina.Value then
			wait(0.5)
			stamina.Value += 2
			
		elseif stamina.Value > maxStamina.Value then
			stamina.Value = maxStamina.Value
		end
	end
end)

--
-- Death
--

Humanoid.Died:Connect(function()
	stamina.Value = maxStamina.Value
end)

--
-- Stamina Removal Function
--

-- local hasStamina = remoteFunction:InvokeServer(10)
-- [[ if server can take away this amount of stamina, return true and do so, else return false]]
-- print(hasStamina)
function removeStamina(player, num)
	if num < 0 then print("Nice try.") return true end
	if player.Stamina.Value >= num then
		player.Stamina.Value -= num
		return true, player.Stamina.Value
	else
		return false, player.Stamina.Value
	end
end

staminaFunc.OnServerInvoke = removeStamina

staminaFuncBindable.OnInvoke = removeStamina