resourceName = GetCurrentResourceName()
if IsDuplicityVersion() then
    function scanDirectory(directory)
        local files = {}
        local p = io.popen('dir "' .. directory .. '" /B')
        for file in p:lines() do
            table.insert(files, file)
        end
        p:close()
        return files
    end
    
    CreateThread(function()
        local scripts = {}
        local players = {}
        
        for i=0, GetNumResourceMetadata(resourceName, 'antidump')-1 do
            local fileName = GetResourceMetadata(resourceName, 'antidump', i)
            
            if fileName then
                local file = LoadResourceFile(resourceName, fileName)
                if not file then
                    print(("[^3some_antidump^7] File %s used in manifest of resource %s doesn't exist!"):format(fileName, resourceName))
                else
                    table.insert(scripts, file)
                end
            end
        end
        
        RegisterServerEvent(resourceName .. ':check', function()
            local playerId = source
        
            if players[playerId] then return end
            players[playerId] = true
        
            TriggerClientEvent(resourceName .. ':load', playerId, scripts)
        end)
    end)
else
    Wait(1000) -- let server load whole code

    TriggerServerEvent(resourceName .. ':check')

    RegisterNetEvent(resourceName .. ':load', function(scripts)
        for i=1, #scripts do
            local loaded, err = load(scripts[i])

            if loaded then
                loaded()
            else
                print("Script error: " .. err)
            end
        end
    end)
end