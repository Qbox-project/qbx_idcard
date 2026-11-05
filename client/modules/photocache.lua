local config = require 'configs.client'

local photocache = {}

local PHOTO_EVENT <const> = ('%s:server:photo'):format(cache.resource)
local RETRY_MS <const> = 3000

---@type table<integer|string, string>
local entries = {}
---@type (integer|string)[]
local order = {}
---@type table<integer|string, promise>
local loading = {}
---@type table<integer|string, integer>
local failedAt = {}

---@param id integer|string
local function touch(id)
    for i = #order, 1, -1 do
        if order[i] == id then
            table.remove(order, i)

            break
        end

    end

    order[#order + 1] = id
end

---@param id integer|string
---@param photo string
local function remember(id, photo)
    entries[id] = photo
    touch(id)

    while #order > math.max(1, config.photoCache or 32) do
        entries[table.remove(order, 1)] = nil
    end

end

---@param id integer
---@return string?
function photocache.peek(id)
    return entries[id]
end

---@param token string
---@param id integer?
---@return string?
function photocache.get(token, id)
    local key = id or token
    local cached = entries[key]

    if cached then
        touch(key)

        return cached
    end

    local pending = loading[key]
    if pending then return Citizen.Await(pending) end

    if failedAt[key] and GetGameTimer() - failedAt[key] < RETRY_MS then return end

    pending = promise.new()
    loading[key] = pending

    local ok, result = pcall(lib.callback.await, PHOTO_EVENT, false, token, id)
    if loading[key] ~= pending then return end

    local photo = ok and type(result) == 'table' and result.ok and type(result.photo) == 'string' and result.photo or nil

    if photo then
        failedAt[key] = nil
        remember(key, photo)
    else
        failedAt[key] = GetGameTimer()
    end

    loading[key] = nil
    pending:resolve(photo)

    return photo
end

---@param token string
function photocache.forget(token)
    entries[token] = nil
    failedAt[token] = nil
    local pending = loading[token]
    loading[token] = nil
    if pending then pending:resolve(nil) end

    for i = #order, 1, -1 do
        if order[i] == token then table.remove(order, i) end

    end

end

function photocache.clear()
    entries = {}
    order = {}
    failedAt = {}
end

return photocache
