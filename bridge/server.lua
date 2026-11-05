local qbx = exports.qbx_core
local inventory = exports.ox_inventory

local bridge = {}

---@param src integer
---@param slot integer
---@return { name: string, metadata: table }?
function bridge.getSlot(src, slot)
    local item = inventory:GetSlot(src, slot)
    if item and item.name then return { name = item.name, metadata = item.metadata or {} } end

end

---@param src integer
---@param name string
---@param cardId? string
---@return integer?, table?
function bridge.findSlot(src, name, cardId)
    local slots = inventory:Search(src, 'slots', name) or {}
    local first

    for i = 1, #slots do
        local item = slots[i]
        local metadata = item.metadata or {}

        if cardId and metadata.cardId == cardId then return item.slot, metadata end

        first = first or item
    end

    if first then return first.slot, first.metadata or {} end

end

---@param src integer
---@param slot integer
---@param metadata table
---@return boolean
function bridge.setMetadata(src, slot, metadata)
    inventory:SetMetadata(src, slot, metadata)

    return true
end

---@param src integer
---@param name string
---@param metadata table
---@return boolean
function bridge.canCarry(src, name, metadata)
    return inventory:CanCarryItem(src, name, 1, metadata) == true
end

---@param src integer
---@param name string
---@param metadata table
---@return boolean
function bridge.addItem(src, name, metadata)
    return inventory:AddItem(src, name, 1, metadata) == true
end

---@param src integer
---@param text string
---@param kind? 'error'|'info'|'success'
function bridge.notify(src, text, kind)
    qbx:Notify(src, text, (kind == nil or kind == 'info') and 'inform' or kind)
end

---@param src integer
---@return boolean
function bridge.incapacitated(src)
    local state = Player(src).state

    return state.isDead == true or state.isCuffed == true or state.handcuffed == true
end

---@param names table<string, true>
---@param canUse fun(src: integer): boolean
---@param handler fun(src: integer, name: string, slot: integer, metadata: table)
function bridge.onUse(names, canUse, handler)
    for name in pairs(names) do
        qbx:CreateUseableItem(name, function(source, item)
            local slot = item and tonumber(item.slot)
            if not slot or not canUse(source) then return end

            local metadata = item.metadata or item.info or {}

            CreateThread(function()
                handler(source, name, slot, metadata)
            end)

        end)

    end

end

return bridge
