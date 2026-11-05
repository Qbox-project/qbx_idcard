local config = require 'configs.server'
local bridge = require 'bridge.server'
local photos = require 'server.modules.photos'

local qbx = exports.qbx_core

local cards = {}

local YEAR <const> = 365 * 24 * 60 * 60
local PHOTO_EVENT <const> = ('%s:client:photo'):format(cache.resource)

---@type table<integer, true>
local locked = {}

---@param value any
---@param fallback string
---@return string
local function text(value, fallback)
    if type(value) ~= 'string' or value == '' then return fallback end

    return value:sub(1, 40)
end

---@param birthdate any
---@return string
local function formatBirthdate(birthdate)
    if type(birthdate) ~= 'string' then return '-' end

    local y, m, d = birthdate:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)')
    if y then return ('%02d/%02d/%s'):format(tonumber(m), tonumber(d), y) end

    return birthdate:sub(1, 10)
end

---@param prefix string
---@return string
local function newCardId(prefix)
    for _ = 1, 20 do
        local id = ('%s%07d'):format(prefix, math.random(0, 9999999))
        if not photos.cardExists(id) and not photos.oldCard(id) then return id end

    end

    return ('%s%s'):format(prefix, lib.string.random('11111111'))
end

---@param src integer
---@return string?
local function capturePhoto(src, source)
    local player = qbx:GetPlayer(src)
    local citizenid = player and player.PlayerData.citizenid
    if not citizenid then return end

    local ok, data = pcall(lib.callback.await, PHOTO_EVENT, src, source)
    player = qbx:GetPlayer(src)
    if ok and player and player.PlayerData.citizenid == citizenid and photos.inspect(data) then return data end

end

---@param src integer
---@param citizenid string
---@param retake? boolean
---@return integer?
local function currentPhoto(src, citizenid, retake)
    local photoId = not retake and photos.current(citizenid)
    if photoId then return photoId end

    local data = capturePhoto(src)
    photoId = data and photos.store(data)
    if photoId then photos.setCurrent(citizenid, photoId) end

    return photoId or photos.current(citizenid)
end

---@param src integer
---@param name string
---@return table?
function cards.legacyMetadata(src, name)
    local player = config.cards[name] and qbx:GetPlayer(src)
    if not player then return end

    local character = player.PlayerData.charinfo or {}

    return {
        cardtype = name,
        citizenid = player.PlayerData.citizenid,
        firstname = text(character.firstname, 'UNKNOWN'),
        lastname = text(character.lastname, 'UNKNOWN'),
        birthdate = type(character.birthdate) == 'string' and character.birthdate:sub(1, 10) or '-',
        sex = character.gender == 1 and 'F' or 'M',
        nationality = text(character.nationality, 'USA'),
        badge = 'none',
    }
end

---@param src integer
---@param name string
---@return table?
local function newMetadata(src, name)
    local card = config.cards[name]
    local metadata = cards.legacyMetadata(src, name)
    if not metadata then return end

    local issued = os.time()

    metadata.cardId = newCardId(card.prefix)
    metadata.issued = os.date('%m/%d/%Y', issued)
    metadata.expires = os.date('%m/%d/%Y', issued + card.years * YEAR)
    metadata.class = card.class
    metadata.dd = lib.string.random('AAAA1111'):upper()
    metadata.description = ('%s %s'):format(metadata.firstname, metadata.lastname)

    return metadata
end

---@param src integer
---@param name string
---@return boolean
local function issue(src, name)
    local metadata = newMetadata(src, name)
    if not metadata or not bridge.canCarry(src, name, metadata) then return false end

    metadata.photoId = currentPhoto(src, metadata.citizenid, config.photos.retakeOnIssue)
    local player = qbx:GetPlayer(src)
    if not player or player.PlayerData.citizenid ~= metadata.citizenid then return false end

    if not bridge.addItem(src, name, metadata) then return false end

    photos.link(metadata.cardId, metadata.citizenid, metadata.photoId)

    return true
end

---@param src integer
---@param name string
---@param slot integer
---@return boolean
local function blank(src, name, slot)
    local item = bridge.getSlot(src, slot)

    return item ~= nil and item.name == name and not item.metadata.cardId
end

---@param src integer
---@param name string
---@param slot integer
---@return table?
local function stamp(src, name, slot)
    if not blank(src, name, slot) then return end

    local metadata = newMetadata(src, name)
    if not metadata then return end

    local original = bridge.getSlot(src, slot).metadata
    for key, value in pairs(original) do metadata[key] = value end

    local player = qbx:GetPlayer(src)
    local ownsIdentity = player and metadata.citizenid == player.PlayerData.citizenid
    metadata.description = ('%s %s'):format(metadata.firstname, metadata.lastname)
    local holderCitizenid = player and player.PlayerData.citizenid
    local mugShot = original.mugShot
    local old = photos.legacy(mugShot)
    local converted = old and (photos.inspect(old) and old or capturePhoto(src, old))
    if mugShot and not old then return end

    metadata.photoId = converted and photos.store(converted)
    if not mugShot and ownsIdentity then metadata.photoId = currentPhoto(src, metadata.citizenid) end

    if metadata.photoId and ownsIdentity then photos.seedCurrent(metadata.citizenid, metadata.photoId) end

    player = qbx:GetPlayer(src)
    if not player or player.PlayerData.citizenid ~= holderCitizenid or not blank(src, name, slot)
        or bridge.getSlot(src, slot).metadata.citizenid ~= original.citizenid
        or bridge.getSlot(src, slot).metadata.mugShot ~= mugShot then return end

    local merged = bridge.getSlot(src, slot).metadata
    for key, value in pairs(metadata) do merged[key] = value end

    if not bridge.setMetadata(src, slot, merged) then return end

    if metadata.photoId or not mugShot then photos.link(metadata.cardId, metadata.citizenid, metadata.photoId) end

    return merged
end

---@param src integer
---@return boolean
function cards.isBusy(src)
    return locked[src] == true
end

---@param name string
---@return boolean
function cards.exists(name)
    return config.cards[name] ~= nil
end

---@param name string
---@return string
function cards.label(name)
    return config.cards[name].label
end

---@param src integer
---@param name string
---@return boolean
function cards.issue(src, name)
    if not photos.ready() or not config.cards[name] or locked[src] then return false end

    locked[src] = true
    local success, ok = pcall(issue, src, name)
    locked[src] = nil

    if not success then lib.print.error(ok) end

    return success and ok or false
end

---@param src integer
---@param name string
---@param slot integer
---@return table?
function cards.stamp(src, name, slot)
    if not photos.ready() or locked[src] then return end

    locked[src] = true
    local success, metadata = pcall(stamp, src, name, slot)
    locked[src] = nil

    if not success then lib.print.error(metadata) end

    return success and metadata or nil
end

---@param name string
---@param metadata table
---@return table
function cards.payload(name, metadata)
    local card = config.cards[name]
    local details = {}

    if card.class then details[#details + 1] = { label = 'CLASS', value = metadata.class or card.class } end

    details[#details + 1] = { label = 'ISSUED', value = metadata.issued }
    details[#details + 1] = { label = 'EXPIRES', value = metadata.expires }

    return {
        theme = card.theme,
        title = card.title,
        subtitle = card.subtitle,
        agency = card.agency,
        legal = card.legal,
        numberLabel = card.numberLabel,
        state = config.issuer.state,
        country = config.issuer.country,
        emblem = config.issuer.emblem,
        number = metadata.cardId,
        firstname = metadata.firstname,
        lastname = metadata.lastname,
        birthdate = formatBirthdate(metadata.birthdate),
        sex = metadata.sex,
        nationality = metadata.nationality,
        issued = metadata.issued,
        expires = metadata.expires,
        class = metadata.class,
        dd = metadata.dd,
        details = details,
    }
end

---@return table<string, true>
function cards.filter()
    local filter = {}

    for name in pairs(config.cards) do filter[name] = true end

    return filter
end

---@param src integer
function cards.drop(src)
    locked[src] = nil
end

---@param src integer
---@param metadata table
---@return integer?, string?
local function photoIdForCard(src, metadata)
    local photoId = photos.forCard(metadata.cardId)
    if photoId then return photoId end

    local old = photos.oldCard(metadata.cardId)
    local source = old and old.photo or metadata.mugShot
    if source then
        local original = photos.legacy(source)
        if not original then return end

        local data = photos.inspect(original) and original or capturePhoto(src, original)
        local ok
        if data then ok, photoId = pcall(photos.store, data) end

        if not ok or not photoId then return nil, original end

        if not photos.link(metadata.cardId, old and old.citizenid or metadata.citizenid, photoId) then return nil, original end

        if not pcall(photos.fill, metadata.cardId, photoId) then return nil, original end

        pcall(photos.seedCurrent, old and old.citizenid or metadata.citizenid, photoId)

        return (photos.forCard(metadata.cardId))
    end

    photoId = metadata.photoId
    if not photoId then
        local player = qbx:GetPlayer(src)
        if not player or player.PlayerData.citizenid ~= metadata.citizenid then return end

        photoId = currentPhoto(src, metadata.citizenid)
    end

    if not photoId or not photos.link(metadata.cardId, metadata.citizenid, photoId) then return end

    photos.fill(metadata.cardId, photoId)

    return (photos.forCard(metadata.cardId))
end

function cards.photoId(src, metadata)
    if not photos.ready() or locked[src] then return end

    locked[src] = true
    local ok, photoId, legacy = pcall(photoIdForCard, src, metadata)
    locked[src] = nil

    if not ok then lib.print.error(photoId) end

    if ok then return photoId, legacy end

    return nil, photos.legacy(metadata.mugShot)
end

function cards.retake(src)
    if not photos.ready() or locked[src] then return end

    local player = qbx:GetPlayer(src)
    if not player then return end

    locked[src] = true
    local ok, photoId = pcall(currentPhoto, src, player.PlayerData.citizenid, true)
    locked[src] = nil

    if not ok then lib.print.error(photoId) end

    return ok and photoId or nil
end

return cards
