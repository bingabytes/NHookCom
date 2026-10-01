-- n-hook com loader
-- paste this in delta, it grabs windui + the arsenal module

local BASE = "https://raw.githubusercontent.com/bingabytes/NHookCom/main/"

-- delta chokes on game:HttpGet sometimes so try request first
local function fetch(url)
    local fns = {}
    if type(request) == "function" then table.insert(fns, request) end
    if type(http_request) == "function" then table.insert(fns, http_request) end
    if syn and type(syn.request) == "function" then table.insert(fns, syn.request) end

    for _, fn in ipairs(fns) do
        local ok, res = pcall(fn, { Url = url, Method = "GET" })
        if ok and type(res) == "table" then
            local body = res.Body or res.body
            if type(body) == "string" and #body > 0 then
                return body
            end
        end
    end

    if type(game.HttpGet) == "function" then
        local ok, body = pcall(game.HttpGet, game, url)
        if ok and type(body) == "string" then return body end
    end

    return nil
end

local function loadModule(path)
    local src = fetch(BASE .. path)
    if not src then
        error("couldn't fetch " .. path)
    end

    local fn, err = loadstring(src, path)
    if not fn then
        error("syntax error in " .. path .. ": " .. tostring(err))
    end

    local ok, result = pcall(fn)
    if not ok then
        error("crash in " .. path .. ": " .. tostring(result))
    end

    return result
end

-- grab windui. try the pinned release first, raw dist as backup
local WindUI
do
    local urls = {
        "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua",
    }

    for _, url in ipairs(urls) do
        local src = fetch(url)
        -- make sure it's actually lua and not a github 404 page
        if src and #src > 100
            and not src:find("<!DOCTYPE", 1, true)
            and not src:find("<html", 1, true)
            and src:find("CreateWindow", 1, true) then

            local ok, lib = pcall(loadstring(src))
            if ok and type(lib) == "table" and type(lib.CreateWindow) == "function" then
                WindUI = lib
                print("windui loaded")
                break
            end
        end
    end

    if not WindUI then
        return warn("couldn't load windui from any source")
    end
end

-- which game are we in
local games = {
    [286090429] = "arsenal",
}

local folder = games[game.PlaceId]
if not folder then
    pcall(function()
        WindUI:Notify({
            Title = "N-Hook Com",
            Content = "PlaceId " .. game.PlaceId .. " isn't supported yet",
            Duration = 4,
        })
    end)
    return warn("unsupported place: " .. game.PlaceId)
end

print("game detected: " .. folder)

-- wire it all up
local core = loadModule("shared/core.lua")(WindUI)
local esp  = loadModule("shared/esp.lua")(core)
local mod  = loadModule("games/" .. folder .. "/init.lua")

mod.Run({
    WindUI = WindUI,
    Core   = core,
    ESP    = esp,
    Game   = folder,
})

print("loaded " .. folder)
