local vim = game:GetService("VirtualInputManager")
local chat_service = game:GetService("Chat")
local text_chat_service = game:GetService("TextChatService")
local teleport_service = game:GetService("TeleportService")
local gui_service = game:GetService("GuiService")

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

local whitelisted_seeds = {
    "Grape", 
    "Loquat",
    "Mushroom",
    "Pepper",
    "Cacao",
    "Feijoa",
    "Pitcher Plant",
    "Grand Volcania",
    "Sunflower",
    "Maple Apple",
    "Beanstalk",
    "Ember Lily",
    "Sugar Apple",
    "Burning Bud",
    "Giant Pinecone",
    "Elder Strawberry",  
    "Tranquil Bloom",
    "Bone Blossom", 
    "Elephant Ears",
    "Candy Blossom",
    "Lotus",
    "Venus Fly Trap",
    "Cursed Fruit",
    "Soul Fruit",
    "Dragon Pepper",
    "Rosy Delight",
    "Traveler's Fruit",
    "Grand Tomato",
    "Fossilight"
}

local all_gear = {
    "Watering Can",
    "Trowel",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Master Sprinkler",
    "Grandmaster Sprinkler"
}

-- Sell_Inventory = sells entire inventory
-- Water_RE = watering can, first param is position
-- Plant_RE = plants a seed, first parameter is the position, second is the seed
-- BuySeedStock = buys a seed 
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/fard22223/Grow-A-Garden-Bot/refs/heads/main/main.lua"))()

local shovel_prompt = game.Players.LocalPlayer.PlayerGui.ShovelPrompt
local current_placeid = game.PlaceId
local found_farm = nil
local do_main_loop = false
local quit = false 
local selling_inventory = false
local cleaning_plants = false
local last_cleaning_plants = tick()
local all_connections = {}
local last_water = tick()
local last_sell_inventory = tick()
local last_gear_buy = tick()
local last_shop_buy = tick()
local last_basic_sprinkler = tick()
local last_advanced_sprinkler = tick()
local last_master_sprinkler = tick()
local last_grandmaster_sprinkler = tick()
local current_tween = nil

local insert = function(connection)
    all_connections[#all_connections + 1] = connection
end

game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 25
for i, v in pairs(game.Workspace.Farm:GetChildren()) do
    if v.Important.Data.Owner.Value == game.Players.LocalPlayer.Name then
        found_farm = v
    end
end

-- to make it easier on the bot 
for i, v in pairs(game.Workspace.Farm:GetDescendants()) do
    if v:IsA("BasePart") then
        v.CanCollide = false
    end
end

insert(game.Workspace.Farm.DescendantAdded:Connect(function(dick)
    if dick:IsA("BasePart") then
        dick.CanCollide = false
    end
end))

local function mouse_click()
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
    local tool = get_tool(name)
    if not tool then return end

    mouse_click()
end

local function place_seed(pos, seed_name)
    if not get_tool(seed_name .. " Seed") then return end
    print(seed_name)
    game.ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seed_name)
end

local function buy_seed(seed)
    game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
end

local function buy_gear(gear)
    game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
end

local function click_on_part(part)
    local screen_pos, on_screen = workspace.CurrentCamera:WorldToScreenPoint(part.Position)
    vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, true, game, 1)  
    wait(0.01)
    vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, false, game, 1)  
end

local function click_on_ui(ui)
    for _, conn in pairs(getconnections(ui.MouseButton1Click)) do
        conn:Fire()
    end  
end


local function sell_inventory()
    if selling_inventory then return end
    if current_tween then
        current_tween:Cancel()
    end

    game.Players.LocalPlayer.Character.Humanoid:MoveTo(workspace.NPCS.Steven.HumanoidRootPart.Position)
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
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
                game.Players.LocalPlayer.Character.Humanoid:MoveTo((prompt.Parent.CFrame * CFrame.new(0, 1, 0)).Position)
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                game.Players.LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                for i, v in whitelisted_seeds do
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


local delete_non_whitlisted_plants = function()
    if cleaning_plants then return end
    cleaning_plants = true

    for i, v in pairs(found_farm.Important.Plants_Physical:GetChildren()) do
        if not whitelisted_seeds[v.Name] then
            get_tool("Shovel")
            pcall(function()
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, v.PrimaryPart.Position)
                click_on_part(v.PrimaryPart)
            end)
          
            wait(0.01)

            if whitelisted_seeds[shovel_prompt.ConfirmFrame.FruitName.Text] then
                click_on_ui(shovel_prompt.ConfirmFrame.Cancel)
                continue
            end 
            click_on_ui(shovel_prompt.ConfirmFrame.Confirm)
        end
    end

    cleaning_plants = false
end

local main_loop = function()
    if (tick() - last_shop_buy) > 25 then
        last_shop_buy = tick() 
        for i, v in all_seeds do
            buy_seed(v)
        end
    end
                    
    if (tick() - last_gear_buy) > 25 then
        last_gear_buy = tick() 
        for i, v in all_gear do
            buy_gear(v)
        end
    end

    if (tick() - last_cleaning_plants) > 5 then
        last_cleaning_plants = tick()
        delete_non_whitlisted_plants()
    end

    wait(0.1)
    open_seed_pack("Gourmet Seed Pack")
    pickup_all_fruits()

    if (tick() - last_sell_inventory) > 22 then
        last_sell_inventory = tick() 
        sell_inventory()
    end

    wait(0.3)
end


chat_service:Chat(game.Players.LocalPlayer.Character.Head, "chat commands: stopbotting, startbotting", Enum.ChatColor.Blue)
text_chat_service.OnIncomingMessage = function(message)
    if quit then return end
    if message.TextSource and message.TextSource.UserId == game.Players.LocalPlayer.UserId then
        if message.Text:lower() == "startbotting" then
            do_main_loop = true
            coroutine.wrap(function() 
                while do_main_loop do
                    main_loop()
                end
            end)()
        elseif message.Text:lower() == "stopbotting" then
            do_main_loop = false
        elseif message.Text:lower() == "deleteallbadplants" then
            delete_non_whitlisted_plants()
        end
    end
end