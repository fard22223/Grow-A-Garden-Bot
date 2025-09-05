local teleport_service = game:GetService("TeleportService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local farms = workspace.Farm
local sell_npc = workspace.NPCS.Steven
local game_events = replicated_storage.GameEvents

local local_player = players.LocalPlayer
local prompt_overlay = game.CoreGui.RobloxPromptGui.promptOverlay
local sheckles = local_player.leaderstats.Sheckles

local all_bad_seeds = {
    ["Carrot"] = true,
    ["Blueberry"] = true,
    ["Strawberry"] = true,
    ["Orange Tulip"] = true,
    ["Tomato"] = true,
    ["Corn"] = true,
    ["Daffodil"] = true,
    ["Watermelon"] = true,
    ["Pumpkin"] = true,
    ["Apple"] = true,
    ["Bamboo"] = true,
    ["Coconut"] = true,
    ["Cactus"] = true,
    ["Dragon Fruit"] = true,
    ["Mango"] = true,
    ["Grape"] = true,
    ["Pepper"] = true,
    ["Mushroom"] = true,
    ["Cacao"] = true,
    ["Beanstalk"] = true,
    ["Ember Lily"] = true,
    ["Sugar Apple"] = true,
    ["Burning Bud"] = true,
    ["Giant Pinecone"] = true,
    ["Elder Strawberry"] = true,
    ["Romanesco"] = true,
}

local all_good_seeds = {
    ["Grape"] = true,
    ["Pepper"] = true,
    ["Mushroom"] = true,
    ["Cacao"] = true,
    ["Beanstalk"] = true,
    ["Ember Lily"] = true,
    ["Sugar Apple"] = true,
    ["Burning Bud"] = true,
    ["Giant Pinecone"] = true,
    ["Elder Strawberry"] = true,
    ["Romanesco"] = true,
}

local all_seeds = { "Carrot", "Blueberry", "Strawberry", "Orange Tulip", "Tomato", "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus", "Dragon Fruit", "Mango", "Grape", "Pepper", "Mushroom", "Cacao", "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone", "Elder Strawberry", "Romanesco"} 
local all_gear = { "Watering Can", "Trowel", "Basic Sprinkler", "Advanced Sprinkler", "Master Sprinkler", "Grandmaster Sprinkler", "Magnifying Glass"} 
local all_eggs = { "Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg"} 
local all_traveling_merchant_items = { "Paradise Egg", "Rare Summer Egg", "Common Summer Egg", "Cauliflower", "Rafflesia", "Green Apple", "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant", "Mutation Spray Wet", "Mutation Spray Windstruck", "Mutation Spray Verdant", "Night Staff", "Star Caller", "Mutation Spray Cloudtouched" }

local all_threads = {}
local do_loop = true

local get_players_farm = function(player)
	local all_farms = farms:GetChildren()
	local get_owner = function(current_farm)
		return current_farm.Important.Data.Owner.Value
	end

	for _, current_farm in all_farms do
		local current_owner = get_owner(current_farm)
		if current_owner == local_player.Name then
			return current_farm
		end
	end

    return nil
end

local farm = get_players_farm(local_player)
local current_state = {
    last_sell = tick(),
    last_water = tick(),
    last_trowel = tick(),
    last_harvest = tick(),
    last_plant = tick(),

    farm = farm,
    farm_important = farm and farm.Important,
    farm_plant_locations = farm_important and farm_important.Plant_Locations,
    farm_physical_plants = farm_important and farm_important.Plants_Physical,
}

local script_config = {
	sell_interval = 1,
	water_interval = 0.15,
}

local exit = function()
	for i, v in all_threads do
		pcall(function()
			task.cancel(v)
		end)

		pcall(function()
			v:Disconnect()
		end)
	end

	do_loop = false
end

local create_shit = function()
	local gui = Instance.new("ScreenGui")
	gui.Parent = local_player.PlayerGui
	gui.Name = "whoreslmao"

	local button = Instance.new("TextButton")
	button.Parent = gui
	button.Name = "whorebutton"
	button.Text = "STOP BOTTING"

	all_threads[#all_threads + 1] = button.MouseButton1Down:Connect(function()
		gui:Destroy()
		button:Destroy()
		exit()
	end)
end

local submit_fairy_fountain = function()
	game_events.FairyService.SubmitFairyFountainAllPlants:FireServer()
end

local plant_seed = function(pos, seed_name) 
	game_events.Plant_RE:FireServer(pos, seed_name) 
end

local normalize_seed_name = function(name)
	name = string.gsub(name, "%s*%[x%d+%]$", "")
	name = string.gsub(name, "%s*Seed$", "")
	return name
end

local plant_all_good_seeds = function()
	local_player.Character.Humanoid:UnequipTools()

	if sheckles.Value < 1000000000 then
		for i, v in pairs(local_player.Backpack:GetChildren()) do
			if v:IsA("Tool") and string.find(v.Name, "Seed") then
				if all_bad_seeds[normalize_seed_name(v.Name)] then
					v.Parent = local_player.Character
					local seedName = normalize_seed_name(v.Name)
					plant_seed(current_state.farm_plant_locations:FindFirstChildOfClass("Part"), seedName .. " Seed")
				end
			end
		end
	else
		for i, v in pairs(local_player.Backpack:GetChildren()) do
			if v:IsA("Tool") and string.find(v.Name, "Seed") then
				if all_good_seeds[normalize_seed_name(v.Name)] then
					v.Parent = local_player.Character
					local seedName = normalize_seed_name(v.Name)
					plant_seed(current_state.farm_plant_locations:FindFirstChildOfClass("Part"), seedName .. " Seed")
				end
			end
		end
	end
end

local buy_seed = function(seed)
	game_events.BuySeedStock:FireServer(seed)
end

local buy_merchant = function(item)
	game_events.BuyTravelingMerchantShopStock:FireServer(item)
end

local buy_gear = function(gear)
	game_events.BuyGearStock:FireServer(gear)
end

local buy_egg = function(egg)
	game_events.BuyPetEgg:FireServer(egg)
end

local sell_inventory = function()
	if (tick() - current_state.last_sell) < script_config.sell_interval then return end 
	current_state.last_sell = tick() 

	local old_position = local_player.Character.HumanoidRootPart.CFrame
	local_player.Character.HumanoidRootPart.CFrame = sell_npc.HumanoidRootPart.CFrame
	all_threads[#all_threads + 1] = task.delay(0.5, function() 
		game_events.Sell_Inventory:FireServer()
	end)

	all_threads[#all_threads + 1] = task.delay(2, function()
		local_player.Character.HumanoidRootPart.CFrame = old_position
	end)
end

local harvest_plants = function()
	for i, v in pairs(current_state.farm_physical_plants:GetDescendants()) do
		if v:IsA("ProximityPrompt") and v.Enabled then
			fireproximityprompt(v)
		end
	end
end

local main_loop = function()
	for _, seed in ipairs(all_seeds) do buy_seed(seed) end
	for _, gear in ipairs(all_gear) do buy_gear(gear) end
	for _, egg in ipairs(all_eggs) do buy_egg(egg) end
	for _, item in ipairs(all_traveling_merchant_items) do buy_merchant(item) end
	sell_inventory()
	submit_fairy_fountain()
	harvest_plants()
	plant_all_good_seeds()
	
	task.wait()
end

task.spawn(function()
	while do_loop do
		main_loop()
	end
end)

create_shit()
all_threads[#all_threads + 1] = prompt_overlay.ChildAdded:Connect(function(prompt)
	if prompt.Name == "ErrorPrompt" then
		while task.wait(1) do teleport_service:Teleport(game.PlaceId) end
	end
end)