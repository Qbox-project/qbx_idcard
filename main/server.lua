local sharedConfig = require 'config.shared'

local ox_inventory = exports.ox_inventory
local MAX_MUGSHOT_LENGTH = 512 * 1024

---@param mugShot any
---@return boolean
local function isValidMugShot(mugShot)
    return type(mugShot) == 'string'
        and #mugShot <= MAX_MUGSHOT_LENGTH
        and mugShot:find('^data:image/[%w.+-]+;base64,') ~= nil
end

---@param src number
---@param itemName string
local function newMetaDataLicense(src, itemName)
    local inventoryItems = ox_inventory:Search(src, 1, itemName)
    local _, inventoryItem = next(inventoryItems or {})
    if not inventoryItem then return end

    local mugShot = lib.callback.await('um-idcard:client:callBack:getMugShot', src)
    if not isValidMugShot(mugShot) then return end

    inventoryItem = ox_inventory:GetSlot(src, inventoryItem.slot)
    if not inventoryItem or inventoryItem.name ~= itemName then return end

    local metadata = inventoryItem.metadata or {}
    metadata.mugShot = mugShot
    ox_inventory:SetMetadata(src, inventoryItem.slot, metadata)
end

---@param src number
---@param target number
---@return boolean
local function isNearbyPlayer(src, target)
    if math.type(target) ~= 'integer' or target <= 0 or target == src or not GetPlayerName(target) then return false end

    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return false end

    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if playerPed <= 0 or targetPed <= 0 then return false end

    return #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) <= 3.0
end

---@param src number
---@param item string
---@param metadata table
local function sendData(src, item, metadata)
    if type(src) ~= 'number' or not GetPlayerName(src) then return end
    if type(item) ~= 'string' or not sharedConfig.licenses[item] then return end
    if type(metadata) ~= 'table' then return end

    if isValidMugShot(metadata.mugShot) then
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return end

        lib.callback('um-idcard:client:callBack:getClosestPlayer', src, function(target)
            if not GetPlayerName(src) then return end

            target = tonumber(target)
            if target and isNearbyPlayer(src, target) then
                TriggerClientEvent('um-idcard:client:notifyOx', src, {
                    title = 'You showed your idcard',
                    desc = 'You are showing your ID Card to the closest player',
                    icon = 'id-card',
                    iconColor = 'green'
                })
            else
                target = src
            end

            local charinfo = player.PlayerData.charinfo
            TriggerClientEvent('um-idcard:client:sendData', target, {
                citizenid = player.PlayerData.citizenid,
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                birthdate = charinfo.birthdate,
                sex = charinfo.gender == 0 and 'Male' or 'Female',
                nationality = charinfo.nationality,
                cardtype = item,
                mugShot = metadata.mugShot,
                badge = metadata.badge,
            })
        end)

        TriggerClientEvent('um-idcard:client:startAnim', src, item)
    else
        newMetaDataLicense(src, item)
    end
end

-- This event is intentionally server-only. It is called by the usable item
-- handler and must not accept arbitrary card data from clients.
AddEventHandler('um-idcard:server:sendData', sendData)

for k,_ in pairs(sharedConfig.licenses) do
    CreateRegisterItem(k)
end
