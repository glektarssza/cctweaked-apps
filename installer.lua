-- The main installer script for all applications hosted in this repository.

--- The repository owner to request from.
local OWNER = "glektarssza"

--- The repository to request from.
local REPOSITORY = "cctweaked-apps"

--- The branch to request from the repository.
local REPO_BRANCH = "chore/setup"

--- Send a GET request to the GitHub user content server for a specific raw resource.
--- @param owner string The owner of the repository to request from.
--- @param repo string The repository to request from.
--- @param branch string The branch to request from.
--- @param resource string The resource to request.
--- @param headers? table<string, string> The headers to send with the request.
--- @param binary? boolean Whether to request the resource as binary or not.
--- @return ccTweaked.http.BinaryResponse|ccTweaked.http.Response|nil response The response object or `nil` if the request failed.
--- @return string message The error message if the request failed.
--- @return ccTweaked.http.BinaryResponse|ccTweaked.http.Response|nil failedResponse The response object if the request failed.
local function getRawGitHubUserContent(owner, repo, branch, resource, headers, binary)
    return http.get("https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/" .. branch .. "/" .. resource,
        headers, binary)
end

--- Get a resource from a GitHub repository and parse it as a JSON object.
--- @param owner string The owner of the repository to request from.
--- @param repo string The repository to request from.
--- @param branch string The branch to request from.
--- @param resource string The resource to request.
--- @return table|nil response The JSON object or `nil` if the request failed.
--- @return string|nil message The error message if the request failed.
local function getGitHubUserContentAsJSON(owner, repo, branch, resource)
    local response, responseMessage, failedResponse = getRawGitHubUserContent(owner, repo, branch, resource)
    if response then
        local rawData = response.readAll()
        response.close()
        if rawData then
            local data = textutils.unserializeJSON(rawData)
            if data then
                return data
            else
                return nil, "Failed to parse JSON data"
            end
        end
        return nil, "Failed to read response (unexpected end of data)"
    end
    if failedResponse then
        return nil, "Failed to get resource (" .. failedResponse.getResponseCode() .. " - " .. responseMessage .. ")"
    else
        return nil, "Failed to get resource (" .. responseMessage .. ")"
    end
end

--- Get the manifest for an application.
--- @param appName string The name of the application to get the manifest for.
--- @return table|nil manifest The manifest for the application or `nil` if the request failed.
--- @return string|nil message The error message if the request failed.
local function getAppManifest(appName)
    return getGitHubUserContentAsJSON(OWNER, REPOSITORY, REPO_BRANCH, "apps/" .. appName .. "/manifest.json")
end

--- Get a list of known applications from the repository.
--- @return string[]|nil apps The list of known applications.
--- @return string|nil message The error message if the request failed.
local function getAppList()
    return getGitHubUserContentAsJSON(OWNER, REPOSITORY, REPO_BRANCH, "apps.json")
end

--- Print the version of the program.
local function printVersion()
    print("G'lek's CC: Tweaked App Installer v0.0.1")
end

local function printListAppsHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] list [command_options...] [query]")
    print("Options:")
    print("  -h, --help Print this help information.")
    print("  --version  Print the version of this program.")
    print("Command Options:")
    print("  N/A")
    print("")
    print("Arguments:")
    print("  query      The query to search for in the list of known applications.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Parse the arguments for the `list` command.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil parsedArgs The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseListAppsArgs(args)
    local parsedArgs = {}
    local remainingArgs = {}
    for i, arg in ipairs(args) do
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.query = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
    end
    return parsedArgs, remainingArgs
end

--- Get a list of known applications from the repository.
--- @param args? string[] The remaining arguments after the command.
local function listApps(args)
    local parsedArgs = nil
    local query = nil

    if args then
        parsedArgs = parseListAppsArgs(args)
    end

    if parsedArgs then
        if parsedArgs.help == "true" then
            printListAppsHelp()
            return
        end
        if parsedArgs.version == "true" then
            printVersion()
            return
        end
        query = parsedArgs.query
    end

    local apps, appsError = getAppList()
    if apps then
        local filteredApps = {}
        if query then
            for _, app in ipairs(apps) do
                if app:find(query) then
                    table.insert(filteredApps, app)
                end
            end
        else
            filteredApps = apps
        end
        print("Available Apps:")
        if #filteredApps == 0 then
            print("  No applications available.")
        else
            for _, app in ipairs(filteredApps) do
                print(" * " .. app)
            end
        end
    else
        printError("Error: Failed to get list of known applications (" .. appsError .. ")")
        return
    end
end

--- Parse the arguments for the `info` command.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil parsedArgs The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseShowAppInfoArgs(args)
    local parsedArgs = {}
    local remainingArgs = {}
    for i, arg in ipairs(args) do
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.appName = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
    end
    return parsedArgs, remainingArgs
end

--- Print help information for the `info` command.
local function printShowAppInfoHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] info [command_options...] appName")
    print("Options:")
    print("  -h, --help Print this help information.")
    print("  --version  Print the version of this program.")
    print("Command Options:")
    print("  N/A")
    print("")
    print("Arguments:")
    print("  appName     The name of the application to get information about.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Show information about an application.
--- @param args string[] The command line arguments.
local function showAppInfo(args)
    local parsedArgs = nil
    local appName = nil

    if args then
        parsedArgs = parseShowAppInfoArgs(args)
    end

    if parsedArgs then
        if parsedArgs.help == "true" then
            printShowAppInfoHelp()
            return
        end
        if parsedArgs.version == "true" then
            printVersion()
            return
        end
        appName = parsedArgs.appName
    end

    if not appName then
        printError("Error: No application specified")
        return
    end

    local manifest, manifestError = getAppManifest(appName)
    if manifest then
        print("ID: " .. manifest.id)
        print("Name: " .. manifest.name)
        print("Version: " .. manifest.version)
        print("Description: " .. manifest.description)
        print("Can be auto-booted: " .. (manifest.autoBoot and "Yes" or "No"))
        print("File Count: " .. #manifest.files)
    else
        printError("Error: Failed to get information about application \"" .. appName .. "\" (" .. manifestError .. ")")
    end
end

--- Print help information for the `install` command.
local function printInstallAppHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] install [command_options...] appName")
    print("Options:")
    print("  -h, --help           Print this help information.")
    print("  --version            Print the version of this program.")
    print("Command Options:")
    print("  --install-dir[=path] The directory the application is to be installed to.")
    print("  --auto-boot          Whether to enable auto-booting the application (if supported).")
    print("")
    print("Arguments:")
    print("  appName              The name of the application to install.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Parse the arguments for the `remove` command.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil parsedArgs The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseInstallAppArgs(args)
    local parsedArgs = {}
    local remainingArgs = {}
    local skipNext = false
    for i, arg in ipairs(args) do
        if skipNext then
            skipNext = false
            goto continue
        end
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            elseif arg == "--auto-boot" then
                parsedArgs.autoBoot = "true"
            elseif arg:match("--install-dir=") then
                parsedArgs.installDir = arg:sub(#"--install-dir=" + 1)
            elseif arg == "--install-dir" then
                if not args[i + 1] then
                    return nil, nil, "Missing value for --install-dir option"
                end
                parsedArgs.installDir = args[i + 1]
                skipNext = true
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.appName = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
        ::continue::
    end
    return parsedArgs, remainingArgs
end

--- Install an application.
--- @param args string[] The command line arguments.
local function installApp(args)
    local parsedArgs = nil
    local appName = nil
    local installDir = nil
    local autoBoot = nil

    if args then
        parsedArgs = parseInstallAppArgs(args)
    end

    if parsedArgs then
        if parsedArgs.help == "true" then
            printInstallAppHelp()
            return
        end
        if parsedArgs.version == "true" then
            printVersion()
            return
        end
        appName = parsedArgs.appName
        installDir = parsedArgs.installDir
        autoBoot = parsedArgs.autoBoot
    end

    if not appName then
        printError("Error: No application specified")
        return
    end

    local manifest, manifestError = getAppManifest(appName)
    if not manifest then
        printError("Error: Failed to get information about application \"" .. appName .. "\" (" .. manifestError .. ")")
        return
    end

    if not installDir then
        installDir = "/apps/" .. appName
    end

    local installDirExists = fs.exists(installDir)
    if installDirExists then
        local installDirIsDir = fs.isDir(installDir)
        if not installDirIsDir then
            printError("Error: Cannot install \"" .. appName .. "\" to requested directory (it's not a directory)")
            return
        end
        local installDirEmpty = fs.list(installDir)
        if #installDirEmpty > 0 then
            printError("Error: Cannot install \"" .. appName .. "\" to requested directory (it's not empty)")
            return
        end
    else
        fs.makeDir(installDir)
    end

    local files = manifest.files

    for _, file in ipairs(files) do
        local response, responseMessage, failedResponse = getRawGitHubUserContent(OWNER, REPOSITORY, REPO_BRANCH,
            "apps/" .. appName .. "/" .. file, nil, true)
        if response then
            local fileData = response.readAll()
            response.close()
            if fileData then
                local fileHandle = fs.open(fs.combine(installDir, file), "w")
                if fileHandle then
                    fileHandle.write(fileData)
                    fileHandle.close()
                else
                    printError("Error: Failed to write file \"" .. file .. "\" to installation directory")
                    fs.delete(installDir)
                    return
                end
            else
                printError("Error: Failed to read file \"" .. file .. "\" from response")
                fs.delete(installDir)
                return
            end
        else
            if failedResponse then
                printError("Error: Failed to get file \"" ..
                    file .. "\" (" .. failedResponse.getResponseCode() .. " - " ..
                    responseMessage .. ")")
            else
                printError("Error: Failed to get file \"" .. file .. "\" (" .. responseMessage .. ")")
            end
        end
    end

    local manifestHandle = fs.open(fs.combine(installDir, "manifest.json"), "w")
    if manifestHandle then
        manifestHandle.write(textutils.serializeJSON(manifest))
        manifestHandle.close()
    else
        printError("Error: Failed to write manifest file to installation directory")
        fs.delete(installDir)
        return
    end

    if autoBoot then
        term.setTextColor(colors.yellow)
        print("Warning: Auto-booting is not supported yet!")
        term.setTextColor(colors.white)
    end

    print("Application \"" .. appName .. "\" has been installed")
end

--- Print help information for the `remove` command.
local function printRemoveAppHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] remove [command_options...] appName")
    print("Options:")
    print("  -h, --help           Print this help information.")
    print("  --version            Print the version of this program.")
    print("Command Options:")
    print("  --install-dir[=path] The directory the application to remove is installed to.")
    print("")
    print("Arguments:")
    print("  appName              The name of the application to remove.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Parse the arguments for the `remove` command.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil parsedArgs The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseRemoveAppArgs(args)
    local parsedArgs = {}
    local remainingArgs = {}
    local skipNext = false
    for i, arg in ipairs(args) do
        if skipNext then
            skipNext = false
            goto continue
        end
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            elseif arg:match("--install-dir=") then
                parsedArgs.installDir = arg:sub(#"--install-dir=" + 1)
            elseif arg == "--install-dir" then
                if not args[i + 1] then
                    return nil, nil, "Missing value for --install-dir option"
                end
                parsedArgs.installDir = args[i + 1]
                skipNext = true
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.appName = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
        ::continue::
    end
    return parsedArgs, remainingArgs
end

--- Remove a previously installed application.
--- @param args string[] The command line arguments.
local function removeApp(args)
    local parsedArgs = nil
    local appName = nil
    local installDir = nil

    if args then
        parsedArgs = parseRemoveAppArgs(args)
    end

    if parsedArgs then
        if parsedArgs.help == "true" then
            printRemoveAppHelp()
            return
        end
        if parsedArgs.version == "true" then
            printVersion()
            return
        end
        appName = parsedArgs.appName
        installDir = parsedArgs.installDir
    end

    if not appName then
        printError("Error: No application specified")
        return
    end

    if not installDir then
        installDir = "/apps/" .. appName
    end

    local installDirExists = fs.exists(installDir)
    if not installDirExists then
        printError("Error: Application \"" .. appName .. "\" is not installed")
        return
    end

    local installDirIsDir = fs.isDir(installDir)
    if not installDirIsDir then
        printError("Error: Application \"" .. appName .. "\" is not installed")
        return
    end

    fs.delete(installDir)

    print("Application \"" .. appName .. "\" has been removed")
end

--- Parse the arguments for the `update` command.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil parsedArgs The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseUpdateAppArgs(args)
    local parsedArgs = {}
    local remainingArgs = {}
    local skipNext = false
    for i, arg in ipairs(args) do
        if skipNext then
            skipNext = false
            goto continue
        end
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            elseif arg:match("--temp-dir=") then
                parsedArgs.tempDir = arg:sub(#"--temp-dir=" + 1)
            elseif arg == "--temp-dir" then
                if not args[i + 1] then
                    return nil, nil, "Missing value for --temp-dir option"
                end
                parsedArgs.tempDir = args[i + 1]
                skipNext = true
            elseif arg:match("--install-dir=") then
                parsedArgs.installDir = arg:sub(#"--install-dir=" + 1)
            elseif arg == "--install-dir" then
                if not args[i + 1] then
                    return nil, nil, "Missing value for --install-dir option"
                end
                parsedArgs.installDir = args[i + 1]
                skipNext = true
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.appName = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
        ::continue::
    end
    return parsedArgs, remainingArgs
end

--- Print help information for the `update` command.
local function printUpdateAppHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] update [command_options...] appName")
    print("Options:")
    print("  -h, --help           Print this help information.")
    print("  --version            Print the version of this program.")
    print("Command Options:")
    print("  --temp-dir[=path]    The temporary directory to use for downloading files.")
    print("  --install-dir[=path] The directory the application to update is installed to.")
    print("")
    print("Arguments:")
    print("  appName              The name of the application to update.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Update an application.
--- @param args? string[] The command line arguments.
local function updateApp(args)
    local parsedArgs = nil
    local appName = nil
    local tempDir = nil
    local installDir = nil

    if args then
        parsedArgs = parseUpdateAppArgs(args)
    end

    if parsedArgs then
        if parsedArgs.help == "true" then
            printUpdateAppHelp()
            return
        end
        if parsedArgs.version == "true" then
            printVersion()
            return
        end
        appName = parsedArgs.appName
        tempDir = parsedArgs.tempDir
        installDir = parsedArgs.installDir
    end

    if not appName then
        printError("Error: No application specified")
        return
    end

    if not tempDir then
        tempDir = "/.tmp"
    end

    if not installDir then
        installDir = "/apps/" .. appName
    end

    local manifest, manifestError = getAppManifest(appName)

    if not manifest then
        printError("Error: Failed to get information about application \"" .. appName .. "\" (" .. manifestError .. ")")
        return
    end

    local installDirExists = fs.exists(installDir)
    if not installDirExists then
        printError("Error: Application \"" .. appName .. "\" is not installed")
        return
    end

    local installDirIsDir = fs.isDir(installDir)
    if not installDirIsDir then
        printError("Error: Application \"" .. appName .. "\" is not installed")
        return
    end

    local tempDirExists = fs.exists(tempDir)
    if not tempDirExists then
        fs.makeDir(tempDir)
    end

    local tempDirIsDir = fs.isDir(tempDir)
    if not tempDirIsDir then
        printError("Error: The temporary directory is not a directory")
        return
    end

    local tempDirEmpty = fs.list(tempDir)
    if #tempDirEmpty > 0 then
        printError("Error: The temporary directory is not empty")
        return
    end

    local files = manifest.files

    for _, file in ipairs(files) do
        local response, responseMessage, failedResponse = getRawGitHubUserContent(OWNER, REPOSITORY, REPO_BRANCH,
            "apps/" .. appName .. "/" .. file, nil, true)
        if response then
            local fileData = response.readAll()
            response.close()
            if fileData then
                local filePath = fs.combine(tempDir, file)
                local fileHandle = fs.open(filePath, "w")
                if fileHandle then
                    fileHandle.write(fileData)
                    fileHandle.close()
                else
                    printError("Error: Failed to write file \"" .. file .. "\" to temporary directory")
                    fs.delete(tempDir)
                    return
                end
            else
                printError("Error: Failed to read file \"" .. file .. "\" from response")
                fs.delete(tempDir)
                return
            end
        else
            if failedResponse then
                printError("Error: Failed to get file \"" ..
                    file .. "\" (" .. failedResponse.getResponseCode() .. " - " ..
                    responseMessage .. ")")
            else
                printError("Error: Failed to get file \"" .. file .. "\" (" .. responseMessage .. ")")
            end
            fs.delete(tempDir)
            return
        end
    end

    local installDirFiles = fs.list(installDir)

    for _, file in ipairs(installDirFiles) do
        fs.delete(fs.combine(installDir, file))
    end

    for _, file in ipairs(files) do
        fs.move(fs.combine(tempDir, file), fs.combine(installDir, file))
    end

    local manifestHandle = fs.open(fs.combine(installDir, "manifest.json"), "w")
    if manifestHandle then
        manifestHandle.write(textutils.serializeJSON(manifest))
        manifestHandle.close()
    else
        printError("Error: Failed to write manifest file to installation directory")
        fs.delete(installDir)
        fs.delete(tempDir)
        return
    end

    fs.delete(tempDir)

    print("Application \"" .. appName .. "\" has been updated to version " .. manifest.version)
end

--- Print the program about information.
local function printAbout()
    print("G'lek's CC: Tweaked App Installer")
    print("This program is a simple installer for applications hosted in the complimentary GitHub repository.")
    print("For more information, please visit the GitHub repository.")
    print("https://github.com/glektarssza/cctweaked-apps")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Print help information for the program.
local function printHelp()
    print("G'lek's CC: Tweaked App Installer")
    print("Usage: installer [options...] command")
    print("Options:")
    print("  -h, --help Print this help information.")
    print("  --version  Print the version of this program.")
    print("")
    print("Commands:")
    print("  about      Print information about this program.")
    print("  help       Print this help information.")
    print("  version    Print the version of this program.")
    print("  list       List all known applications.")
    print("  info       Display information about an application.")
    print("  install    Install an application.")
    print("  remove     Remove an application.")
    print("  update     Update an application.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

--- Parse the command line arguments.
--- @param args string[] The command line arguments.
--- @return table<string, string>|nil arguments The parsed arguments.
--- @return string[]|nil remainingArgs The remaining arguments after the parsed arguments.
--- @return string|nil message The error message if the arguments could not be parsed.
local function parseArguments(args)
    local parsedArgs = {}
    local remainingArgs = {}
    for i, arg in ipairs(args) do
        if arg:sub(1, 1) == "-" then
            if arg == "-h" or arg == "--help" then
                parsedArgs.help = "true"
            elseif arg == "--version" then
                parsedArgs.version = "true"
            else
                return nil, nil, "Unknown command line option \"" .. arg .. "\""
            end
        else
            parsedArgs.command = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
            break
        end
    end
    return parsedArgs, remainingArgs
end

--- The application entry point.
--- @param args string[] The command line arguments.
local function main(args)
    local parsedArgs, remainingArgs, parseError = parseArguments(args)
    if not parsedArgs then
        printError("Error: " .. parseError)
        return
    end

    if parsedArgs.help == "true" then
        printHelp()
        return
    end

    if parsedArgs.version == "true" then
        printVersion()
        return
    end

    if not parsedArgs.command then
        printError("Error: No command specified")
        return
    end

    if parsedArgs.command == "about" then
        printAbout()
        return
    elseif parsedArgs.command == "help" then
        printHelp()
        return
    elseif parsedArgs.command == "version" then
        printVersion()
        return
    elseif parsedArgs.command == "list" then
        listApps(remainingArgs)
        return
    elseif parsedArgs.command == "info" then
        showAppInfo(remainingArgs)
        return
    elseif parsedArgs.command == "install" then
        installApp(remainingArgs)
        return
    elseif parsedArgs.command == "remove" then
        removeApp(remainingArgs)
        return
    elseif parsedArgs.command == "update" then
        updateApp(remainingArgs)
        return
    end

    printError("Error: Unknown command \"" .. parsedArgs.command .. "\"")
end

main(arg)
