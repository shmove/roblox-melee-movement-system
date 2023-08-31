-- UUID (Script)

local HttpService = game:GetService("HttpService")
local Humanoid = script.parent.Humanoid

--
-- Unique ID
--

local UUID = HttpService:GenerateGUID(false)
Humanoid:SetAttribute("UUID", UUID)