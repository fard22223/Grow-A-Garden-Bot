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
end
 
while true do
    for i, v in all_seeds do
        buy_seed(v)
    end

    for _, prompt in ipairs(game.Farms:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            fireproximityprompt(prompt)
        end
    end

    submit_all_zen()
    wait(0.1)
    sell_inventory()
end