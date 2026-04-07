local HttpService = game:GetService("HttpService")

local COMP_PREFIX = "bss_comp_"

-- fills in any missing fields added in newer versions so old comps dont break
local function applyDefaults(comp)
    comp.neverKeep = comp.neverKeep or {}
    comp.eventBees = comp.eventBees or {}
    for _, entry in ipairs(comp.keepList or {}) do
        if entry.maxCount == nil then
            entry.maxCount = nil -- nil = no cap, leave as-is
        end
    end
    return comp
end

local function saveComp(comp)
    local ok, err = pcall(function()
        writefile(COMP_PREFIX .. comp.name .. ".json", HttpService:JSONEncode(comp))
    end)
    if not ok then
        warn("Failed to save comp: " .. tostring(err))
        return false
    end
    return true
end

local function loadComp(name)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(COMP_PREFIX .. name .. ".json"))
    end)
    if ok and data then
        return applyDefaults(data)
    end
    return nil
end

local function deleteComp(name)
    local ok, err = pcall(function()
        delfile(COMP_PREFIX .. name .. ".json")
    end)
    return ok
end

local function listComps()
    local comps = {}
    local ok, files = pcall(listfiles, "")
    if not ok then return comps end
    for _, file in ipairs(files) do
        local name = file:match("bss_comp_(.+)%.json$")
        if name then
            table.insert(comps, name)
        end
    end
    return comps
end

local function exportComp(comp)
    local ok, str = pcall(function()
        return HttpService:JSONEncode(comp)
    end)
    if ok then return str end
    return nil
end

local function importComp(str)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    if ok and data and data.name then
        return applyDefaults(data)
    end
    return nil
end

return {
    save   = saveComp,
    load   = loadComp,
    delete = deleteComp,
    list   = listComps,
    export = exportComp,
    import = importComp,
}