local sharedConfig = require 'config.shared'

local ox_inventory = exports.ox_inventory

function NewMetaDataLicense(src, itemName)
    local newMetaDataItem = ox_inventory:Search(src, 1, itemName)
    for _, v in pairs(newMetaDataItem) do --luacheck: ignore
        newMetaDataItem = v
        break
    end
    newMetaDataItem.metadata.mugShot = lib.callback.await('um-idcard:client:callBack:getMugShot', src)
    ox_inventory:SetMetadata(src, newMetaDataItem.slot, newMetaDataItem.metadata)
end

RegisterNetEvent('um-idcard:server:sendData', function(src, item, metadata)
    if metadata.mugShot then
        local source = src

        lib.callback('um-idcard:client:callBack:getClosestPlayer', src, function(player)
            if player ~= 0 then
                TriggerClientEvent('um-idcard:client:notifyOx', src, {
                    title = 'You showed your idcard',
                    desc = 'You are showing your ID Card to the closest player',
                    icon = 'id-card',
                    iconColor = 'green'
                })

                src = player
            end

            local data = exports.qbx_core:GetPlayer(source).PlayerData.charinfo
            data.sex = data.gender == 0 and 'Male' or 'Female' -- Resolve gender being int
            data.cardtype = item or "id_card" -- Define card type default if not found
            data.mugShot = metadata.mugShot -- Append mugshot to data obj

            TriggerClientEvent('um-idcard:client:sendData', src, data)
        end)

        TriggerClientEvent('um-idcard:client:startAnim', src, item)
    else
        NewMetaDataLicense(src, item)
    end
end)

for k,_ in pairs(sharedConfig.licenses) do
    CreateRegisterItem(k)
end