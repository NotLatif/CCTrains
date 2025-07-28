-- Central Controller script (manages stations)

local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.closeAll()
modem.open(300)

local stations = {}
local channelCounter = 3000
local function addStation(sName, channel)
    if not stations[sName] then
        stations[sName] = channel
        print("Station added: " .. sName .. " on channel " .. channel)
    else
        print("Station " .. sName .. " already exists on channel " .. stations[sName])
    end
end

-- discover online stations and give them a communication channel
modem.transmit(301, 300, "DISCOVERY")
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    if type(message) == "table" and message.message == "DACK" and message.name then
        print("< DACK from " .. message.name .. " setting channel " .. channelCounter)
        addStation(message.name, channelCounter)
        modem.transmit(replyChannel, 300, {name = message.name, channel = channelCounter, message = "SETCHANNEL"})
        channelCounter = channelCounter + 1
    end
end


-- local startTime = os.clock()
-- while os.clock() - startTime < 5 do
--     local eventData = {os.pullEventTimeout("modem_message", 5 - (os.clock() - startTime))}
--     if eventData[1] == "modem_message" then
--         local _, _, _, replyChannel, message, _ = table.unpack(eventData)
--         if type(message) == "table" and message.message == "DACK" and message.id then
--             addStation(message.id, channelCounter)
--             modem.transmit(replyChannel, 300, {id = message.id, channel = channelCounter})
--             channelCounter = channelCounter + 1
--         end
--     else
--         break -- timeout reached, exit loop
--     end
-- end