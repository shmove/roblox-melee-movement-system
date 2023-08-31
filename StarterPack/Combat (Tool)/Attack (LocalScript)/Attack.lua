-- Attack (LocalScript)
-- -- attackEvent (RemoteEvent)
-- -- -- Combat (Script)
-- -- -- -- Anims (Folder)
-- -- -- -- -- Combo1 (Animation)
-- -- -- -- -- Combo2 (Animation)
-- -- -- -- -- Combo3 (Animation)
-- -- -- -- -- Combo4 (Animation)
-- -- -- -- -- Idle (Animation)

local Tool = script.Parent
local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

--
-- Equipping
--

local equipped = false

Tool.Equipped:Connect(function(mouse)
	equipped = true
	--print("The combat tool was equipped: ", equipped)
end)

Tool.Unequipped:Connect(function(mouse)
	equipped = false
	--print("The combat tool was unequipped: ", equipped)
end)

--
-- Using
--

UIS.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if not equipped then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		script.attackEvent:FireServer()

	end
end)
