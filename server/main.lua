local storages = require('data.storage')
local ox_inventory = exports.ox_inventory
local serverTime = os.time()
local playerStorages = {}

if not GetResourceState('ox_inventory') == 'started' then
    lib.print.error('ox_inventory not started')
    return
end

MySQL.query([[
    create table if not exists `storages`
    (
        identifier    varchar(255)   not null,
        playername    varchar(255)   not null,
        password    varchar(255)   not null,
        id    varchar(255)   not null
    );]], {}, function(result)
        if result and result.warningStatus == 0 then
           print('Created Tabel storages')
        end
    end)

local function diffDay(time)
    local timestamp = time
    local date = os.date('%d', timestamp)
    local currentTime = os.date('%d', serverTime)
    return currentTime > date and currentTime - date or 0
end

CreateThread(function ()
    local data = MySQL.query.await('SELECT * FROM storages')
    for k, v in pairs(storages) do
        ox_inventory:RegisterStash(k, v.label, v.slots, v.weight * 1000, true)
        if not playerStorages[k] then
            playerStorages[k] = {}
        end
        for a, b in pairs(data) do
            playerStorages[k][b.identifier] = {
                password = b.password
            }
        end
    end
end)

lib.callback.register('sr_storage:server:hasStorage', function(src, id)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not storages[id] then lib.print.error(('storage with id : %s doesn\'nt exist'):format(id)) return end
    return playerStorages[id][xPlayer.identifier]
end)

lib.callback.register('sr_storage:server:registerStorage', function (src, id, password)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not storages[id] then lib.print.error(('storage with id : %s doesn\'nt exist'):format(id)) return end
    local money = xPlayer.getAccount('bank').money
    if money < storages[id].payment then
        lib.notify(src, {
            title = 'Storage',
            description = 'Not enough money',
            type = 'error',
            duration = 5000,
        })
        return
    end

    if playerStorages[id][xPlayer.identifier] then
        lib.notify(src, {
            title = 'Storage',
            description = 'Already Registered',
            type = 'error',
            duration = 5000,
        })
        return
    end
    lib.notify(src, {
        title = 'Storage',
        description = 'Successfully registering storage',
        type = 'success',
        duration = 5000,
    })
    xPlayer.removeAccountMoney('bank', storages[id].payment)
    playerStorages[id][xPlayer.identifier] = {
        password = password
    }
    MySQL.insert.await('INSERT INTO `storages` (identifier, playername, id, password) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, xPlayer.name, id, password
    })
    return true
end)

lib.callback.register('sr_storage:server:removeStorage', function(src, id)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not storages[id] then lib.print.error(('storage with id : %s doesn\'nt exist'):format(id)) return end
    if playerStorages[id][xPlayer.identifier] then
        playerStorages[id][xPlayer.identifier] = nil
    end
    ox_inventory:ClearInventory({id = id, owner = xPlayer.identifier})
    MySQL.query.await('DELETE FROM storages WHERE identifier = ? and id = ?', {
        xPlayer.identifier, id
    })
end)

AddEventHandler('esx:playerDropped', function (playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    xPlayer.setMeta('lastlogin', os.time())
end)

AddEventHandler('esx:playerLoaded', function (playerId, xPlayer, isNew)
    if isNew then return end
    local lastlogin = xPlayer.getMeta('lastlogin')
    if lastlogin then
        local diff = diffDay(lastlogin)
        if diff < 0 then
            return
        end
        for k, v in pairs(storages) do
            local money = xPlayer.getAccount('bank').money
            if playerStorages[k][xPlayer.identifier] and money >= v.daily then
                xPlayer.removeAccountMoney('bank', v.daily)
                lib.notify(playerId, {
                    title = 'Storage',
                    description = ('Pay : %s'):format(lib.math.groupdigits(v.daily))
                })
            end
            Wait(100)
        end
    end
end)