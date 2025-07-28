-- THE MODEM CONNECTED TO THE STATION MUST BE IN THE BACK SIDE
-- the intersection redstone relay can be on any other side
-- only one relay is allowed.
-- relay output is FRONT (where the face is)

-- we use 2 modems to avoid lan pollution/interfeerence with other intersections
-- one intersection computer is needed for every junction due to computercraft limitation
local config = require "config"

-- find out who's the modem-modem
local modem = peripheral.wrap("back") or print("ERROR, no station modem found (back side)")
if modem == nil then return end

local redstone, x = peripheral.find("redstone_relay")

if redstone == nil then print("ERROR - no redstone_relay found") end
if x ~= nil then print("ERROR - only one redstone_relay allowed") end
if redstone == nil or x ~= nil then return end

-- find station
modem.closeAll()
modem.open(302)
local stationChannel = nil
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")

    -- step 1
    if (message == "DISCOVERY") then
        print("< DISCOVERY")
        modem.transmit(replyChannel, 302, {message = "DACK", id = os.getComputerID(), name = config.name})
        print("> D ACK (id: " .. os.getComputerID() .. ")")
        stationChannel = replyChannel

    -- step 2
    elseif (type(message) == "table" and message.message == "SETCHANNEL" and message.name == config.name) then
        print("< SETCHANNEL " .. message.channel)
        modem.open(message.channel)
        modem.close(302) -- close discovery channel
        print('[I] Opened channel ' .. message.channel )
        print('[I] Closed channel ' .. 302 )
        break
    end
end

-- now we wait.


while true do
    ::continue::
    local _, _, ch, _, message, _ = os.pullEvent("modem_message")

    if message.name ~= config.name then
        print("ERROR - received message on private communication but name did not match")
        print("DEBUG - channel" .. ch .. " name: " .. message.name)
        goto continue
    end

    --
    print("DEBUG - message: ")
    for k, v in pairs(message) do print(k, v) end
    --

    if message.open == true then
        redstone.setOutput("front", true)

    elseif message.open == false then
        redstone.setOutput("front", false)

    end

end