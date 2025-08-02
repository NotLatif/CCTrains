local monitor = require "monitor"
monitor.clear()

local function serialize(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        local key = tostring(k)
        local value
        if type(v) == "table" then
            value = serialize(v)
        elseif type(v) == "string" then
            value = '"' .. v .. '"'
        else
            value = tostring(v)
        end
        result = result .. key .. "=" .. value .. ","
    end
    result = result .. "}"
    return result:gsub("\n", "")
end

local usingMonitor = true
local function log(lvl, message)
    if lvl == nil or message == nil then
        print("tried to print nil values")
        print(lvl, message)
        return
    end

    if usingMonitor then
        monitor.raw("[" .. lvl .. "]: " ..message)
    else
        print("[" .. lvl .. "]: " ..message)
    end

end

-- reboot/start intersections
local pcs = { peripheral.find("computer") }

if #pcs == 0 then
    log("E",  "nessuna stazione trovata")
    return
end

log("I",  "Rebooting lan computers...")

for _, pc in ipairs(pcs) do
    if pc.isOn() then
        pc.reboot()
    else
        pc.turnOn()
    end
end

os.sleep(5) -- wait for all computers to reboot
log("I",  "Discovering intersections...")

local config = require "config"
local routing = require "routing"

local m1, m2 = peripheral.find("modem")

if m1 == nil then 
    log("E",  "modem 1 mancante")
    return
elseif m2 == nil then
    log("E",  "modem 2 mancente")
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
    log("E",  "è necessario 1 modem wireless e 1 wired")
    return
end


modem.closeAll()

lan.closeAll()
lan.open(301)


-- find intersections and stops ---------------------------------
local intersections = {}
local stops = {}
local channelCounter = 2000
local function addIntersection(name, channel)
    if not intersections[name] then
        intersections[name] = channel
        log("I",  "[+] intersection: " .. name .. " (ch: " .. channel .. ")")
    else
        log("D",  "intersection " .. name .. " already exists on channel " .. intersections[name])
    end
end

local function addStop(name, channel)
    if not stops[name] then
        stops[name] = channel
        log("I",  "[+] Stop: " .. name .. " (ch: " .. channel .. ")")
    else
        log("D",  "Stop " .. name .. " already exists on channel " .. stops[name])
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

        if type(message) == "table" and message.message == "DACK" and message.name and message.type then
            -- intersection or stop responded, addIntersection and set channel
            discoveryTime = 3
            -- log("D",  "< DACK from " .. message.name .. " (name: " .. message.name .. ") setting channel " .. channelCounter)
            if message.type == "intersection" then
                addIntersection(message.name, channelCounter)
            elseif message.type == "stop" then
                addStop(message.name, channelCounter)
            end
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
    log("I",  "Discovery done.")
end

local function discoverComponents()
    -- discover online stations and give them a communication channel
    parallel.waitForAny( -- if no answer within 3 seconds, done
        discoveryHelper,
        wait
    )

    local count = 0
    for _ in pairs(intersections) do count = count + 1 end
    log("D",  "I:".. serialize(intersections))
    log("D",  "S:".. serialize(stops))
end

discoverComponents()





modem.open(301)
log("I",  "Waiting for CC connection...")
local controllerChannel = nil
-- Wait for CC connection ---------------------------------
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")

    -- step 1
    if (message == "DISCOVERY") then
        log("D",  "< DISCOVERY")
        os.sleep(0.01)
        modem.transmit(replyChannel, 301, {message = "DACK", name = config.name})
        log("D",  "> D ACK (name: " .. config.name .. ")")

    -- step 2
    elseif (type(message) == "table" and message.message == "SETCHANNEL" and message.name == config.name) then
        log("D",  "< SETCHANNEL " .. message.channel)
        modem.open(message.channel)
        modem.close(301) -- close discovery channel
        controllerChannel = message.channel
        log("I",  " Opened channel " .. message.channel )
        log("I",  " Closed channel " .. 301 )
        break
    end
end



-- lan.transmit(intersections["I3"], 301, {name = "I3", direction = "left"})


local busyStops = {} -- stores busy stops to prevent double handling

local function handleArrival(message)
    log("I", "Handling arrival: ")
    for name, port in pairs(stops) do
        if busyStops[name] then
            log("I", "Stop " .. name .. " is busy.")
        else
            log("I", "Stop " .. name .. " is free, sending message.")
            for _, route in pairs(routing.routes[name]) do
                lan.transmit(intersections[route.name], 301, {
                    name = route.name,
                    direction = route.direction
                })

                log("D", "Sent: " .. serialize({
                    name = route.name,
                    direction = route.direction
                }))
            end
            busyStops[name] = true

            monitor.append({
                from = message.from,
                to = message.to,
                stops = message.stops,
                platform = name,
                ETA = message.eta
            })
            break
        end
    end
end

local function handleDeparture(message)
    log("I", "Handling departure: ")
end

log("I", "Setup ok, listening...")

monitor.init()
usingMonitor = false
os.sleep(1)

-- Station initialization
while true do

    local _, _, ch, _, message, _ = os.pullEvent("modem_message")

    if ch == controllerChannel then
        if type(message) == "table" and message.name == config.name then
            log("D", "(CC): " .. serialize(message))

            if message.type == "arr" then
                handleArrival(message)
            elseif message.type == "dep" then
                handleDeparture(message)
            end

        else
            log("W", "Received message but station does not care (not a table).")
            log("D", "Message: " .. serialize(message))
        end

    else
        -- component message
        if type(message) == "table" then
            log("D", "(C): " .. serialize(message))
            if message.type == "stop" then
                if message.stop then
                    log("D", "Stop " .. message.name .. " is now busy.")
                    busyStops[message.name] = true
                    monitor.arrived(message.name)
                else
                    log("D", "Stop " .. message.name .. " is now free.")
                    busyStops[message.name] = nil
                    monitor.departed(message.name)
                end
            end
        end

    end
end