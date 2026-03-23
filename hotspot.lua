local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS          = game:GetService("ReplicatedStorage")

_G.Hotspot = {}

-- ключи доступа
local VALID_KEYS = {
    "tester",
}

local unlocked = false

function _G.Hotspot.unlock(key)
    for _, v in ipairs(VALID_KEYS) do
        if v == key then
            unlocked = true
            print("[Hotspot] Authorized!")
            return true
        end
    end
    warn("[Hotspot] Invalid key!")
    return false
end

local function checkAuth()
    if not unlocked then
        warn("[Hotspot] No access! Use: _G.Hotspot.unlock('KEY')")
        return false
    end
    return true
end

-- получаем реальный url аватарки через roblox api
local function getAvatarUrl(userId)
    local ok, res = pcall(function()
        return request({
            Url    = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
    end)

    if ok and res and res.Body then
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        if ok2 and data and data.data and data.data[1] then
            return data.data[1].imageUrl
        end
    end

    -- фолбек если апи не ответил
    return "https://www.roblox.com/bust-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
end

-- список поддерживаемых игр
_G.Hotspot.Games = {
    [4588604953] = {
        name  = "Criminality",
        emoji = "🔫",
        getFields = function()
            local gameMode = "Unknown"
            local serverId = "Unknown"
            pcall(function() gameMode = tostring(RS.Values.GameMode.Value) end)
            pcall(function() serverId = tostring(RS.Values.ServerId.Value) end)
            return {
                { name = "🎮 Game Mode", value = "`" .. gameMode .. "`", inline = true },
                { name = "🔑 Server ID", value = "`" .. serverId .. "`", inline = true },
            }
        end
    },
    -- добавляй новые игры так:
    -- [PLACE_ID] = {
    --     name  = "Game Name",
    --     emoji = "🎮",
    --     getFields = function()
    --         return {
    --             { name = "field", value = "value", inline = true }
    --         }
    --     end
    -- },
}

-- основной конфиг
_G.Hotspot.Config = {
    WebhookURL   = "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN",
    KnownPlayers = {
        -- [UserID] = "Name",
    }
}

-- определяем игру
local function getGameInfo()
    local data = _G.Hotspot.Games[game.PlaceId]
    if data then
        return data.name, data.getFields()
    end
    local ok, name = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return (ok and name or "Unknown Game"), {}
end

-- отправить вебхук
function _G.Hotspot.send(target, customName)
    if not checkAuth() then return end

    local p = typeof(target) == "Instance" and target
        or Players:GetPlayerByUserId(target)

    if not p then
        return warn("[Hotspot] Player not found")
    end

    local name = customName
        or _G.Hotspot.Config.KnownPlayers[p.UserId]
        or p.DisplayName

    local gameName, extraFields = getGameInfo()

    -- базовые поля
    local fields = {
        { name = "👤 Player",  value = p.DisplayName .. " (@" .. p.Name .. ")", inline = true },
        { name = "🆔 User ID", value = tostring(p.UserId),                      inline = true },
        { name = "🎮 Game",    value = gameName,                                 inline = false },
        { name = "🔑 Server ID",  value = "`" .. game.JobId:sub(1, 8) .. "`",      inline = false },
    }

    -- поля конкретной игры
    for _, field in ipairs(extraFields) do
        table.insert(fields, field)
    end

    local body = HttpService:JSONEncode({
        username = "Hotspot Tracker",
        embeds = {{
            title     = "hotspot — " .. name .. " joined!",
            color     = 0x00CCFF,
            fields    = fields,
            thumbnail = {
                url = getAvatarUrl(p.UserId)
            },
            footer = { text = os.date("!%Y-%m-%d %H:%M:%S UTC") }
        }}
    })

    request({
        Url     = _G.Hotspot.Config.WebhookURL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = body
    })

    print("[Hotspot] Sent: " .. name .. " | " .. gameName)
end

-- добавить игрока в список
function _G.Hotspot.addPlayer(userId, name)
    if not checkAuth() then return end
    _G.Hotspot.Config.KnownPlayers[userId] = name
    print("[Hotspot] Added: " .. name)
end

-- сменить вебхук
function _G.Hotspot.setWebhook(url)
    if not checkAuth() then return end
    _G.Hotspot.Config.WebhookURL = url
    print("[Hotspot] Webhook updated")
end

-- добавить игру в рантайме
function _G.Hotspot.addGame(placeId, name, emoji, getFieldsFn)
    if not checkAuth() then return end
    _G.Hotspot.Games[placeId] = { name = name, emoji = emoji, getFields = getFieldsFn }
    print("[Hotspot] Game added: " .. name)
end

-- авто режим
function _G.Hotspot.startAuto()
    if not checkAuth() then return end

    -- проверяем кто уже в сервере
    for _, p in ipairs(Players:GetPlayers()) do
        if _G.Hotspot.Config.KnownPlayers[p.UserId] then
            task.spawn(_G.Hotspot.send, p)
        end
    end

    -- следим за новыми
    Players.PlayerAdded:Connect(function(p)
        if _G.Hotspot.Config.KnownPlayers[p.UserId] then
            task.delay(2, _G.Hotspot.send, p)
        end
    end)

    print("[Hotspot] Auto mode active!")
end

print("[Hotspot] API v2.0 loaded!")
