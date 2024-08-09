-- The main installer script for all applications hosted in this repository.

--- Send a GET request to the GitHub user content server for a specific raw resource.
--- @param repo string The repository to request from.
--- @param branch string The branch to request from.
--- @param resource string The resource to request.
--- @param headers? table<string, string> The headers to send with the request.
--- @param binary? boolean Whether to request the resource as binary or not.
--- @return ccTweaked.http.BinaryResponse|ccTweaked.http.Response|nil response The response object or `nil` if the request failed.
--- @return string message The error message if the request failed.
--- @return ccTweaked.http.BinaryResponse|ccTweaked.http.Response|nil failedResponse The response object if the request failed.
local function getRawGitHubUserContent(repo, branch, resource, headers, binary)
    return http.get("https://raw.githubusercontent.com/" .. repo .. "/" .. branch .. "/" .. resource, headers, binary)
end

--- Get a resource from a GitHub repository and parse it as a JSON object.
--- @param repo string The repository to request from.
--- @param branch string The branch to request from.
--- @param resource string The resource to request.
--- @return table|nil response The JSON object or `nil` if the request failed.
--- @return string|nil message The error message if the request failed.
local function getGitHubUserContentAsJSON(repo, branch, resource)
    local response, responseMessage, failedResponse = getRawGitHubUserContent(repo, branch, resource)
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
        return nil, "Failed to get resource (" .. failedResponse.getResponseCode() .. "-" .. responseMessage .. ")"
    else
        return nil, "Failed to get resource (" .. responseMessage .. ")"
    end
end

--- Get a list of known applications from the repository.
--- @return string[]|nil apps The list of known applications.
--- @return string|nil message The error message if the request failed.
local function getAppList()
    return getGitHubUserContentAsJSON("glektarssza/cctweaked-apps", "chore/setup", "apps.json")
end

--- Get a list of known applications from the repository.
local function listApps()
    local apps, appsError = getAppList()
    if apps then
        print("Known Apps:")
        if #apps == 0 then
            print("  No applications available.")
        else
            for _, app in ipairs(apps) do
                print(" * " .. app)
            end
        end
    else
        printError("Error: Failed to get list of known applications (" .. appsError .. ")")
        return
    end
end

--- Print help information for the application.
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
    print("  install    Install an application.")
    print("  remove     Remove an application.")
    print("  update     Update an application.")
    print("")
    print("Copyright (c) 2024 G'lek Tarssza")
    print("All rights reserved.")
end

local function printVersion()
    print("G'lek's CC: Tweaked App Installer v0.0.1")
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
            if parsedArgs.command then
                return nil, nil, "Multiple commands specified"
            end
            parsedArgs.command = arg
            for j = i + 1, #args do
                table.insert(remainingArgs, args[j])
            end
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

    if parsedArgs.help then
        printHelp()
        return
    end

    if parsedArgs.version then
        printVersion()
        return
    end

    if not parsedArgs.command then
        printError("Error: No command specified")
        return
    end

    if parsedArgs.command == "about" then
        printError("Error: The about command is not yet implemented")
        return
    elseif parsedArgs.command == "help" then
        printHelp()
        return
    elseif parsedArgs.command == "version" then
        printVersion()
        return
    elseif parsedArgs.command == "list" then
        listApps()
        return
    elseif parsedArgs.command == "install" then
        printError("Error: The install command is not yet implemented")
        return
    elseif parsedArgs.command == "remove" then
        printError("Error: The remove command is not yet implemented")
        return
    elseif parsedArgs.command == "update" then
        printError("Error: The update command is not yet implemented")
        return
    end

    printError("Error: Unknown command \"" .. parsedArgs.command .. "\"")
end

main(arg)
