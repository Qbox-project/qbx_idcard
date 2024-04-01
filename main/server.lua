local sharedConfig = require 'config.shared'

local ox_inventory = exports.ox_inventory

function NewMetaDataLicense(src, itemName)
    local newMetaDataItem = ox_inventory:Search(src, 1, itemName)
    for _, v in pairs(newMetaDataItem) do
        newMetaDataItem = v
        break
    end
    newMetaDataItem.metadata.mugShot = lib.callback.await('um-idcard:client:callBack:getMugShot', src)
    ox_inventory:SetMetadata(src, newMetaDataItem.slot, newMetaDataItem.metadata)
end

RegisterNetEvent('um-idcard:server:sendData', function(src,metadata)
    if metadata.mugShot ~= 'none' then
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
            TriggerClientEvent('um-idcard:client:sendData', src, metadata)
        end)
        TriggerClientEvent('um-idcard:client:startAnim', src, metadata.cardtype)
    else
        NewMetaDataLicense(src,metadata.cardtype)
    end
end)

for k,_ in pairs(sharedConfig.licenses) do
    CreateRegisterItem(k)
end