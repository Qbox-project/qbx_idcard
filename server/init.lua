local config = require 'configs.server'
local photos = require 'server.modules.photos'
local bridge = require 'bridge.server'
local cards = require 'server.modules.cards'
local shows = require 'server.modules.shows'

local resource = cache.resource

CreateThread(function()
    for statement in LoadResourceFile(resource, 'sql/schema.sql'):gmatch('[^;]+') do
        if statement:find('%S') then MySQL.query.await(statement) end

    end

    photos.initialize()

    local hours = (config.photos.cleanup or {}).intervalHours or 0
    if hours > 0 then
        SetInterval(function() photos.collect() end, hours * 3600000)
    end

end)

bridge.onUse(cards.filter(), shows.free, shows.use)

AddEventHandler('playerDropped', function()
    shows.drop(source)
    cards.drop(source)
end)

AddEventHandler('onResourceStop', function(name)
    if name == resource then shows.clear() end

end)
