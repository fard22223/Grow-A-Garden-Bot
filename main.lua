local vim = game:GetService("VirtualInputManager")
local chat_service = game:GetService("Chat")
local text_chat_service = game:GetService("TextChatService")
local teleport_service = game:GetService("TeleportService")
local players = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")

repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")

local lp = players.LocalPlayer
local po = game.CoreGui.RobloxPromptGui.promptOverlay

-- Force rejoin loop on error prompts
po.ChildAdded:Connect(function(a)
	if a.Name == "ErrorPrompt" then
		while true do
			teleport_service:Teleport(game.PlaceId)
			task.wait(2)
		end
	end
end)

local CONFIG = {
	WALK_SPEED = 75,
	SELL_INTERVAL = 7,
	SHOP_BUY_INTERVAL = 25,
	GEAR_BUY_INTERVAL = 25,
	EGG_BUY_INTERVAL = 25,
	MERCHANT_BUY_INTERVAL = 25,
	CLEANING_INTERVAL = 45,
	WATER_COOLDOWN = 0.25,
}

local all_seeds = {"Carrot","Blueberry","Strawberry","Tomato"}
local all_gear = {"Watering Can","Trowel"}
local all_eggs = {"Common Egg","Mythical Egg"}
local all_traveling_merchant_items = {"Banana","Kiwi"}

local State = {
	found_farm = nil,
	do_main_loop = true,
	quit = false,
	timers = {
		last_water = 0,
		last_sell_inventory = 0,
		last_traveling_merchant_buy = 0,
		last_gear_buy = 0,
		last_shop_buy = 0,
		last_egg_buy = 0,
		last_cleaning_plants = 0,
	}
}

local function get_current_time() return tick() end
local function time_since(t) return get_current_time() - t end

-- Initialization (NO checks)
local function initialize()
	lp.Character.Humanoid.WalkSpeed = CONFIG.WALK_SPEED

	for _, farm in pairs(workspace.Farm:GetChildren()) do
		if farm.Important.Data.Owner.Value == lp.Name then
			State.found_farm = farm
			break
		end
	end

	for _, part in pairs(workspace.Farm:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	workspace.Farm.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end)
end

-- Buy functions (raw, no pcall)
local function buy_seed(seed)
	replicated.GameEvents.BuySeedStock:FireServer(seed)
end

local function buy_traveling_merchant_item(item)
	replicated.GameEvents.BuyTravelingMerchantShopStock:FireServer(item)
end

local function buy_gear(gear)
	replicated.GameEvents.BuyGearStock:FireServer(gear)
end

local function buy_egg(egg)
	replicated.GameEvents.BuyPetEgg:FireServer(egg)
end

local function sell_inventory()
	lp.Character.Humanoid:MoveTo(workspace.NPCS.Steven.HumanoidRootPart.Position)
	lp.Character.Humanoid.MoveToFinished:Wait()
	replicated.GameEvents.Sell_Inventory:FireServer()
end

-- Main loop (raw)
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

	if time_since(State.timers.last_sell_inventory) > CONFIG.SELL_INTERVAL then
		State.timers.last_sell_inventory = now
		sell_inventory()
	end

	task.wait(0.5)
end

initialize()

coroutine.wrap(function()
	while State.do_main_loop do
		main_loop()
	end
end)()

chat_service:Chat(lp.Character.Head, "chat commands: stopbotting, startbotting", Enum.ChatColor.Blue)

text_chat_service.OnIncomingMessage = function(message)
	if message.TextSource and message.TextSource.UserId == lp.UserId then
		local command = message.Text:lower()
		if command == "stopbotting" then
			State.do_main_loop = false
		elseif command == "startbotting" then
			State.do_main_loop = true
			coroutine.wrap(function()
				while State.do_main_loop do
					main_loop()
				end
			end)()
		end
	end
end
