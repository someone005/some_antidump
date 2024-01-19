--[[
    RECOMMENDED TO OBFUSCATE THIS FILE!
]]

resourceName = GetCurrentResourceName()
if IsDuplicityVersion() then
    function scanDirectory(directory)
        local files = {}
        local p = io.popen('dir "' .. directory .. '" /B /a-d')
        for file in p:lines() do
            if file ~= 'fxmanifest.lua' and file ~= '__resource.lua' then
                table.insert(files, file)
            end
        end
        p:close()
        return files
    end

    function getPath(directory)
        local sub = ''
        for folder in directory:gmatch("([^/]+)/") do
            sub = sub .. folder .. '/'
            directory = directory:gsub(folder .. '/', '')
        end
    
        return sub, directory
    end

    function readFile(path)
        local file = io.open(path, 'r')

        if file then
            local content = file:read("*all")
            file:close()
            return content
        else
            return nil
        end
    end
    
    CreateThread(function()
        resourcePath = GetResourcePath(resourceName)
        local scripts = {}
        local players = {}
        
        for i=0, GetNumResourceMetadata(resourceName, 'antidump')-1 do
            local fileName = GetResourceMetadata(resourceName, 'antidump', i)
            
            if fileName then
                local files = {}

                if not fileName:find('%*') then
                    table.insert(files, {
                        location = resourcePath .. '/' .. fileName,
                        fileName = fileName
                    })
                elseif fileName:find("%*") and not fileName:find("%*%*") then
                    local path, _ = getPath(resourcePath .. '/' .. fileName)
                    local currentFiles = scanDirectory(path)

                    for k,v in pairs(currentFiles) do
                        table.insert(files, {
                            location = path .. v,
                            fileName = fileName
                        })
                    end
                else
                    print(("[^3some_antidump^7] ^1Antidump has been installed in resource %s that uses ** globbing (%s)! Stopping resource..^7"):format(resource, fileName))
                    StopResource(resourceName)
                    return
                end

                for _, fileName in pairs(files) do
                    local file = readFile(fileName.location)
                    if not file then
                        print(("[^3some_antidump^7] File %s used in manifest of resource %s doesn't exist!"):format(fileName, resourceName))
                    else
                        table.insert(scripts, encrypt(file))
                    end
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

    function encrypt(str)
        -- implement your own logic
        return str
    end
else
    Wait(1000) -- let server load whole code

    TriggerServerEvent(resourceName .. ':check')

    codeLoaded = false
    RegisterNetEvent(resourceName .. ':load', function(scripts)
        if codeLoaded then return end
        codeLoaded = true
        for i=1, #scripts do
            local loaded, err = load(decrypt(scripts[i]))

            if loaded then
                loaded()
            else
                print("Script error: " .. err)
            end
        end
    end)

    function decrypt(str)
        -- implement your own logic
        return str
    end
end