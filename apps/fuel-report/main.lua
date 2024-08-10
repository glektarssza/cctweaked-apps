--- Pad a title to the center of a given width.
--- @param title string The title to pad.
--- @param width number The width to pad the title to.
--- @param paddingCharacter string The character to use for padding.
--- @return string # The padded title.
local function padTitle(title, width, paddingCharacter)
    local padding = math.floor((width - #title) / 2)
    local paddingChar = paddingCharacter or " "
    return string.rep(paddingChar, padding) .. title .. string.rep(paddingChar, padding)
end

--- Create a fuel bar with a given width and fuel level.
--- @param width number The width of the fuel bar.
--- @param level number The fuel level to represent.
local function createFuelBar(width, level)
    local bar = ""
    local fuelLevel = math.floor(level * width)
    bar = bar .. string.rep("\167", fuelLevel)
    bar = bar .. string.rep("\016", width - fuelLevel)
    return bar
end

--- Map a fluid type to a human-readable name.
--- @param fluidType string The fluid type to map.
--- @return string # The human-readable name of the fluid type.
local function mapFluidTypeToName(fluidType)
    if fluidType == "minecraft:lava" then
        return "Lava"
    elseif fluidType == "minecraft:water" then
        return "Water"
    elseif fluidType == "createdieselgenerators:biodiesel" then
        return "Biodiesel"
    end
    return "Unknown"
end

--- The program entry point.
local function main()
    --- @diagnostic disable-next-line: param-type-mismatch
    local tanks = { peripheral.find("fluidTank") }
    if #tanks == 0 then
        printError("Error: No tanks available to report on!")
        return
    end
    --- @diagnostic disable-next-line: param-type-mismatch
    local displaySource = peripheral.find("create_source")
    if not displaySource then
        printError("Error: No display available to report on!")
        return
    end
    while true do
        os.sleep(5)
        local displayWidth, displayHeight = displaySource.getSize()
        displaySource.clear()
        displaySource.setCursorPos(1, 1)
        displaySource.write(padTitle(" Fuel Report ", displayWidth, "#"))
        local y = 2
        for _, tank in ipairs(tanks) do
            local tankInfo = tank.getInfo()
            local fluidName = mapFluidTypeToName(tankInfo.fluid)
            displaySource.setCursorPos(1, y)
            local title = fluidName .. ": "
            displaySource.write(title .. createFuelBar(displayWidth - #title, tankInfo.amount / tankInfo.capacity))
            y = y + 1
            if y > displayHeight then
                break
            end
        end
    end
end

main()
