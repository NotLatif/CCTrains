-- Central Controller script
local tt = require "tt"

local monitor = peripheral.find("monitor") or error("No monitor attached", 0)
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.closeAll()
modem.open(300)

local stations = {}
local channelCounter = 3000
local function addStation(name, channel)
    if not stations[name] then
        stations[name] = channel
        print("[+] Station: " .. name .. " (ch: " .. channel .. ")")
    else
        print("Station " .. name .. " already exists on channel " .. stations[name])
    end
end

-- sleep counter
local discoveryTime = 3

local function discoveryHelper()
    -- sends DISCOVERY and listens to the answare until all stations are discovered

    while true do
        modem.transmit(301, 300, "DISCOVERY")

        local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    
        if type(message) == "table" and message.message == "DACK" and message.name then
            -- station responded, addStation and set channel
            discoveryTime = 3
            print("< DACK from " .. message.name .. " (name: " .. message.name .. ") setting channel " .. channelCounter)
            addStation(message.name, channelCounter)
            modem.transmit(replyChannel, 300, {name = message.name, channel = channelCounter, message = "SETCHANNEL"})
            channelCounter = channelCounter + 1
        end

        os.sleep(0.1)

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

os.sleep(3) -- wait for stations to finish setting up

-- testing
print("Sending message to S1, ", stations["S1"])
modem.transmit(stations["S1"], 300, {name = "S1", type = "arr", from = "SC", to = "S2", eta = 10, stops = {"NT", "Farm", "Base Aiello"}})

os.sleep(2)
modem.transmit(stations["S1"], 300, {name = "S1", type = "arr", from = "SC", to = "S2", eta = 10, stops = {}})

os.sleep(2)
modem.transmit(stations["S1"], 300, {name = "S1", type = "arr", from = "SC", to = "S2", eta = 10, stops = {}})

-- load routing table
-- while true do
--     os.sleep(1)
-- end