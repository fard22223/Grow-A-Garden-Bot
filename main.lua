local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local game_events = replicated_storage:WaitForChild("GameEvents")
local farms = workspace.Farms

workspace:SetAttribute("BOT_LOADED", nil)
workspace:SetAttribute("BOT_LOADED", true)

local local_player = players.LocalPlayer
local local_farm = nil
local all_connections = {}
local all_seeds = {
    "Carrot",
    "Tomato",
    "Blueberry",
    "Strawberry",
    "Orange Tulip",
    "Tomato",
    "Corn",
    "Daffodil",
    "Watermelon",
    "Pumpkin",
    "Apple",
    "Bamboo",
    "Coconut",
    "Cactus",
    "Dragon Fruit",
    "Mango",
    "Grape",
    "Pepper",
    "Mushroom",
    "Cacao",
    "Beanstalk",
    "Ember Lily",
    "Sugar Apple",
    "Burning Bud",
    "Giant Pinecone",
    "Elder Strawberry",
}

for i, v in pairs(farms:GetChildren()) do  
    if v.Important.Data.Owner.Value == local_player.Name then
        local_farm = v
        break
    end
end

all_connections[#all_connections + 1] = workspace:GetAttributeChangedSignal("BOT_LOADED"):Connect(function()
    if not workspace:GetAttribute("BOT_LOADED") then
        for i, v in all_connections do
            pcall(function() v:Disconnect() end)
            pcall(function() task.cancel(v) end)
            pcall(function() v:Destroy() end)

            v = nil 
        end
    end
end)

local check = function()
    if local_player.Character and local_player.Character.Parent and local_player.Character:FindFirstChild("HumanoidRootPart") then
        return true
    end

    return false
end

local sell_inventory = function()
    if not check() then return end

    local_player.Character.HumanoidRootPart.CFrame = workspace.NPCS.Steven.HumanoidRootPart.CFrame
    all_connections[#all_connections + 1] = task.delay(0.05, function()
        game_events.Sell_Inventory:FireServer()
    end)
end

local buy_seed = function(seed, amount)
    if not check() then return end

    if amount then
        for i = 0, amount do
            game_events.BuySeedStock:FireServer(seed)
        end
    else
        game_events.BuySeedStock:FireServer(seed)
    end
end

all_connections[#all_connections + 1] = run_service.Heartbeat:Connect(function(dt)
    for i, v in all_seeds do
        buy_seed(v, 200)
    end
end)