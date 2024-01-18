myName = GetCurrentResourceName()
fileName = "shared_script '@" .. myName .. "/shared.lua'"

RegisterCommand('antidump', function(source, args)
    if source ~= 0 then return end

    local option = args[1]
    local parameter = args[2]

    if option == 'install' then
        if parameter then
            if myName == parameter then return end
            local state = GetResourceState(parameter)
            if state == 'missing' then
                print(("[^3some_antidump^7] Resource %s is missing!"):format(parameter))
                return
            elseif state ~= 'started' then
                print(("[^3some_antidump^7] Resource %s is not started!"):format(parameter))
                return
            end

            if Config.IgnoredScripts[parameter] then
                print(("[^3some_antidump^7] Resource %s is on the ignore list"):format(parameter))
            else
                local success = install(parameter)

                if success == false then
                    print(("[^3some_antidump^7] Antidump is already installed in resource %s"):format(parameter))
                end
            end
        else
            local found = 0
            local installed = 0
            for i=0, GetNumResources() do
                local resource = GetResourceByFindIndex(i)
                if resource and myName == resource then goto continue end
                
                if resource and GetResourceState(resource) ~= 'missing' then
                    found+=1

                    if install(resource, true) then installed+=1 end
                end
                ::continue::
            end

            print(("[^3some_antidump^7] Installed antidump to %s/%s scripts"):format(installed, found))
        end
    else
        if parameter then
            if myName == parameter then return end
            local state = GetResourceState(parameter)
            if state == 'missing' then
                print(("[^3some_antidump^7] Resource %s is missing!"):format(parameter))
                return
            elseif state ~= 'started' then
                print(("[^3some_antidump^7] Resource %s is not started!"):format(parameter))
                return
            end

            local success = uninstall(parameter)

            if not success then
                print(("[^3some_antidump^7] Antidump is not installed in resource %s"):format(parameter))
            end
        else
            local found = 0
            local uninstalled = 0
            for i=0, GetNumResources() do
                local resource = GetResourceByFindIndex(i)
                if resource and myName == resource then goto continue end

                if resource and GetResourceState(resource) ~= 'missing' then
                    found+=1

                    if uninstall(resource, true) then uninstalled+=1 end
                end

                ::continue::
            end

            print(("[^3some_antidump^7] Uninstalled antidump from %s/%s scripts"):format(uninstalled, found))
        end
    end
end)

function install(resource, auto)
    local installed, manifestName = checkIfInstalled(resource)

    if not installed and not manifestName then
        if not auto then
            print(("[^3some_antidump^7] ^1Couldn't find manifest of resource %s^7"):format(resource))
        end
        return
    end

    local manifest = LoadResourceFile(resource, manifestName)

    if installed then
        return false
    else
        for i=0, GetNumResourceMetadata(resource, 'client_script')-1 do
            local data = GetResourceMetadata(resource, 'client_script', i)

            if data then
                if data:find('%*%*') then
                    print(("[^3some_antidump^7] ^1Cannot install antidump in resource %s! ^3Globbing ** used in %s^7"):format(resource, data))
                    return
                end
            end
        end

        manifest = fileName .. '\n' .. manifest
        manifest = manifest:gsub("client_script '([^']+)'", 'antidump \'%1\'')
        manifest = manifest:gsub("client_scripts%s*{", 'antidump {')

        SaveResourceFile(resource, manifestName, manifest, manifest:len())
        print(("[^3some_antidump^7] ^2Installed antidump in resource %s^7"):format(resource))
        return true
    end
end

function uninstall(resource, auto)
    local installed, manifestName = checkIfInstalled(resource)

    if not installed and not manifestName then
        if not auto then
            print(("[^3some_antidump^7] ^1Couldn't find manifest of resource %s^7"):format(resource))
        end
        return
    end

    local manifest = LoadResourceFile(resource, manifestName)

    if installed then
        manifest = manifest:gsub(fileName .. '\n', '')
        manifest = manifest:gsub("antidump '([^']+)'", 'client_script \'%1\'')
        manifest = manifest:gsub("antidump%s*{", 'client_scripts {')

        SaveResourceFile(resource, manifestName, manifest, manifest:len())
        print(("[^3some_antidump^7] ^2Uninstalled antidump in resource %s^7"):format(resource))
        return true
    else
        return false
    end
end

function checkIfInstalled(resource)
    if GetResourceState(resource) == 'started' then
        local manifestName = 'fxmanifest.lua'
        local manifest = LoadResourceFile(resource, manifestName)

        if not manifest then
            manifestName = '__resource.lua'
            manifest = LoadResourceFile(resource, manifestName)
        end

        if not manifest then
            return false
        end

        return string.find(manifest, fileName), manifestName
    else
        return false
    end
end