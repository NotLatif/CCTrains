-- reboot/start intersections
local pcs = { peripheral.find("computer") }

if #pcs == 0 then
    print("ERRORE - nessuna stazione trovata")
    return
end

for _, pc in ipairs(pcs) do
    if pc.isOn() then
        pc.reboot()
        print("Rebooting ", pc.getLabel())
    else
        pc.turnOn()
        print("Turning on ", pc.getLabel())
    end
end

print("Waiting for all computers to reboot...")
os.sleep(5) -- wait for all computers to reboot
print("Discovering intersections...")

local config = require "config"

local m1, m2 = peripheral.find("modem")

if m1 == nil then 
    print("ERRORE - modem 1 mancante")
    return
elseif m2 == nil then
    print("ERRORE - modem 2 mancente")
    return
end

local modem, lan = nil, nil

if m1.isWireless() and not m2.isWireless() then
    modem = m1
    lan = m2
elseif not m1.isWireless() and m2.isWireless() then
    lan = m1
    modem = m2
else
    print("ERRORE - è necessario 1 modem wireless e 1 wired")
    return
end


modem.closeAll()

lan.closeAll()
lan.open(301)


-- find intersections ---------------------------------
local intersections = {}
local channelCounter = 2000
local function addIntersection(name, channel)
    if not intersections[name] then
        intersections[name] = channel
        print("Station added: " .. name .. " on channel " .. channel)
    else
        print("Station " .. name .. " already exists on channel " .. intersections[name])
    end
end

-- sleep counter
local discoveryTime = 3

local function discoveryHelper()
    -- sends DISCOVERY and listens to the answare until all stations are discovered

    while true do
        lan.transmit(302, 301, "DISCOVERY")

        local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
        -- no need to check for side matching as the wan modem has ports cloed for now

        if type(message) == "table" and message.message == "DACK" and message.name then
            -- intersection responded, addIntersection and set channel
            discoveryTime = 3
            print("< DACK from " .. message.name .. " (name: " .. message.name .. ") setting channel " .. channelCounter)
            addIntersection(message.name, channelCounter)
            lan.transmit(replyChannel, 301, {name = message.name, channel = channelCounter, message = "SETCHANNEL"})
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

local function discoverIntersections()
    -- discover online stations and give them a communication channel
    parallel.waitForAny( -- if no answer within 3 seconds, done
        discoveryHelper,
        wait
    )

    local count = 0
    for _ in pairs(intersections) do count = count + 1 end
    print("Discovered Stations:".. count)
end

discoverIntersections()

-- testing (debug)
for key, value in pairs(intersections) do
    lan.transmit(value, 301, {name = key, direction = "left"})
    os.sleep(1)
    lan.transmit(value, 301, {name = key, direction = "right"})
end



modem.open(301)
-- Wait for CC connection ---------------------------------
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")

    -- step 1
    if (message == "DISCOVERY") then
        print("< DISCOVERY")
        modem.transmit(replyChannel, 301, {message = "DACK", name = config.name})
        print("> D ACK (id: " .. os.getComputerID() .. ")")

    -- step 2
    elseif (type(message) == "table" and message.message == "SETCHANNEL" and message.name == config.name) then
        print("< SETCHANNEL " .. message.channel)
        modem.open(message.channel)
        modem.close(301) -- close discovery channel
        print('[I] Opened channel ' .. message.channel )
        print('[I] Closed channel ' .. 301 )
        break
    end
end

-- Station initialization

