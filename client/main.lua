
local storages = require('data.storage')
local ox_target = exports.ox_target
local text = Config.useTarget and '[ALT/E] - Storage Menu' or '[E] - Storage Menu'
local currentStorage = nil
local ox_inventory = exports.ox_inventory

local function  createBlip(coords, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 473)
    SetBlipDisplay(blip, 6)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
end

local function storageMenu()
    if not currentStorage then return end
    local owned = lib.callback.await('sr_storage:server:hasStorage', false, currentStorage)
    local options = {}
    local data = storages[currentStorage]
    if not owned then
        options = {
            {
                title = ('Rent %s'):format(data.label),
                description = ('First Time Payment : $%s \n Daily Payment : $%s'):format(lib.math.groupdigits(data.payment), lib.math.groupdigits( data.daily)),
                onSelect = function ()
                    local input = lib.inputDialog('Set Password', {
                        { type = 'input', password = true, label = 'Pasword', placeholder = '' },
                    })
                    if not input then return end
                    local registered = lib.callback.await('sr_storage:server:registerStorage', false, currentStorage, input[1])
                end
            }
        }
    else
        options = {
            {
                title = ('Open %s'):format(data.label),
                description = 'Click here to open storage',
                onSelect = function ()
                    local input = lib.inputDialog('Password', {
                        { type = 'input', password = true, label = 'Pasword', placeholder = '' },
                    })
                    if not input then return end
                    if not input[1] == owned.password then
                        lib.notify('Wrong Password')
                        return
                    end
                    ox_inventory:openInventory('stash', currentStorage)
                end
            },
            {
                title = ('Stop Renting %s'):format(data.label),
                description = 'Click here to stop renting',
                onSelect = function ()
                    local alert = lib.alertDialog({
                    header = 'Stop Renting ?',
                    content = 'If You Stop Renting This Storage, Your Items Will Be Removed',
                    centered = true,
                    cancel = true
                    })

                    if alert == 'cancel' then
                        return
                    end

                    lib.callback.await('sr_storage:server:removeStorage', false, currentStorage)
                end
            }
        }
    end

    lib.registerContext({
        id = 'ctx_warehouse_menu',
        title = data.label,
        options = options
    })

    lib.showContext('ctx_warehouse_menu')
end

local keybind = lib.addKeybind({
    name = 'openstorage',
    description = 'Open Storage Menu',
    defaultKey = 'E',
    onPressed = function(self)
        storageMenu()
    end,
})

keybind:disable(true)

local onEnter = function (self)
    lib.showTextUI(text)
    keybind:disable(false)
    currentStorage = self.storage
end

local onExit = function ()
    lib.hideTextUI()
    keybind:disable(true)
    currentStorage = nil
end

CreateThread(function ()
    for k, v in pairs(storages) do
        if Config.useTarget then
            for i = 1, #v.zones do
                local data = v.zones[i]
                if data.blip then
                    createBlip(data.coords, v.label)
                end
                ox_target:addBoxZone({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    name = data.name or k..'_'..i,
                    storage = k,
                    onEnter = onEnter,
                    onExit = onExit,
                    options = {
                        {
                            label = 'Storage Menu',
                            icon = 'fas fa-warehouse',
                            onSelect = function ()
                                storageMenu(k)
                            end
                        }
                    }
                })
            end
        else
            for i = 1, #v.zones do
                local data = v.zones[i]
                if data.blip then
                    createBlip(data.coords, v.label)
                end
                lib.zones.box({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    storage = k,
                    name = data.name or k..'_'..i,
                    onEnter = onEnter,
                    onExit = onExit,
                })
            end
        end
    end
end)