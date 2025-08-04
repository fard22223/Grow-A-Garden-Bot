local vim = game:GetService("VirtualInputManager")
local chat_service = game:GetService("Chat")
local text_chat_service = game:GetService("TextChatService")
local teleport_service = game:GetService("TeleportService")
local gui_service = game:GetService("GuiService")
local run_service = game:GetService("RunService")

local CONFIG = {
    WALK_SPEED = 75,
    SELL_INTERVAL = 7,
    SHOP_BUY_INTERVAL = 25,
    GEAR_BUY_INTERVAL = 25,
    EGG_BUY_INTERVAL = 25,
    MERCHANT_BUY_INTERVAL = 25,
    CLEANING_INTERVAL = 45,
    COOK_INTERVAL = 3,
    SUBMIT_FOOD_INTERVAL = 6,
    SPRINKLER_BASIC_INTERVAL = 300,
    SPRINKLER_ADVANCED_INTERVAL = 300,
    SPRINKLER_MASTER_INTERVAL = 600,
    WATER_COOLDOWN = 0.25,
    PICKUP_CHANCE = 25,
    PLANT_CHANCE = 50,
    SPRINKLER_CHANCE = 3
}

local all_seeds = {
    "Carrot", "Blueberry", "Strawberry", "Orange Tulip", "Tomato", "Corn", "Daffodil",
    "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus", "Dragon Fruit",
    "Mango", "Grape", "Pepper", "Mushroom", "Cacao", "Beanstalk", "Ember Lily",
    "Sugar Apple", "Burning Bud", "Giant Pinecone", "Elder Strawberry"
}

local all_gear = {
    "Watering Can", "Trowel", "Basic Sprinkler", "Advanced Sprinkler",
    "Master Sprinkler", "Grandmaster Sprinkler"
}

local all_eggs = {
    "Common Egg", "Mythical Egg", "Paradise Egg", "Bug Egg",
    "Rare Summer Egg", "Common Summer Egg"
}

local all_traveling_merchant_items = {
    "Cauliflower", "Rafflesia", "Green Apple", "Avocado", "Banana", "Pineapple",
    "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant",
    "Mutation Spray Wet", "Mutation Spray Windstruck", "Mutation Spray Verdant",
    "Night Staff", "Star Caller", "Mutation Spray Cloudtouched"
}

local whitelisted_seeds = {
    ["Grape"] = true, ["Loquat"] = true, ["Mushroom"] = true, ["Pepper"] = true,
    ["Cacao"] = true, ["Feijoa"] = true, ["Tomato"] = true, ["Pitcher Plant"] = true,
    ["Grand Volcania"] = true, ["Sunflower"] = true, ["Maple Apple"] = true,
    ["Beanstalk"] = true, ["Ember Lily"] = true, ["Sugar Apple"] = true,
    ["Burning Bud"] = true, ["Giant Pinecone"] = true, ["Elder Strawberry"] = true,
    ["Tranquil Bloom"] = true, ["Bone Blossom"] = true, ["Elephant Ears"] = true,
    ["Candy Blossom"] = true, ["Lotus"] = true, ["Venus Fly Trap"] = true,
    ["Cursed Fruit"] = true, ["Soul Fruit"] = true, ["Dragon Pepper"] = true,
    ["Rosy Delight"] = true, ["Traveler's Fruit"] = true, ["Grand Tomato"] = true,
    ["Fossilight"] = true, ["Taco Fern"] = true, ["Sugarglaze"] = true,
    ["Strawberry"] = true, ["Coconut"] = true, ["Mango"] = true, ["Banana"] = true,
    ["Corn"] = true, ["Bamboo"] = true, ["Apple"] = true, ["Blueberry"] = true
}

local COOKING_EVENT_PIG_CHEF = workspace.Interaction.UpdateItems.CookingEvent.CookingEventModel.PigChefFolder.PigChef
local CURRENT_CRAVING = COOKING_EVENT_PIG_CHEF.Cravings.CravingThoughtBubblePart.CravingBillboard.BG.CravingTextLabel

local State = {
    found_farm = nil,
    do_main_loop = true,
    quit = false,
    selling_inventory = false,
    cleaning_plants = false,
    picking_up = false,
    all_connections = {},
    
    timers = {
        last_water = 0,
        last_sell_inventory = 0,
        last_traveling_merchant_buy = 0,
        last_gear_buy = 0,
        last_shop_buy = 0,
        last_egg_buy = 0,
        last_submit_food = 0,
        last_cook_food = 0,
        last_cleaning_plants = 0,
        sprinkler_timers = {
            basic = 0,
            advanced = 0,
            master = 0,
            grandmaster = 0
        }
    }
}

local function get_current_time()
    return tick()
end

local function time_since(last_time)
    return get_current_time() - last_time
end

local function add_connection(connection)
    State.all_connections[#State.all_connections + 1] = connection
end

local function cleanup_connections()
    for i, connection in ipairs(State.all_connections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.all_connections = {}
end

local current_version = 1
if workspace:GetAttribute("SCRIPT_COUNT") then
    workspace:SetAttribute("SCRIPT_COUNT", workspace:GetAttribute("SCRIPT_COUNT") + 1)
    current_version = workspace:GetAttribute("SCRIPT_COUNT")
else
    workspace:SetAttribute("SCRIPT_COUNT", current_version)
end

add_connection(workspace:GetAttributeChangedSignal("SCRIPT_COUNT"):Connect(function()
    if workspace:GetAttribute("SCRIPT_COUNT") ~= current_version then
        State.do_main_loop = false
        State.quit = true
        cleanup_connections()
    end
end))

local function initialize()
    local player = game.Players.LocalPlayer
    if player.Character and player.Character.Humanoid then
        player.Character.Humanoid.WalkSpeed = CONFIG.WALK_SPEED
    end
    
    for _, farm in pairs(game.Workspace.Farm:GetChildren()) do
        if farm:FindFirstChild("Important") and 
           farm.Important:FindFirstChild("Data") and
           farm.Important.Data:FindFirstChild("Owner") and
           farm.Important.Data.Owner.Value == player.Name then
            State.found_farm = farm
            break
        end
    end
    
    for _, part in pairs(game.Workspace.Farm:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    add_connection(game.Workspace.Farm.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end))
end

local function get_tool(tool_name, is_seed)
    local player = game.Players.LocalPlayer
    
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            local name_match = string.find(tool.Name, tool_name)
            if is_seed and name_match then
                return tool
            elseif not is_seed and name_match and tool:GetAttribute("MaxAge") then
                return tool
            end
        end
    end
    
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name_match = string.find(tool.Name, tool_name)
            if is_seed and name_match then
                player.Character.Humanoid:EquipTool(tool)
                return tool
            elseif not is_seed and name_match and tool:GetAttribute("MaxAge") then
                player.Character.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end
    
    return nil
end

local function get_amount_of_tool(tool_name, is_seed)
    local count = 0
    local player = game.Players.LocalPlayer
    
    player.Character.Humanoid:UnequipTools()
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name_match = string.find(tool.Name, tool_name)
            if is_seed and name_match then
                count = count + 1
            elseif not is_seed and name_match and tool:GetAttribute("MaxAge") then
                count = count + 1
            end
        end
    end
    
    return count
end

local function mouse_click()
    local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

local function place_seed(pos, seed_name)
    if not get_tool(seed_name .. " Seed", true) then return false end
    pcall(function()
        game.ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seed_name)
    end)
    return true
end

local function buy_seed(seed)
    pcall(function()
        game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
    end)
end

local function buy_traveling_merchant_item(item)
    pcall(function()
        game.ReplicatedStorage.GameEvents.BuyTravelingMerchantShopStock:FireServer(item)
    end)
end

local function buy_gear(gear)
    pcall(function()
        game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
    end)
end

local function buy_egg(egg)
    pcall(function()
        game.ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(egg)
    end)
end

local function click_on_part(part)
    if not part or not part.Position then return end
    local screen_pos, on_screen = workspace.CurrentCamera:WorldToScreenPoint(part.Position)
    if on_screen then
        vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, true, game, 1)
        wait(0.01)
        vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, false, game, 1)
    end
end

local function click_on_ui(ui)
    if not ui then return end
    for _, conn in pairs(getconnections(ui.MouseButton1Click)) do
        pcall(function()
            conn:Fire()
        end)
    end
end

local function watering_can(pos)
    if time_since(State.timers.last_water) < CONFIG.WATER_COOLDOWN then
        return false
    end
    
    State.timers.last_water = get_current_time()
    local tool = get_tool("Watering Can")
    if not tool then return false end
    
    pcall(function()
        game.ReplicatedStorage.GameEvents.Water_RE:FireServer(pos + Vector3.new(0, -0.15, 0))
    end)
    return true
end

local function sprinkler(type, cframe)
    local sprinkler_item = get_tool(type)
    if not sprinkler_item then return false end
    
    pcall(function()
        game.ReplicatedStorage.GameEvents.SprinklerService:FireServer("Create", cframe)
    end)
    return true
end

local function submit_plants_to_cooking()
    local remote = game.ReplicatedStorage.GameEvents.CookingPotService_RE
    local submitted = 0
    
    for seed_name in pairs(whitelisted_seeds) do
        local tool = get_tool(seed_name, false)
        if tool then
            for i = 1, 10 do
                tool = get_tool(seed_name, false)
                if not tool then break end
                
                wait(0.1)
                pcall(function()
                    remote:FireServer("SubmitHeldPlant")
                end)
                wait(0.1)
                submitted = submitted + 1
            end
        end
    end
    
    return submitted > 0
end

local function cook_and_submit_food()
    if State.selling_inventory then return false end
    State.selling_inventory = true
    
    submit_plants_to_cooking()
    
    pcall(function()
        game.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("CookBest")
    end)
    
    wait(2)
    
    pcall(function()
        game.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("GetFoodFromPot")
    end)
    
    wait(2)
    
    local food_types = {"Soup", "Cake", "Burger", "Sushi", "Pizza", "Donut", "Ice Cream", "Hot Dog", "Waffle", "Pie", "Sandwich", "Salad"}
    for _, food_type in ipairs(food_types) do
        if get_tool(food_type) then
            wait(1)
            pcall(function()
                game.ReplicatedStorage.GameEvents.SubmitFoodService_RE:FireServer("SubmitHeldFood")
            end)
            break
        end
    end
    
    State.selling_inventory = false
    return true
end

local function sell_inventory()
    if State.selling_inventory then return false end
    State.selling_inventory = true
    
    cook_and_submit_food()
    
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:MoveTo(workspace.NPCS.Steven.HumanoidRootPart.Position)
        player.Character.Humanoid.MoveToFinished:Wait()
        wait(0.1)
        
        pcall(function()
            game.ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
        end)
        wait(0.2)
    end
    
    State.selling_inventory = false
    return true
end

local function pickup_all_fruits()
    if State.picking_up or State.selling_inventory or not State.found_farm then 
        return false 
    end
    State.picking_up = true
    
    local prompts = State.found_farm.Important:GetDescendants()
    for _, prompt in ipairs(prompts) do
        if State.quit or State.selling_inventory then break end
        
        if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
            if math.random(1, CONFIG.PICKUP_CHANCE) ~= CONFIG.PICKUP_CHANCE then 
                continue 
            end
            
            prompt.Enabled = true
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 100000000000
            
            local pos = prompt.Parent.Position
            local player = game.Players.LocalPlayer
            
            watering_can(pos)
            
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
                player.Character.Humanoid:MoveTo((prompt.Parent.CFrame * CFrame.new(0, 1, 0)).Position)
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                player.Character.Humanoid.MoveToFinished:Wait()
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                
                if math.random(1, CONFIG.PLANT_CHANCE) == CONFIG.PLANT_CHANCE then
                    for seed_name in pairs(whitelisted_seeds) do
                        if State.selling_inventory or State.quit then break end
                        
                        if get_tool(seed_name .. " Seed", true) then
                            place_seed(player.Character.Torso.Position, seed_name)
                            wait(0.1)
                            break
                        end
                    end
                end
                
                local current_time = get_current_time()
                if time_since(State.timers.sprinkler_timers.basic) > CONFIG.SPRINKLER_BASIC_INTERVAL and 
                   math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
                    State.timers.sprinkler_timers.basic = current_time
                    sprinkler("Basic Sprinkler", CFrame.new(pos))
                end
                
                if time_since(State.timers.sprinkler_timers.advanced) > CONFIG.SPRINKLER_ADVANCED_INTERVAL and 
                   math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
                    State.timers.sprinkler_timers.advanced = current_time
                    sprinkler("Advanced Sprinkler", CFrame.new(pos))
                end
                
                if time_since(State.timers.sprinkler_timers.master) > CONFIG.SPRINKLER_MASTER_INTERVAL and 
                   math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
                    State.timers.sprinkler_timers.master = current_time
                    sprinkler("Master Sprinkler", CFrame.new(pos))
                end
                
                if time_since(State.timers.sprinkler_timers.grandmaster) > CONFIG.SPRINKLER_MASTER_INTERVAL and 
                   math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
                    State.timers.sprinkler_timers.grandmaster = current_time
                    sprinkler("Grandmaster Sprinkler", CFrame.new(pos))
                end
            end
        end
    end
    
    State.picking_up = false
    return true
end

local function delete_non_whitelisted_plants()
    if State.cleaning_plants or not State.found_farm then return false end
    State.cleaning_plants = true
    
    local shovel_prompt = game.Players.LocalPlayer.PlayerGui.ShovelPrompt
    
    for _, plant in pairs(State.found_farm.Important.Plants_Physical:GetChildren()) do
        if State.quit or math.random(1, 7) == 7 then break end
        
        if not whitelisted_seeds[plant.Name] then
            get_tool("Shovel")
            pcall(function()
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, plant.PrimaryPart.Position)
                click_on_part(plant.PrimaryPart)
            end)
            
            wait(0.01)
            if State.quit then break end
            
            if whitelisted_seeds[shovel_prompt.ConfirmFrame.FruitName.Text] then
                click_on_ui(shovel_prompt.ConfirmFrame.Cancel)
                continue
            end
            click_on_ui(shovel_prompt.ConfirmFrame.Confirm)
        end
    end
    
    State.cleaning_plants = false
    return true
end

local function delete_all_plants()
    if State.cleaning_plants or not State.found_farm then return false end
    State.cleaning_plants = true
    
    local shovel_prompt = game.Players.LocalPlayer.PlayerGui.ShovelPrompt
    
    for _, plant in pairs(State.found_farm.Important.Plants_Physical:GetChildren()) do
        if State.quit then break end
        
        get_tool("Shovel")
        pcall(function()
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, plant.PrimaryPart.Position)
            click_on_part(plant.PrimaryPart)
        end)
        
        wait(0.01)
        if State.quit then break end
        
        click_on_ui(shovel_prompt.ConfirmFrame.Confirm)
    end
    
    State.cleaning_plants = false
    return true
end

local function main_loop()
    local current_time = get_current_time()
    
    if time_since(State.timers.last_shop_buy) > CONFIG.SHOP_BUY_INTERVAL then
        State.timers.last_shop_buy = current_time
        for _, seed in ipairs(all_seeds) do
            buy_seed(seed)
        end
    end
    
    if time_since(State.timers.last_gear_buy) > CONFIG.GEAR_BUY_INTERVAL then
        State.timers.last_gear_buy = current_time
        for _, gear in ipairs(all_gear) do
            buy_gear(gear)
        end
    end
    
    if time_since(State.timers.last_egg_buy) > CONFIG.EGG_BUY_INTERVAL then
        State.timers.last_egg_buy = current_time
        for _, egg in ipairs(all_eggs) do
            buy_egg(egg)
        end
    end
    
    if time_since(State.timers.last_traveling_merchant_buy) > CONFIG.MERCHANT_BUY_INTERVAL then
        State.timers.last_traveling_merchant_buy = current_time
        for _, item in ipairs(all_traveling_merchant_items) do
            buy_traveling_merchant_item(item)
        end
    end
    
    if time_since(State.timers.last_cleaning_plants) > CONFIG.CLEANING_INTERVAL then
        State.timers.last_cleaning_plants = current_time
        delete_non_whitelisted_plants()
    end
    
    local gourmet_pack = get_tool("Gourmet Seed Pack")
    if gourmet_pack then
        mouse_click()
    end
    
    if not State.selling_inventory then
        pickup_all_fruits()
    end
    
    if time_since(State.timers.last_cook_food) > CONFIG.COOK_INTERVAL then
        State.timers.last_cook_food = current_time
        cook_and_submit_food()
    end
    
    if time_since(State.timers.last_sell_inventory) > CONFIG.SELL_INTERVAL then
        State.timers.last_sell_inventory = current_time
        sell_inventory()
    end
    
    wait(0.1)
end

initialize()

coroutine.wrap(function()
    while State.do_main_loop do
        pcall(main_loop)
    end
end)()

chat_service:Chat(game.Players.LocalPlayer.Character.Head, "chat commands: stopbotting, startbotting, deleteallbadplants, deleteallplants", Enum.ChatColor.Blue)

text_chat_service.OnIncomingMessage = function(message)
    if State.quit then return end
    if message.TextSource and message.TextSource.UserId == game.Players.LocalPlayer.UserId then
        local command = message.Text:lower()
        if command == "startbotting" then
            State.do_main_loop = true
            coroutine.wrap(function()
                while State.do_main_loop do
                    pcall(main_loop)
                end
            end)()
        elseif command == "stopbotting" then
            State.do_main_loop = false
        elseif command == "deleteallbadplants" then
            delete_non_whitelisted_plants()
        elseif command == "deleteallplants" then
            delete_all_plants()
        end
    end
end