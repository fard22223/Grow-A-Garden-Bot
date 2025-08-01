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

local function buy_seed(seed)
    game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
end

local function submit_all_zen()
    game.ReplicatedStorage.GameEvents.ZenQuestRemoteEvent:FireServer("SubmitAllPlants")
end

local function sell_inventory()
    game.ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Workspace.NPCS.Steven.HumanoidRootPart.CFrame
end

local function pickup_all_fruits()
   for _, prompt in ipairs(game.Workspace.Farms:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
            if part then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame 
            end
            fireproximityprompt(prompt)
        end       
    end
end
 
while true do
    for i, v in all_seeds do
        buy_seed(v)
    end

    wait(0.05)
    submit_all_zen()
    wait(0.05)
    sell_inventory()
    wait(0.05)
end