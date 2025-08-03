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

local all_gear = {
    "Watering Can",
    "Trowel",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Master Sprinkler",
    "Grandmaster Sprinkler"
}

local all_eggs = {
    "Common Egg",
    "Mythical Egg",
    "Paradise Egg",
    "Mythical Egg",
    "Bug Egg",
    "Rare Summer Egg",
    "Common Summer Egg"
}

local all_traveling_merchant_items = {
    "Cauliflower",
    "Rafflesia",
    "Green Apple",
    "Avocado",
    "Banana",
    "Pineapple",
    "Kiwi",
    "Bell Pepper",
    "Prickly Pear",
    "Loquat",
    "Feijoa",
    "Pitcher Plant",
    "Mutation Spray Wet",
    "Mutation Spray Windstruck",
    "Mutation Spray Verdant",
    "Night Staff",
    "Star Caller",
    "Mutation Spray Cloudtouched",
}

local whitelisted_seeds = {
    "Grape", 
    "Loquat",
    "Mushroom",
    "Pepper",
    "Cacao",
    "Feijoa",
    "Tomato",
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
    "Fossilight",
    "Taco Fern",
    "Sugarglaze",
    "Strawberry",
    "Coconut",
    "Mango",
    "Tomato",
    "Banana",
    "Corn",
    "Bamboo",
    "Apple",
    "Blueberry"
}

local COOKING_EVENT_PIG_CHEF = workspace.Interaction.UpdateItems.CookingEvent.CookingEventModel.PigChefFolder.PigChef
local CURRENT_CRAVING = COOKING_EVENT_PIG_CHEF.Cravings.CravingThoughtBubblePart.CravingBillboard.BG.CravingTextLabel

-- Sell_Inventory = sells entire inventory
-- Water_RE = watering can, first param is position
-- Plant_RE = plants a seed, first parameter is the position, second is the seed
-- BuySeedStock = buys a seed of your choice
-- BuyPetEgg = buys an egg of your choice
-- BuyTravelingMerchantShopStock = buys a fucking thing of your choice
-- BuyGearStock = buys a gear of your choice
-- SprinklerService has ocmmand like Create (requires sprinkler to be held) (2nd argument is cframe)
-- CookingPotService_RE has commands like: SubmitHeldPlant (requires player to be holding a selected fruit), CookBest (cooks all the shit)
-- SubmitFoodService_RE has commands like: SubmitHeldFood (gives the fatass pig the soup you cooked)
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/fard22223/Grow-A-Garden-Bot/refs/heads/main/main.lua"))()

local shovel_prompt = game.Players.LocalPlayer.PlayerGui.ShovelPrompt
local current_placeid = game.PlaceId
local found_farm = nil
local do_main_loop = true
local quit = false 
local selling_inventory = false
local cleaning_plants = false
local last_cleaning_plants = tick()
local all_connections = {}
local last_water = tick()
local last_sell_inventory = tick()
local last_traveling_merchant_buy = tick()
local last_gear_buy = tick()
local last_shop_buy = tick()
local last_egg_buy = tick()
local last_submit_food = tick()
local last_cook_food = tick()
local last_basic_sprinkler = tick()
local last_advanced_sprinkler = tick()
local last_godly_sprinkler = tick()
local last_master_sprinkler = tick()
local last_grandmaster_sprinkler = tick()

local insert = function(connection)
    all_connections[#all_connections + 1] = connection
end

-- incase i update the script while ingame. shuts this shit down
local current_version = 1
if workspace:GetAttribute("SCRIPT_COUNT") then
    workspace:SetAttribute("SCRIPT_COUNT", workspace:GetAttribute("SCRIPT_COUNT") + 1)
    current_version = workspace:GetAttribute("SCRIPT_COUNT")
else
    workspace:SetAttribute("SCRIPT_COUNT", current_version)
end

insert(workspace:GetAttributeChangedSignal("SCRIPT_COUNT"):Connect(function()
    if workspace:GetAttribute("SCRIPT_COUNT") ~= current_version then
        do_main_loop = false
        quit = true
        for i, v in all_connections do
            v:Disconnect()
            v = nil
        end
    end
end))

game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 75
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

local function get_tool(tool_name, is_seed)
    -- Check if already equipped
    for i, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") then
            if is_seed and string.find(v.Name, tool_name) or not is_seed and string.find(v.Name, tool_name) and v:GetAttribute("MaxAge") then
                return v  -- Return immediately!
            end
        end
    end

    -- Check backpack and equip
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and string.find(v.Name, tool_name) then
            if is_seed and string.find(v.Name, tool_name) or not is_seed and string.find(v.Name, tool_name) and v:GetAttribute("MaxAge") then
                game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                return v  -- Return immediately!
            end
        end
    end

    return nil  -- No tool found
end

local function get_amount_of_tool(tool_name, is_seed)
    local count = 0

    game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and is_seed and string.find(v.Name, tool_name) or v:IsA("Tool") and not is_seed and string.find(v.Name, tool_name) and v:GetAttribute("MaxAge") then
                count += 1
            end
    end

    return count
end

local function open_seed_pack(name)
    local tool = get_tool(name)
    if not tool then return end

    mouse_click()
end

local function place_seed(pos, seed_name)
    if not get_tool(seed_name .. " Seed", true) then return end
    game.ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seed_name)
end

local function buy_seed(seed)
    game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
end

local function buy_traveling_merchant_item(item)
    game.ReplicatedStorage.GameEvents.BuyTravelingMerchantShopStock:FireServer(item)
end

local function buy_gear(gear)
    game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
end

local function buy_egg(egg)
    game.ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(egg)
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

local remote = game.ReplicatedStorage.GameEvents.CookingPotService_RE

local function submit(tool, type_, count)
    local shit = get_tool(tool, false)
    if not shit then return end
    
    for i = 1, count do
        shit = get_tool(tool, false)
        if not shit then break end
        wait(0.1)
        remote:FireServer("SubmitHeldPlant")
        wait(0.1)
    end
end

local function cooked_event()
    local craving = CURRENT_CRAVING.Text
    if selling_inventory then return end
    selling_inventory = true

    local num = math.random(1, 4)
    if num < 4 then
        for i, v in whitelisted_seeds do
            submit(v, "Seed", 10)
        end
    elseif num == 4 then
        if string.find(craving, "Salad") then
                if get_amount_of_tool("Bone Blossom", "Seed") >= 4 and get_amount_of_tool("Tomato", "Seed") >= 1 then
                    submit("Bone Blossom", "Seed", 4)
                    submit("Tomato", "Seed", 1)
                elseif get_amount_of_tool("Sugar Apple", "Seed") >= 3 and get_amount_of_tool("Pepper", "Seed") >= 1 and get_amount_of_tool("Pineapple", "Seed") >= 1 then
                    submit("Sugar Apple", "Seed", 3)
                    submit("Pepper", "Seed", 1)
                    submit("Pineapple", "Seed", 1)
                elseif get_amount_of_tool("Giant Pinecone", "Seed") >= 1 and get_amount_of_tool("Tomato", "Seed") >= 1 then
                    submit("Giant Pinecone", "Seed", 1)
                    submit("Tomato", "Seed", 1)
                elseif get_amount_of_tool("Tomato", "Seed") >= 2 then
                    submit("Tomato", "Seed", 2)
                end
            elseif string.find(craving, "Sandwich") then
                if get_amount_of_tool("Tomato", "Seed") >= 2 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Tomato", "Seed", 2)
                    submit("Corn", "Seed", 1)
                end
            elseif string.find(craving, "Pie") then
                if get_amount_of_tool("Bone Blossom", "Seed") >= 4 and get_amount_of_tool("Pumpkin", "Seed") >= 1 then
                    submit("Bone Blossom", "Seed", 4)
                    submit("Pumpkin", "Seed", 1)
                elseif get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Coconut", "Seed") >= 3 and get_amount_of_tool("Mango", "Seed") >= 1 then
                    submit("Corn", "Seed", 1)
                    submit("Coconut", "Seed", 3)
                    submit("Mango", "Seed", 1)
                elseif get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Coconut", "Seed") >= 1 then
                    submit("Corn", "Seed", 1)
                    submit("Coconut", "Seed", 1)
                elseif get_amount_of_tool("Pumpkin", "Seed") >= 1 and get_amount_of_tool("Apple", "Seed") >= 1 then
                    submit("Pumpkin", "Seed", 1)
                    submit("Apple", "Seed", 1)
                end
            elseif string.find(craving, "Waffle") then
                if get_amount_of_tool("Sugar Apple", "Seed") >= 1 and get_amount_of_tool("Coconut", "Seed") >= 1 then
                    submit("Sugar Apple", "Seed", 1)
                    submit("Coconut", "Seed", 1)
                elseif (get_amount_of_tool("Tranquil Bloom", "Seed") >=1 and get_amount_of_tool("Starfruit", "Seed") >=1 and get_amount_of_tool("Coconut", "Seed")>=1)
                or (get_amount_of_tool("Pumpkin", "Seed") >=1 and get_amount_of_tool("Watermelon", "Seed") >=1)
                or (get_amount_of_tool("Pumpkin", "Seed") >=1 and get_amount_of_tool("Sugar Apple", "Seed") >=1) then
                    if get_amount_of_tool("Tranquil Bloom", "Seed")>=1 then
                        submit("Tranquil Bloom", "Seed",1)
                        submit("Starfruit", "Seed",1)
                        submit("Coconut", "Seed",1)
                    elseif get_amount_of_tool("Pumpkin", "Seed")>=1 then
                        submit("Pumpkin", "Seed",1)
                        if get_amount_of_tool("Watermelon","Seed")>=1 then
                            submit("Watermelon","Seed",1)
                        else
                            submit("Sugar Apple","Seed",1)
                        end
                    end
                end
            elseif string.find(craving, "Hot Dog") then
                if get_amount_of_tool("Bone Blossom", "Seed") >= 4 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Bone Blossom", "Seed", 4)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Ember Lily", "Seed") >= 4 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Ember Lily", "Seed", 4)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Ember Lily", "Seed") >= 1 then
                    submit("Corn", "Seed", 1)
                    submit("Ember Lily", "Seed", 1)
                elseif get_amount_of_tool("Pepper", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Pepper", "Seed", 1)
                    submit("Corn", "Seed", 1)
                end
            elseif string.find(craving, "Ice Cream") then
                if get_amount_of_tool("Banana", "Seed") >= 1 and get_amount_of_tool("Sugar Apple", "Seed") >= 1 and get_amount_of_tool("Bone Blossom", "Seed") >= 3 then
                    submit("Banana", "Seed", 1)
                    submit("Sugar Apple", "Seed", 1)
                    submit("Bone Blossom", "Seed", 3)
                elseif get_amount_of_tool("Banana", "Seed") >= 2 then
                    submit("Banana", "Seed", 2)
                elseif (get_amount_of_tool("Blueberry", "Seed") >= 1 or get_amount_of_tool("Strawberry", "Seed") >= 1)
                    and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Blueberry", "Seed", 1)
                    submit("Corn", "Seed", 1)
                end
            elseif string.find(craving, "Donut") then
                if get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Blueberry", "Seed") >= 1 and get_amount_of_tool("Strawberry", "Seed") >= 1 then
                    submit("Corn", "Seed", 1)
                    submit("Blueberry", "Seed", 1)
                    submit("Strawberry", "Seed", 1)
                elseif get_amount_of_tool("Strawberry", "Seed") >= 1 and get_amount_of_tool("Tomato", "Seed") >= 1 and get_amount_of_tool("Apple", "Seed") >= 1 then
                    submit("Strawberry", "Seed", 1)
                    submit("Tomato", "Seed", 1)
                    submit("Apple", "Seed", 1)
                elseif get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Watermelon", "Seed") >= 1 then
                    submit("Corn", "Seed", 1)
                    submit("Watermelon", "Seed", 1)
                end
            elseif string.find(craving, "Pizza") then
                if get_amount_of_tool("Sugar Apple", "Seed") >= 1 and get_amount_of_tool("Bone Blossom", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Sugar Apple", "Seed", 1)
                    submit("Bone Blossom", "Seed", 1)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Tomato", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 and get_amount_of_tool("Pepper", "Seed") >= 1 and get_amount_of_tool("Sugar Apple", "Seed") >= 2 then
                    submit("Tomato", "Seed", 1)
                    submit("Corn", "Seed", 1)
                    submit("Pepper", "Seed", 1)
                    submit("Sugar Apple", "Seed", 2)
                elseif get_amount_of_tool("Corn", "Seed") >= 2 and get_amount_of_tool("Apple", "Seed") >= 2 and get_amount_of_tool("Pepper", "Seed") >= 1 then
                    submit("Corn", "Seed", 2)
                    submit("Apple", "Seed", 2)
                    submit("Pepper", "Seed", 1)
                elseif get_amount_of_tool("Banana", "Seed") >= 1 and get_amount_of_tool("Tomato", "Seed") >= 1 then
                    submit("Banana", "Seed", 1)
                    submit("Tomato", "Seed", 1)
                end
            elseif string.find(craving, "Sushi") then
                if get_amount_of_tool("Bone Blossom", "Seed") >= 3 and get_amount_of_tool("Bamboo", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Bone Blossom", "Seed", 3)
                    submit("Bamboo", "Seed", 1)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Sugar Apple", "Seed") >= 3 and get_amount_of_tool("Bamboo", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Sugar Apple", "Seed", 3)
                    submit("Bamboo", "Seed", 1)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Pepper", "Seed") >= 1 and get_amount_of_tool("Coconut", "Seed") >= 1 and get_amount_of_tool("Bamboo", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Pepper", "Seed", 1)
                    submit("Coconut", "Seed", 1)
                    submit("Bamboo", "Seed", 1)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Bamboo", "Seed") >= 4 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Bamboo", "Seed", 4)
                    submit("Corn", "Seed", 1)
                end
            elseif string.find(craving, "Cake") then
                if get_amount_of_tool("Bone Blossom", "Seed") >= 3 and get_amount_of_tool("Sugar Apple", "Seed") >= 1 and get_amount_of_tool("Banana", "Seed") >= 1 then
                    submit("Bone Blossom", "Seed", 3)
                    submit("Sugar Apple", "Seed", 1)
                    submit("Banana", "Seed", 1)
                elseif get_amount_of_tool("Banana", "Seed") >= 1 and get_amount_of_tool("Kiwi", "Seed") >= 1 and get_amount_of_tool("Bone Blossom", "Seed") >= 3 then
                    submit("Banana", "Seed", 1)
                    submit("Kiwi", "Seed", 1)
                    submit("Bone Blossom", "Seed", 3)
                elseif get_amount_of_tool("Sugar Apple", "Seed") >= 4 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Sugar Apple", "Seed", 4)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Elder Strawberry", "Seed") >= 4 and get_amount_of_tool("Corn", "Seed") >= 1 then
                    submit("Elder Strawberry", "Seed", 4)
                    submit("Corn", "Seed", 1)
                elseif get_amount_of_tool("Sugar Apple", "Seed") >= 2 and get_amount_of_tool("Corn", "Seed") >= 2 then
                    submit("Sugar Apple", "Seed", 2)
                    submit("Corn", "Seed", 2)
                elseif (get_amount_of_tool("Kiwi", "Seed") >= 2 and get_amount_of_tool("Banana", "Seed") >= 2)
                or (get_amount_of_tool("Blueberry", "Seed") >= 1 and get_amount_of_tool("Grape", "Seed") >= 1 and get_amount_of_tool("Apple", "Seed") >= 1 and get_amount_of_tool("Corn", "Seed") >= 1) then
                    if get_amount_of_tool("Kiwi", "Seed")>=2 then
                        submit("Kiwi","Seed",2)
                        submit("Banana","Seed",2)
                    else
                        submit("Blueberry","Seed",1)
                        submit("Grape","Seed",1)
                        submit("Apple","Seed",1)
                        submit("Corn","Seed",1)
                    end
                end
            end
    end

    selling_inventory = false
    remote:FireServer("CookBest")
end

local function sell_inventory()
    if selling_inventory then return end
    selling_inventory = true
    game.Players.LocalPlayer.Character.Humanoid:MoveTo(workspace.NPCS.Steven.HumanoidRootPart.Position)
    game.Players.LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
    wait(0.1)
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

local function sprinkler(type, cframe)
    local sprinkler_item = get_tool(type)
    if not sprinkler_item then return end

    game.ReplicatedStorage.GameEvents.SprinklerService:FireServer("Create", cframe)
end

local picking_up = false
local function pickup_all_fruits()
    if picking_up or selling_inventory then return end
    picking_up = true

    for _, prompt in ipairs(found_farm.Important:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
            if quit then break end
            if math.random(1, 555) ~= 555 then continue end
            prompt.Enabled = true
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 100000000000

            if prompt.Parent then
                if selling_inventory or quit then break end

                local pos = prompt.Parent.Position
                pcall(function()
                    watering_can(pos)
                end)

                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
                game.Players.LocalPlayer.Character.Humanoid:MoveTo((prompt.Parent.CFrame * CFrame.new(0, 1, 0)).Position)
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                game.Players.LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                if math.random(1, 25) == 25 then
                    for i, v in whitelisted_seeds do
                        if selling_inventory or quit then break end
                        if math.random(1, 10) == 10 then
                            local seed = get_tool(v .. " Seed", true)
                            if seed then 
                                for j = 0, 2 do 
                                    if selling_inventory or quit then break end

                                    place_seed(game.Players.LocalPlayer.Character.Torso.Position, v)
                                    wait(0.1)
                                end
                            end
                        end
                    end
                end
        
                if (tick() - last_basic_sprinkler) > (5 * 60) and math.random(1, 3) == 3 then
                    last_basic_sprinkler = tick()
                    sprinkler("Basic Sprinkler", CFrame.new(pos))
                end

                if (tick() - last_advanced_sprinkler) > (5 * 60) and math.random(1, 3) == 3 then
                    last_advanced_sprinkler = tick()
                    sprinkler("Advanced Sprinkler", CFrame.new(pos))
                end

                if (tick() - last_godly_sprinkler) > (5 * 60) and math.random(1, 3) == 3 then
                    last_godly_sprinkler = tick()
                    sprinkler("Godly Sprinkler", CFrame.new(pos))
                end

                if (tick() - last_master_sprinkler) > (10 * 60) and math.random(1, 3) == 3 then
                    last_master_sprinkler = tick()
                    sprinkler("Master Sprinkler", CFrame.new(pos))
                end

                if (tick() - last_grandmaster_sprinkler) > (10 * 60) and math.random(1, 3) == 3 then
                    last_grandmaster_sprinkler = tick()
                    sprinkler("Grandmaster Sprinkler", CFrame.new(pos))
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
        if quit then break end

        if not whitelisted_seeds[v.Name] then
            get_tool("Shovel")
            pcall(function()
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, v.PrimaryPart.Position)
                click_on_part(v.PrimaryPart)
            end)
          
            wait(0.01)
            if quit then break end

            if whitelisted_seeds[shovel_prompt.ConfirmFrame.FruitName.Text] then
                click_on_ui(shovel_prompt.ConfirmFrame.Cancel)
                continue
            end 
            click_on_ui(shovel_prompt.ConfirmFrame.Confirm)
        end
    end

    cleaning_plants = false
end

local function submit_food()
    if selling_inventory then return end
    selling_inventory = true
    game.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("GetFoodFromPot")
    wait(2)
    local food = get_tool("Soup") or get_tool("Cake") or get_tool("Burger") or get_tool("Sushi") or get_tool("Pizza") or get_tool("Donut") or get_tool("Ice Cream") or get_tool("Hot Dog") or get_tool("Waffle") or get_tool("Pie") or get_tool("Sandwich") or get_tool("Salad")
    wait(1)
    game.ReplicatedStorage.GameEvents.SubmitFoodService_RE:FireServer("SubmitHeldFood")
    wait(0.25)

    selling_inventory = false
end

local main_loop = function()
    print((tick() - last_sell_inventory), " ", selling_inventory)
    if (tick() - last_sell_inventory) > 7 then
        last_sell_inventory = tick() 
        return
    end

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

    if (tick() - last_egg_buy) > 25 then
        last_shop_buy = tick() 
        for i, v in all_eggs do
            buy_egg(v)
        end
    end

    if (tick() - last_traveling_merchant_buy) > 25 then
        last_traveling_merchant_buy = tick()
        for i, v in all_traveling_merchant_items do
            buy_traveling_merchant_item(v)
        end
    end

    if (tick() - last_cleaning_plants) > 45 then
        last_cleaning_plants = tick()
        delete_non_whitlisted_plants()
        return
    end

    if (tick() - last_cook_food) > 3 then
        last_cook_food = tick()
        return
    end

            sell_inventory()
            cooked_event()
                    submit_food()


    if (tick() - last_submit_food) > 6 then
        last_submit_food = tick()
        return
    end

    open_seed_pack("Gourmet Seed Pack")

    if not selling_inventory then
        pickup_all_fruits()
        return
    end

    wait()
end

coroutine.wrap(function() 
    while do_main_loop do
        main_loop()
    end
end)()

chat_service:Chat(game.Players.LocalPlayer.Character.Head, "chat commands: stopbotting, startbotting, deleteallbadplants", Enum.ChatColor.Blue)
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