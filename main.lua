local vim = game:GetService("VirtualInputManager")
local chat_service = game:GetService("Chat")
local text_chat_service = game:GetService("TextChatService")
local all_seeds = {
    "Carrot",
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

local all_event_shop = {
    "Zen Seed Pack",
    "Raiju",
    "Pet Shard Corrupted",
    "Pet Shard Tranquil",
    "Spiked Mango",
    "Koi",
    "Zen Gnome Crate",
    "Soft Sunshine",
    "Sakura Bush",
    "Zen Crate",
    "Zenfalre",
    "Corrupt Radar",
    "Tranquil Radar",
    "Zen Sand",
    "Hot Spring",
    "Zen Egg",
}

local all_gear = {
    "Watering Can",
    "Trowel",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Master Sprinkler",
}

local all_zen_seeds = {
    "Serenity",
    "Monoblooma",
    "Taro Flower",
    "Zen Rocks",
    "Spiked Mango",
    "Hinomai",
    "Sakura Bush",
    "Soft Sunshine",
    "Zenfalre",
    "Maple Apple"
}

-- Sell_Inventory = sells entire inventory
-- Water_RE = watering can, first param is position
-- Plant_RE = plants a seed, first parameter is the position, second is the seed
-- BuySeedStock = buys a seed 
-- ZenQuestRemoteEvent = zen event, has a bunch of things including SubmitAllPlants

local found_farm = nil
local selling_inventory = false
local last_water = tick()
local last_sell_inventory = tick()
local last_gear_buy = tick()
local last_shop_buy = tick()
local current_tween = nil

game.Players.LocalPlayer.Character.Humanoid.WalkSpeed += 22

for i, v in pairs(game.Workspace.Farm:GetChildren()) do
    if v.Important.Data.Owner.Value == game.Players.LocalPlayer.Name then
        found_farm = v
    end
end

for i, v in pairs(game.Workspace.Farm:GetDescendants()) do
    if v:IsA("BasePart") then
        v.CanCollide = false
    end
end

game.Workspace.Farm.DescendantAdded:Connect(function(dick)
    if dick:IsA("BasePart") then
        dick.CanCollide = false
    end
end)

local function mouse_click(cf, value)
    if not cf or not value then return end

    local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

local function get_tool(tool_name)
    local tool = nil
    for i, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") and string.find(v.Name, tool_name) then
            tool = v
        end
    end

    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and string.find(v.Name, tool_name) then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
            tool = v
        end
    end

    return tool
end

local function open_seed_pack(name)
    local tool = get_tool("Zen Seed Pack")
    if not tool then return end

    mouse_click(CFrame.new(0, 0, 0), true)
end

local function place_seed(pos, seed_name)
    if not get_tool(seed_name .. " Seed") then return end
    print(seed_name)
    game.ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seed_name)
end

local function buy_seed(seed)
    game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
end

local function buy_event_stock(item)
    game.ReplicatedStorage.GameEvents.BuyEventShopStock:FireServer(item)
end

local function buy_gear(gear)
    game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
end

local function submit_all_zen()
    game.ReplicatedStorage.GameEvents.ZenQuestRemoteEvent:FireServer("SubmitAllPlants")
end

local function sell_inventory()
    if selling_inventory then return end
    if current_tween then
        current_tween:Cancel()
    end

    game.Players.LocalPlayer.Character.Humanoid:MoveTo(Workspace.NPCS.Steven.HumanoidRootPart.Position)
    game.Players.LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
    game.ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
    wait(0.2)
    selling_inventory = false
end

local function watering_can(pos)
    if (tick() - last_water) < 0.25 then
        return
    end

    last_water = tick()
    local tool = get_tool("Watering Can")
    if not tool then return end
    game.ReplicatedStorage.GameEvents.Water_RE:FireServer(pos + Vector3.new(0, -0.15, 0))
end

local picking_up = false
local function pickup_all_fruits()
    if picking_up then return end
    picking_up = true

    for _, prompt in ipairs(found_farm.Important:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
            prompt.Enabled = true
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 100000000000

            if prompt.Parent then
                if selling_inventory then continue end

                local pos = prompt.Parent.Position
                pcall(function()
                    watering_can(pos)
                end)
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, pos)
                game.Players.LocalPlayer.Character.Humanoid:MoveTo((prompt.Parent.CFrame * CFrame.new(0, 1, 0)).Position)
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                game.Players.LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                for i, v in all_zen_seeds do
                    local seed = get_tool(v .. " Seed")
                    if seed then 
                        for j = 0, seed:GetAttribute("Quantity") do 
                            place_seed(game.Players.LocalPlayer.Character.Torso.Position, v)
                            wait(0.1)
                        end
                    end
                end
            end
        end       
    end

    picking_up = false
end

chat_service:Chat(game.Players.LocalPlayer.Character.Head, "chat commands: plantallseeds, startbotting", Enum.ChatColor.Blue)
text_chat_service.OnIncomingMessage = function(message)
    if message.TextSource and message.TextSource.UserId == game.Players.LocalPlayer.UserId then
        if message.Text:lower() == "plantallseeds" then
            game.Players.LocalPlayer.Character.HumanoidRootPart.Anchored = true
            for i, v in all_zen_seeds do
                local seed = get_tool(v .. " Seed")
                if not seed then continue end
                
                for j = 0, seed:GetAttribute("Quantity") do 
                    place_seed(game.Players.LocalPlayer.Character.Torso.Position, v)
                    wait(0.01)
                end
            end

            for i, v in all_seeds do
                local seed = get_tool(v .. " Seed")
                if not seed then continue end
                
                for j = 0, seed:GetAttribute("Quantity") do 
                    place_seed(game.Players.LocalPlayer.Character.Torso.Position, v)
                    wait(0.01)
                end
            end

            game.Players.LocalPlayer.Character.HumanoidRootPart.Anchored = false
        elseif message.Text:lower() == "startbotting" then
            coroutine.wrap(function() 
                while true do
                    print("poo dick")
                    if (tick() - last_shop_buy) > 25 then
                        last_shop_buy = tick() 
                        for i, v in all_seeds do
                            buy_seed(v)
                        end

                        for i, v in all_event_shop do
                            buy_event_stock(v)
                        end
                    end
                    
                    if (tick() - last_gear_buy) > 25 then
                        last_gear_buy = tick() 
                        for i, v in all_gear do
                            buy_gear(v)
                        end
                    end

                    wait(0.1)
                    open_seed_pack("Zen Seed Pack")
                    pickup_all_fruits()

                    if (tick() - last_sell_inventory) > 4 then
                        submit_all_zen()
                    end

                    if (tick() - last_sell_inventory) > 22 then
                        submit_all_zen()
                        last_sell_inventory = tick() 
                        sell_inventory()
                    end

                    wait(0.3)
                end
            end)()
        end
    end
end