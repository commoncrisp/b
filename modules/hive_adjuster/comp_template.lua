-- This is the structure every comp follows
-- Use this as a reference when building comps in the GUI

local template = {
    name = "My Comp",           -- name of the comp
    hiveSize = 25,              -- how many slots this comp is for

    requirements = {
        -- ability based requirement
        {
            type = "token",         -- targeting a specific token
            value = "blue_bomb",    -- the token name from bee_abilities.lua
            count = 4,              -- how many bees with this token you want
            gifted = false          -- whether you need them gifted
        },
        -- specific bee requirement
        {
            type = "specific",      -- targeting a specific bee
            value = "Precise Bee",  -- the bee name
            count = 1,              -- how many you want
            gifted = true           -- whether you need it gifted
        },
    },

    keepList = {
        -- bees to keep if you happen to get them even if not in requirements
        {
            name = "Fuzzy Bee",
            stopIfGifted = true,    -- keep only if gifted
            maxCount = 1            -- max number of gifted to keep (only applies when stopIfGifted is true)
        },
        {
            name = "Gummy Bee",
            stopIfGifted = false,   -- always keep regardless of gifted
            maxCount = 2            -- max total to keep of this bee
        },
    },

    neverKeep = {
        -- bees to always RJ over, even if requirements are already satisfied
        -- these are checked first and override everything except... nothing, they override all
        {
            name = "Vicious Bee",
            giftedOnly = false      -- if true, only RJ non-gifted versions (keep gifted ones)
        },
        {
            name = "Windy Bee",
            giftedOnly = true       -- RJ non-gifted Windy Bees, but keep gifted ones
        },
    },

    eventBees = {
        -- bees to RJ over at the start if they exist in the hive
        -- behaves the same as neverKeep in the evaluator
        "Festive Bee",
        "Photon Bee",
    },

    globalStopIfGifted = false,     -- stop on ANY gifted bee
}

return template