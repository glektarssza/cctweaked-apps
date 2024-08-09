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

--- The application entry point.
local function main()
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

main()
