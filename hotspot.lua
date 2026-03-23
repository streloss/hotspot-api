local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS          = game:GetService("ReplicatedStorage")

_G.Hotspot = {}

local VALID_KEYS = {
    "KEY-ABCD-1234",
    "KEY-EFGH-5678",
}

local _unlocked = false

function _G.Hotspot.unlock(key)
    for _, v in ipairs(VALID_KEYS) do
        if v == key then
            _unlocked = true
            print("[Hotspot] ✅ Авторизован!")
            return true
        end
    end
    warn("[Hotspot] ❌ Неверный ключ!")
    return false
end

local function checkAuth()
    if not _unlocked then
        warn("[Hotspot] ❌ Нет доступа! Сначала: _G.Hotspot.unlock('KEY')")
        return false
    end
    return true
end

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
                { name = "🎮 GameMode",  value = "`" .. gameMode .. "`", inline = true },
                { name = "🔑 Server ID", value = "`" .. serverId .. "`", inline = true },
            }
        end
    },
}

_G.Hotspot.Config = {
    WebhookURL   = "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN",
    KnownPlayers = {}
}

function _G.Hotspot.getGameInfo()
    local placeId  = game.PlaceId
    local gameData = _G.Hotspot.Games[placeId]
    if gameData then
        return gameData.name, gameData.emoji, gameData.getFields()
    end
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)
    return (ok and info or "Unknown Game"), "🎮", {}
end

function _G.Hotspot.send(target, customName)
    if not checkAuth() then return end

    local p = typeof(target) == "Instance" and target
        or Players:GetPlayerByUserId(target)
    if not p then return warn("[Hotspot] Игрок не найден") end

    local name                       = customName
        or _G.Hotspot.Config.KnownPlayers[p.UserId]
        or p.DisplayName
    local gameName, gameEmoji, extraFields = _G.Hotspot.getGameInfo()

    local fields = {
        { name = "👤 Игрок",  value = p.DisplayName .. " (@" .. p.Name .. ")", inline = true },
        { name = "🆔 UserID", value = tostring(p.UserId),                      inline = true },
        { name = "🌐 Job ID", value = "`" .. game.JobId:sub(1, 8) .. "`",      inline = false },
    }
    for _, field in ipairs(extraFields) do
        table.insert(fields, field)
    end

    local body = HttpService:JSONEncode({
        username = "Hotspot Tracker",
        embeds = {{
            title       = "📍 Хотспот | " .. name,
            description = gameEmoji .. " **" .. gameName .. "**",
            color       = 0x00CCFF,
            fields      = fields,
            thumbnail   = {
                url = "https://www.roblox.com/headshot-thumbnail/image?userId="
                    .. p.UserId .. "&width=420&height=420&format=png"
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

    print("[Hotspot] " .. name .. " | " .. gameName)
end

function _G.Hotspot.addPlayer(userId, name)
    if not checkAuth() then return end
    _G.Hotspot.Config.KnownPlayers[userId] = name
    print("[Hotspot] Добавлен: " .. name)
end

function _G.Hotspot.setWebhook(url)
    if not checkAuth() then return end
    _G.Hotspot.Config.WebhookURL = url
    print("[Hotspot] Вебхук обновлён")
end

function _G.Hotspot.addGame(placeId, name, emoji, getFieldsFn)
    if not checkAuth() then return end
    _G.Hotspot.Games[placeId] = { name = name, emoji = emoji, getFields = getFieldsFn }
    print("[Hotspot] Игра добавлена: " .. name)
end

function _G.Hotspot.startAuto()
    if not checkAuth() then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if _G.Hotspot.Config.KnownPlayers[p.UserId] then
            task.spawn(_G.Hotspot.send, p)
        end
    end

    Players.PlayerAdded:Connect(function(p)
        if _G.Hotspot.Config.KnownPlayers[p.UserId] then
            task.delay(2, _G.Hotspot.send, p)
        end
    end)

    print("[Hotspot] Авто-режим активен!")
end

print("[Hotspot] API v2.0 загружен!")
