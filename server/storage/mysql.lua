local provider = {}

---@param body string base64 image bytes
---@param mime string
---@param bytes integer
---@return integer?
function provider.put(body, mime, bytes)
    local id = MySQL.insert.await([[
        INSERT INTO `qbx_idcard_photo_store` (`hash`, `mime`, `bytes`, `data`)
        VALUES (UNHEX(SHA2(FROM_BASE64(?), 256)), ?, ?, FROM_BASE64(?))
        ON DUPLICATE KEY UPDATE `id` = LAST_INSERT_ID(`id`), `used_at` = CURRENT_TIMESTAMP
    ]], { body, mime, bytes, body })

    return tonumber(id)
end

---@param id integer
---@return string?, string?
function provider.get(id)
    local row = MySQL.single.await('SELECT `mime`, TO_BASE64(`data`) AS `data` FROM `qbx_idcard_photo_store` WHERE `id` = ?', { id })
    if not row or type(row.data) ~= 'string' then return end

    return (row.data:gsub('%s', '')), row.mime
end

---@param id integer
---@return boolean
function provider.exists(id)
    return MySQL.scalar.await('SELECT 1 FROM `qbx_idcard_photo_store` WHERE `id` = ?', { id }) ~= nil
end

---@param graceMinutes integer
---@param limit integer
---@return integer
function provider.collect(graceMinutes, limit)
    return MySQL.update.await([[
        DELETE FROM `qbx_idcard_photo_store`
        WHERE `used_at` < (CURRENT_TIMESTAMP - INTERVAL ? MINUTE)
          AND NOT EXISTS (SELECT 1 FROM `qbx_idcard_cards` c WHERE c.`photo_id` = `qbx_idcard_photo_store`.`id`)
          AND NOT EXISTS (SELECT 1 FROM `qbx_idcard_profiles` p WHERE p.`photo_id` = `qbx_idcard_photo_store`.`id`)
        LIMIT ?
    ]], { graceMinutes, limit }) or 0
end

-- The previous in-hand PR used this table; keep it untouched for lazy conversion.
local hasLegacy

function provider.oldCard(cardId)
    if hasLegacy == nil then
        hasLegacy = MySQL.scalar.await('SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { 'qbx_idcard_photos' }) ~= nil
    end

    if not hasLegacy then return end

    return MySQL.single.await('SELECT `citizenid`, `photo` FROM `qbx_idcard_photos` WHERE `card_id` = ?', { cardId })
end

return provider
