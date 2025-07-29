-- Central Controller script
local tt = require "tt"

local monitor = peripheral.find("monitor") or error("No monitor attached", 0)
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.closeAll()
modem.open(300)

local stations = {}
local channelCounter = 3000
local function addStation(id, channel)
    if not stations[id] then
        stations[id] = channel
        print("Station added: " .. id .. " on channel " .. channel)
    else
        print("Station " .. id .. " already exists on channel " .. stations[id])
    end
end

-- sleep counter
local discoveryTime = 3

local function discoveryHelper()
    -- sends DISCOVERY and listens to the answare until all stations are discovered

    while true do
        modem.transmit(301, 300, "DISCOVERY")

        local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    
        if type(message) == "table" and message.message == "DACK" and message.id then
            -- station responded, addStation and set channel
            discoveryTime = 3
            print("< DACK from " .. message.name .. " (id: " .. message.id .. ") setting channel " .. channelCounter)
            addStation(message.id, channelCounter)
            modem.transmit(replyChannel, 300, {id = message.id, channel = channelCounter, message = "SETCHANNEL"})
            channelCounter = channelCounter + 1
        end

        os.sleep(0.05)

    end
end


local function wait()
    -- function will continue sleeping until discoveryHelper stops resetting discoveryTime
    while discoveryTime > 0 do
        os.sleep(1)
        discoveryTime = discoveryTime - 1
    end
    print("discoveryTime Elapsed!")
end


local function discoverStations()
    -- discover online stations and give them a communication channel
    parallel.waitForAny( -- if no answer within 3 seconds, done
        discoveryHelper,
        wait
    )

    local count = 0
    for _ in pairs(stations) do count = count + 1 end
    print("Discovered Stations:".. count)
end

discoverStations()

-- load routing table
