-- RemoteEvents (LocalScript)
-- -- attackOverride (RemoteEvent)
-- -- highFriction (RemoteEvent)
-- -- interruptRun (RemoteEvent)
-- -- movementOverride (RemoteEvent)

local Character = game.Players.LocalPlayer.Character

--
-- All Events
--

local interruptRun = Character.Run:WaitForChild("interruptRun")
local interruptRunRemote = Character.RemoteEvents:WaitForChild("interruptRun")

local highFriction = Character.Run:WaitForChild("highFriction")
local highFrictionRemote = Character.RemoteEvents:WaitForChild("highFriction")

local movementOverride = Character.Roll:WaitForChild("movementOverride")
local movementOverrideRemote = Character.RemoteEvents:WaitForChild("movementOverride")

local attackOverride = Character.Roll:WaitForChild("attackOverride")
local attackOverrideRemote = Character.RemoteEvents:WaitForChild("attackOverride")

--
-- Fire Bindable events when Remote events are fired
--

interruptRunRemote.onClientEvent:Connect(function(bool) interruptRun:Fire(bool) end)

highFrictionRemote.onClientEvent:Connect(function(originName, bool) highFriction:Fire(originName, bool) end)

movementOverrideRemote.onClientEvent:Connect(function(originName, bool, bool2) movementOverride:Fire(originName, bool, bool2) end)

attackOverrideRemote.onClientEvent:Connect(function(originName, bool) attackOverride:Fire(originName, bool) end)

--
-- Fire Remote events when Bindable events are fired
--

highFriction.Event:Connect(function(originName, bool) highFrictionRemote:FireServer(originName, bool) end)

movementOverride.Event:Connect(function(originName, bool, bool2) movementOverrideRemote:FireServer(originName, bool, bool2) end)

attackOverride.Event:Connect(function(originName, bool) attackOverrideRemote:FireServer(originName, bool) end)