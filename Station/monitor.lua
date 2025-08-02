local monitor = peripheral.find("monitor") or print("ERROR - no monitor found")
if monitor == nil then return end
local cursory = 1

monitor.setTextScale(1.5)
local w, h = monitor.getSize()
local lineY = {}
local memory = {}

monitor.setTextScale(0.5)
local function raw(message)
    monitor.write(message)
    local _, y = monitor.getCursorPos()
    monitor.setCursorPos(0, y+1)
end

local function resetcol()
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
end

local function clear()
    monitor.setCursorPos(1, 1)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

local function init()
    clear()
    monitor.setTextScale(1.5)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, 1)

    for i = 1, w do
        monitor.write(" ")
    end

    monitor.setCursorPos(2, 1)
    monitor.write("STASSSIONE")

    cursory = 2

    monitor.setBackgroundColor(colors.black)
end

local function append(line)
    -- line: {from, to, stops[], platform, ETA}
    if type(line) ~= "table" then
        return nil
    end


    monitor.setCursorPos(1, cursory + 1)
    monitor.write(line.to)

    monitor.setCursorPos( w - 2 - #line.platform - 3 - #tostring(line.ETA),
                            cursory + 1)
    
    if (line.ETA == 0) then
        monitor.write(" " .. " " .. "  ")
    else
        monitor.write(" " .. line.ETA .. "s ")
    end
    local color = colors.orange
    if line.arrived ~= nil then
        color = line.arrived
    end
    monitor.setBackgroundColor(color)
    monitor.write(" " .. line.platform .. " ")
    resetcol()

    monitor.setCursorPos(2, cursory + 2)
    monitor.write("Ferma: ")
    for _, stop in ipairs(line.stops) do
        monitor.write(stop .. ", ")
    end

    lineY[line.platform] = cursory + 1
    memory[line.platform] = line
    cursory = cursory + 2
end

local function arrived(platform)
    if type(platform) ~= "string" then return nil end
    if lineY[platform] == nil then return nil end

    monitor.setCursorPos(w - 2 - #platform - 3 - #tostring(0),
                            lineY[platform])
    monitor.write(" " .. " " .. "  ")
    monitor.setBackgroundColor(colors.green)
    monitor.write(" " .. platform .. " ")
    resetcol()
    memory[platform].arrived = colors.green
    memory[platform].ETA = 0
end

local function delayed(platform)
    if type(platform) ~= "string" then return nil end
    if lineY[platform] == nil then return nil end

    monitor.setCursorPos(w - 2 - #platform - 3 - #tostring(0),
                            lineY[platform])
    monitor.write(" " .. " " .. "  ")
    monitor.setBackgroundColor(colors.red)
    monitor.write(" " .. platform .. " ")
    resetcol()
    memory[platform].arrived = colors.red

end


local function departed(platform)
    if type(platform) ~= "string" then return nil end
    if lineY[platform] == nil then return nil end

    memory[platform] = nil

    init()
    for key, value in pairs(memory) do
        append(value)
    end

    resetcol()
    lineY[platform] = nil
end


clear()

return {
    clear = clear,
    init = init,
    append = append,
    arrived = arrived,
    departed = departed,
    delayed = delayed,
    raw = raw
}