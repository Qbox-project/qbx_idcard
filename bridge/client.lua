local bridge = {}

---@param text string
---@param kind? 'error'|'info'|'success'
function bridge.notify(text, kind)
    lib.notify({ title = locale('notify.title'), description = text, type = (kind == nil or kind == 'info') and 'inform' or kind })
end

---@param busy boolean
function bridge.setBusy(busy)
    LocalPlayer.state.invBusy = busy
end

return bridge
