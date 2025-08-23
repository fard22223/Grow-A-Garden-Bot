--// Services
local vim = game:GetService("VirtualInputManager")
local chat_service = game:GetService("Chat")
local text_chat_service = game:GetService("TextChatService")
local teleport_service = game:GetService("TeleportService")
local gui_service = game:GetService("GuiService")
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")

-- Wait for RobloxPromptGui to exist
repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")

-- Rejoin loop on generic ErrorPrompt
local lp = players.LocalPlayer
local po = game.CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
local ts = teleport_service

if po then
	po.ChildAdded:Connect(function(a)
		if a.Name == "ErrorPrompt" then
			while true do
				pcall(function()
					ts:Teleport(game.PlaceId)
				end)
				task.wait(2)
			end
		end
	end)
end

--// Config (removed cooking-related intervals)
local CONFIG = {
	WALK_SPEED = 75,
	SELL_INTERVAL = 7,
	SHOP_BUY_INTERVAL = 25,
	GEAR_BUY_INTERVAL = 25,
	EGG_BUY_INTERVAL = 25,
	MERCHANT_BUY_INTERVAL = 25,
	CLEANING_INTERVAL = 45,
	SPRINKLER_BASIC_INTERVAL = 300,
	SPRINKLER_ADVANCED_INTERVAL = 300,
	SPRINKLER_MASTER_INTERVAL = 600,
	WATER_COOLDOWN = 0.25,
	PICKUP_CHANCE = 25,
	PLANT_CHANCE = 50,
	SPRINKLER_CHANCE = 3,
}

--// Data tables (unchanged except cooking items removed where applicable)
local all_seeds = {
	"Carrot","Blueberry","Strawberry","Orange Tulip","Tomato","Corn","Daffodil",
	"Watermelon","Pumpkin","Apple","Bamboo","Coconut","Cactus","Dragon Fruit",
	"Mango","Grape","Pepper","Mushroom","Cacao","Beanstalk","Ember Lily",
	"Sugar Apple","Burning Bud","Giant Pinecone","Elder Strawberry"
}

local all_gear = {
	"Watering Can","Trowel","Basic Sprinkler","Advanced Sprinkler",
	"Master Sprinkler","Grandmaster Sprinkler"
}

local all_eggs = {
	"Common Egg","Mythical Egg","Paradise Egg","Bug Egg",
	"Rare Summer Egg","Common Summer Egg"
}

local all_traveling_merchant_items = {
	"Cauliflower","Rafflesia","Green Apple","Avocado","Banana","Pineapple",
	"Kiwi","Bell Pepper","Prickly Pear","Loquat","Feijoa","Pitcher Plant",
	"Mutation Spray Wet","Mutation Spray Windstruck","Mutation Spray Verdant",
	"Night Staff","Star Caller","Mutation Spray Cloudtouched"
}

local whitelisted_seeds = {
	["Grape"]=true,["Loquat"]=true,["Mushroom"]=true,["Pepper"]=true,
	["Cacao"]=true,["Feijoa"]=true,["Pitcher Plant"]=true,
	["Grand Volcania"]=true,["Sunflower"]=true,["Maple Apple"]=true,
	["Beanstalk"]=true,["Ember Lily"]=true,["Sugar Apple"]=true,
	["Burning Bud"]=true,["Giant Pinecone"]=true,["Elder Strawberry"]=true,
	["Tranquil Bloom"]=true,["Bone Blossom"]=true,["Elephant Ears"]=true,
	["Candy Blossom"]=true,["Lotus"]=true,["Venus Fly Trap"]=true,
	["Cursed Fruit"]=true,["Soul Fruit"]=true,["Dragon Pepper"]=true,
	["Rosy Delight"]=true,["Traveler's Fruit"]=true,["Grand Tomato"]=true,
	["Fossilight"]=true,["Taco Fern"]=true,["Sugarglaze"]=true,
}

--// State
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
		last_cleaning_plants = 0,
		sprinkler_timers = {
			basic = 0, advanced = 0, master = 0, grandmaster = 0
		}
	}
}

--// Utils
local function get_current_time() return tick() end
local function time_since(t) return get_current_time() - t end

local function add_connection(conn)
	if conn then table.insert(State.all_connections, conn) end
end

local function cleanup_connections()
	for _, c in ipairs(State.all_connections) do
		pcall(function() if c then c:Disconnect() end end)
	end
	State.all_connections = {}
end

-- Single-instance guard
local current_version = 1
local ws = workspace
if ws:GetAttribute("SCRIPT_COUNT") then
	ws:SetAttribute("SCRIPT_COUNT", ws:GetAttribute("SCRIPT_COUNT") + 1)
	current_version = ws:GetAttribute("SCRIPT_COUNT")
else
	ws:SetAttribute("SCRIPT_COUNT", current_version)
end

add_connection(ws:GetAttributeChangedSignal("SCRIPT_COUNT"):Connect(function()
	if ws:GetAttribute("SCRIPT_COUNT") ~= current_version then
		State.do_main_loop = false
		State.quit = true
		cleanup_connections()
	end
end))

-- Safer MoveTo that times out
local function safeMoveTo(hrpPos)
	local char = lp.Character
	if not (char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	hum:MoveTo(hrpPos)
	local finished = false
	local conn; conn = hum.MoveToFinished:Connect(function() finished = true; if conn then conn:Disconnect() end end)
	local t0 = time()
	while not finished and time() - t0 < 4 do task.wait(0.05) end
	return finished
end

--// Initialization
local function initialize()
	local player = lp
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = CONFIG.WALK_SPEED
	end

	-- Find player's farm
	local farms = ws:FindFirstChild("Farm")
	if farms then
		for _, farm in pairs(farms:GetChildren()) do
			local owner = farm:FindFirstChild("Important")
				and farm.Important:FindFirstChild("Data")
				and farm.Important.Data:FindFirstChild("Owner")
			if owner and owner.Value == player.Name then
				State.found_farm = farm
				break
			end
		end
	end

	-- Disable collisions in farm
	if farms then
		for _, part in pairs(farms:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
		add_connection(farms.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then d.CanCollide = false end
		end))
	end
end

-- Tool helpers
local function get_tool(namePart, is_seed)
	local player = lp
	local char = player.Character
	local function match(tool)
		if not tool:IsA("Tool") then return false end
		local name_match = string.find(tool.Name, namePart)
		if not name_match then return false end
		if is_seed then return true end
		-- Non-seed plant items tend to have MaxAge attribute
		return tool:GetAttribute("MaxAge") ~= nil or true
	end

	if char then
		for _, tool in pairs(char:GetChildren()) do
			if match(tool) then return tool end
		end
	end
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if match(tool) then
			if char and char:FindFirstChildOfClass("Humanoid") then
				pcall(function() char:FindFirstChildOfClass("Humanoid"):EquipTool(tool) end)
			end
			return tool
		end
	end
	return nil
end

local function mouse_click()
	local char = lp.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then pcall(function() tool:Activate() end) end
end

-- Actions
local function place_seed(pos, seed_name)
	if not get_tool(seed_name .. " Seed", true) then return false end
	return pcall(function()
		replicated.GameEvents.Plant_RE:FireServer(pos, seed_name)
	end)
end

local function buy_seed(seed)
	pcall(function() replicated.GameEvents.BuySeedStock:FireServer(seed) end)
end

local function buy_traveling_merchant_item(item)
	pcall(function() replicated.GameEvents.BuyTravelingMerchantShopStock:FireServer(item) end)
end

local function buy_gear(gear)
	pcall(function() replicated.GameEvents.BuyGearStock:FireServer(gear) end)
end

local function buy_egg(egg)
	pcall(function() replicated.GameEvents.BuyPetEgg:FireServer(egg) end)
end

local function click_on_part(part)
	if not (part and part.Position) then return false end
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local screen_pos, on_screen = cam:WorldToScreenPoint(part.Position)
	if not on_screen then return false end
	vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, true, game, 1)
	task.wait(0.01)
	vim:SendMouseButtonEvent(screen_pos.X, screen_pos.Y, 0, false, game, 1)
	return true
end

local function click_on_ui(ui)
	if not ui then return end
	local ok, conns = pcall(getconnections, ui.MouseButton1Click)
	if ok and conns then
		for _, c in pairs(conns) do pcall(function() c:Fire() end) end
	end
end

local function watering_can(pos)
	if time_since(State.timers.last_water) < CONFIG.WATER_COOLDOWN then return false end
	State.timers.last_water = get_current_time()
	if not get_tool("Watering Can", true) then return false end
	pcall(function()
		replicated.GameEvents.Water_RE:FireServer(pos + Vector3.new(0, -0.15, 0))
	end)
	return true
end

local function sprinkler(kind, cframe)
	if not get_tool(kind, true) then return false end
	pcall(function()
		replicated.GameEvents.SprinklerService:FireServer("Create", cframe)
	end)
	return true
end

-- CLEANUP / PICKUP
local function pickup_all_fruits()
	if State.picking_up or State.selling_inventory or not State.found_farm then return false end
	State.picking_up = true

	local prompts = {}
	local ok = pcall(function()
		prompts = State.found_farm.Important:GetDescendants()
	end)
	if not ok then State.picking_up = false; return false end

	for _, prompt in ipairs(prompts) do
		if State.quit or State.selling_inventory then break end
		if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
			if math.random(1, CONFIG.PICKUP_CHANCE) ~= CONFIG.PICKUP_CHANCE then
				continue
			end

			-- Make prompt easy to trigger
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 1e9

			local pos = prompt.Parent.Position
			local char = lp.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
				-- face & water
				local cam = workspace.CurrentCamera
				if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, pos) end
				watering_can(pos)

				-- move & press E
				safeMoveTo((prompt.Parent.CFrame * CFrame.new(0, 1, 0)).Position)
				vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
				task.wait(0.05)
				vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)

				-- opportunistic planting
				if math.random(1, CONFIG.PLANT_CHANCE) == CONFIG.PLANT_CHANCE then
					for seed_name in pairs(whitelisted_seeds) do
						if State.selling_inventory or State.quit then break end
						if get_tool(seed_name .. " Seed", true) then
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if hrp then place_seed(hrp.Position, seed_name) end
							task.wait(0.1)
							break
						end
					end
				end

				-- sprinklers (rate-limited + chance)
				local now = get_current_time()
				if time_since(State.timers.sprinkler_timers.basic) > CONFIG.SPRINKLER_BASIC_INTERVAL
					and math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
					State.timers.sprinkler_timers.basic = now
					sprinkler("Basic Sprinkler", CFrame.new(pos))
				end
				if time_since(State.timers.sprinkler_timers.advanced) > CONFIG.SPRINKLER_ADVANCED_INTERVAL
					and math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
					State.timers.sprinkler_timers.advanced = now
					sprinkler("Advanced Sprinkler", CFrame.new(pos))
				end
				if time_since(State.timers.sprinkler_timers.master) > CONFIG.SPRINKLER_MASTER_INTERVAL
					and math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
					State.timers.sprinkler_timers.master = now
					sprinkler("Master Sprinkler", CFrame.new(pos))
				end
				if time_since(State.timers.sprinkler_timers.grandmaster) > CONFIG.SPRINKLER_MASTER_INTERVAL
					and math.random(1, CONFIG.SPRINKLER_CHANCE) == CONFIG.SPRINKLER_CHANCE then
					State.timers.sprinkler_timers.grandmaster = now
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

	local shovel_prompt = lp:FindFirstChild("PlayerGui")
		and lp.PlayerGui:FindFirstChild("ShovelPrompt")

	local plants_folder = State.found_farm.Important:FindFirstChild("Plants_Physical")
	if not plants_folder then State.cleaning_plants = false; return false end

	for _, plant in pairs(plants_folder:GetChildren()) do
		if State.quit or math.random(1, 7) == 7 then break end
		if not whitelisted_seeds[plant.Name] then
			get_tool("Shovel", true)
			local primary = plant:FindFirstChild("PrimaryPart") or plant:FindFirstChildOfClass("BasePart")
			if not click_on_part(primary) then continue end
			task.wait(0.05)
			if State.quit then break end

			if shovel_prompt then
				local fname = shovel_prompt:FindFirstChild("ConfirmFrame")
					and shovel_prompt.ConfirmFrame:FindFirstChild("FruitName")
				if fname and whitelisted_seeds[fname.Text] then
					click_on_ui(shovel_prompt.ConfirmFrame:FindFirstChild("Cancel"))
				else
					click_on_ui(shovel_prompt and shovel_prompt.ConfirmFrame and shovel_prompt.ConfirmFrame:FindFirstChild("Confirm"))
				end
			end
		end
	end

	State.cleaning_plants = false
	return true
end

local function delete_all_plants()
	if State.cleaning_plants or not State.found_farm then return false end
	State.cleaning_plants = true

	local shovel_prompt = lp:FindFirstChild("PlayerGui")
		and lp.PlayerGui:FindFirstChild("ShovelPrompt")
	local plants_folder = State.found_farm.Important:FindFirstChild("Plants_Physical")
	if not plants_folder then State.cleaning_plants = false; return false end

	for _, plant in pairs(plants_folder:GetChildren()) do
		if State.quit then break end
		get_tool("Shovel", true)
		local base = plant:FindFirstChildOfClass("BasePart")
		if not click_on_part(base) then continue end
		task.wait(0.05)
		if State.quit then break end
		if shovel_prompt and shovel_prompt:FindFirstChild("ConfirmFrame") then
			click_on_ui(shovel_prompt.ConfirmFrame:FindFirstChild("Confirm"))
		end
	end

	State.cleaning_plants = false
	return true
end

-- Selling (removed cooking & food submission entirely)
local function sell_inventory()
	if State.selling_inventory then return false end
	State.selling_inventory = true

	local steven = workspace:FindFirstChild("NPCS")
		and workspace.NPCS:FindFirstChild("Steven")
		and workspace.NPCS.Steven:FindFirstChild("HumanoidRootPart")

	if steven then
		safeMoveTo(steven.Position)
		task.wait(0.1)
	end

	pcall(function()
		replicated.GameEvents.Sell_Inventory:FireServer()
	end)
	task.wait(0.2)

	State.selling_inventory = false
	return true
end

-- Main loop
local function main_loop()
	local now = get_current_time()

	if time_since(State.timers.last_shop_buy) > CONFIG.SHOP_BUY_INTERVAL then
		State.timers.last_shop_buy = now
		for _, seed in ipairs(all_seeds) do buy_seed(seed) end
	end

	if time_since(State.timers.last_gear_buy) > CONFIG.GEAR_BUY_INTERVAL then
		State.timers.last_gear_buy = now
		for _, gear in ipairs(all_gear) do buy_gear(gear) end
	end

	if time_since(State.timers.last_egg_buy) > CONFIG.EGG_BUY_INTERVAL then
		State.timers.last_egg_buy = now
		for _, egg in ipairs(all_eggs) do buy_egg(egg) end
	end

	if time_since(State.timers.last_traveling_merchant_buy) > CONFIG.MERCHANT_BUY_INTERVAL then
		State.timers.last_traveling_merchant_buy = now
		for _, item in ipairs(all_traveling_merchant_items) do buy_traveling_merchant_item(item) end
	end

	if time_since(State.timers.last_cleaning_plants) > CONFIG.CLEANING_INTERVAL then
		State.timers.last_cleaning_plants = now
		delete_non_whitelisted_plants()
	end

	-- Auto-open seed packs if held
	local gourmet_pack = get_tool("Gourmet Seed Pack")
	if gourmet_pack then mouse_click() end

	if not State.selling_inventory then
		pickup_all_fruits()
	end

	if time_since(State.timers.last_sell_inventory) > CONFIG.SELL_INTERVAL then
		State.timers.last_sell_inventory = now
		sell_inventory()
	end

	task.wait(0.1)
end

-- Boot
initialize()

coroutine.wrap(function()
	while State.do_main_loop do
		pcall(main_loop)
	end
end)()

-- Chat commands
chat_service:Chat(lp.Character and lp.Character:FindFirstChild("Head") or lp.Character, "chat commands: stopbotting, startbotting, deleteallbadplants, deleteallplants", Enum.ChatColor.Blue)

text_chat_service.OnIncomingMessage = function(message)
	if State.quit then return end
	if message.TextSource and message.TextSource.UserId == lp.UserId then
		local command = string.lower(message.Text or "")
		if command == "startbotting" then
			if not State.do_main_loop then
				State.do_main_loop = true
				coroutine.wrap(function()
					while State.do_main_loop do
						pcall(main_loop)
					end
				end)()
			end
		elseif command == "stopbotting" then
			State.do_main_loop = false
		elseif command == "deleteallbadplants" then
			delete_non_whitelisted_plants()
		elseif command == "deleteallplants" then
			delete_all_plants()
		end
	end
end
