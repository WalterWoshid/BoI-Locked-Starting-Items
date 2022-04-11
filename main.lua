local Mod = RegisterMod("Locked Starting Items", 1)
local json = require("json")

local checkItems = true

--------------------------------------------------------------------------------
------------------------------- Mod Config Menu --------------------------------
--------------------------------------------------------------------------------

Mod.Config = {
    EnabledForEden = true,
}

Mod.ModConfigMenuCategoryName = "Locked Items"

-- Callback: on start
function Mod:OnStart()
    -- Load mod data on start
    local config = json.decode(Mod:LoadData())
    if config then
        Mod.Config = config
    end
end

-- Add boolean function to mod menu
function Mod:AddBooleanSetting(
    subCategoryName, --[[string]]
    attribute,       --[[string (Mod.Config.*)]]
    settingText      --[[string]]
)
    ModConfigMenu.AddSetting(
        Mod.ModConfigMenuCategoryName,
        subCategoryName,
        {
            Attribute = attribute,
            Type = ModConfigMenu.OptionType.BOOLEAN,
            Default = Mod.Config[attribute],
            Display = function()
                local onOff = Mod.Config[attribute]

                if (onOff) then
                    onOff = "True"
                else
                    onOff = "False"
                end

                return settingText .. ": " .. onOff
            end,
            OnChange = function(value)
                Mod.Config[attribute] = value
                Isaac.SaveModData(Mod, json.encode(Mod.Config))
            end,
            CurrentSetting = function()
                return Mod.Config[attribute]
            end
        }
    )
end

-- Add settings to the mod menu
function Mod:SetupModConfigMenuSettings()
    if ModConfigMenu == nil then return end

    -- Enable for Eden
    Mod:AddBooleanSetting(
        nil,               -- Subcategory name
        "EnabledForEden",  -- Attribute
        "Enabled for Eden" -- Setting text
    )
end

Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Mod.OnStart)
Mod:SetupModConfigMenuSettings()

--------------------------------------------------------------------------------
----------------------------- Locked item - logic ------------------------------
--------------------------------------------------------------------------------

-- Broken items
local brokenItems = {
    "COLLECTIBLE_NULL",
    "COLLECTIBLE_BLACK_HOLE",
    "COLLECTIBLE_BLANK_CARD",
    "COLLECTIBLE_BLUE_BOX",
    "COLLECTIBLE_BOBS_ROTTEN_HEAD",
    "COLLECTIBLE_BOOMERANG",
    "COLLECTIBLE_BREATH_OF_LIFE",
    "COLLECTIBLE_BROKEN_GLASS_CANNON",
    "COLLECTIBLE_CANDLE",
    "COLLECTIBLE_CLEAR_RUNE",
    "COLLECTIBLE_CLICKER",
    "COLLECTIBLE_DIPLOPIA",
    "COLLECTIBLE_ERASER",
    "COLLECTIBLE_FORGET_ME_NOW",
    "COLLECTIBLE_FRIEND_BALL",
    "COLLECTIBLE_GLASS_CANNON",
    "COLLECTIBLE_MAMA_MEGA",
    "COLLECTIBLE_MOMS_BRACELET",
    "COLLECTIBLE_MYSTERY_GIFT",
    "COLLECTIBLE_PLACEBO",
    "COLLECTIBLE_PLAN_C",
    "COLLECTIBLE_RED_CANDLE",
    "COLLECTIBLE_SACRIFICIAL_ALTAR",
    "COLLECTIBLE_SHOOP_DA_WHOOP",
    "COLLECTIBLE_SPIN_TO_WIN",
    "COLLECTIBLE_THE_JAR",
    "COLLECTIBLE_BOOK_OF_VIRTUES",
}

-- Moves the active item as the pocket active
local function moveActiveToPocketActive()
    local player = Isaac.GetPlayer(0)
    local active = player:GetActiveItem()

    -- Check if active matches one of the broken items
    local isBrokenItem = false
    for i = 1, #brokenItems do
        if active == CollectibleType[brokenItems[i]] then
            isBrokenItem = true
        end
    end
    if isBrokenItem == false then
        player:RemoveCollectible(active)
        player:SetPocketActiveItem(active, ActiveSlot.SLOT_POCKET)
    end
end

-- Callback: on game start
function Mod:OnGameStart(isContinued)
    checkItems = true

    -- Don't execute if game is continued
    if isContinued then return end

    -- Check if the player is eden
    local player = Isaac.GetPlayer(0)
    if Mod.Config.EnabledForEden == false then
        local playerType = player:GetPlayerType()

        if playerType == PlayerType.PLAYER_EDEN or playerType == PlayerType.PLAYER_EDEN_B then
            return
        end
    end

    moveActiveToPocketActive()
end

if REPENTANCE then
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Mod.OnGameStart)
end

--------------------------------------------------------------------------------
-------------------------------- Birthright fix --------------------------------
--------------------------------------------------------------------------------

local gameRenderCount = 0

-- Removes the pocket active item
local function removePocketActiveItem()
    local player = Isaac.GetPlayer(0)
    local charge = player:GetActiveCharge(ActiveSlot.SLOT_POCKET)
    player:SetPocketActiveItem(CollectibleType.COLLECTIBLE_NULL, ActiveSlot.SLOT_POCKET)
    player:SetActiveCharge(charge)
end

function Mod:onRender()
    if checkItems == false then return end

    gameRenderCount = gameRenderCount + 1

    if gameRenderCount % 15 ~= 0 then return end

    -- Check if the player is judas
    local player = Isaac.GetPlayer(0)
    local playerType = player:GetPlayerType()
    if playerType == PlayerType.PLAYER_JUDAS then
        local pocketActive = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
        local playerHasBookOfBelialInPocket = pocketActive == CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL
        local playerHasBookOfBelial = player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, true)
        local playerHasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT, true)

        -- Check if the player has the book of belial in the pocket and birthrights
        if playerHasBookOfBelialInPocket and playerHasBirthright then
            removePocketActiveItem()
            checkItems = false
        elseif playerHasBookOfBelial and playerHasBirthright then
            checkItems = false
        end
    else
        checkItems = false
    end
end

if REPENTANCE then
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, Mod.onRender)
end

--------------------------------------------------------------------------------