
-- THE MODEM CONNECTED TO THE STATION MUST BE IN THE BACK SIDE
-- the intersection redstone relay can be on any other side
-- only one relay is allowed.
-- relay output is FRONT (where the face is)

-- we use 2 modems to avoid lan pollution/interfeerence with other intersections
-- one intersection computer is needed for every junction due to computercraft limitation
local config = require "config"
local Queue = require "queue"
print("Intersection: " .. config.name)

local log = fs.open("intersection.log", "w")

-- find out who's the modem-modem
local modem = peripheral.wrap("back") or print("ERROR, no station modem found (back side)")
if modem == nil then return end

local redstone, x = peripheral.find("redstone_relay")

if redstone == nil then print("ERROR - no redstone_relay found") end
if x ~= nil then print("ERROR - only one redstone_relay allowed") end
if redstone == nil or x ~= nil then return end

-- find station
modem.closeAll()
modem.open(config.controller_channel)

local stationChannel = nil
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")

    -- step 1
    if (message == "DISCOVERY") then
        print("< > DISCOVERY EXCHANGE")
        modem.transmit(replyChannel, config.controller_channel, {message = "DACK", name = config.name})
        stationChannel = replyChannel

    -- step 2
    elseif (type(message) == "table" and message.message == "SETCHANNEL" and message.name == config.name) then
        print("< SETCHANNEL " .. message.channel)
        modem.open(message.channel)
        modem.close(config.controller_channel) -- close discovery channel
        print('[I] Opened channel ' .. message.channel )
        print('[I] Closed channel ' .. config.controller_channel )
        break
    end
end


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



local function handleIntersection(direction)
    if direction == "left" then
        if (config.signal_goes_right) then
            redstone.setOutput(config.relay_output, false)
        else
            redstone.setOutput(config.relay_output, true)
        end
    elseif direction == "right" then
        if (config.signal_goes_right) then
            redstone.setOutput(config.relay_output, true)
        else
            redstone.setOutput(config.relay_output, false)
        end
    else
        print("[E] - invalid dir received from station", serialize(direction))
    end
end


local messageQueue = Queue.new()
local minecartTraversing = false
-- now we wait.
while true do
    ::continue::
    local e, _, ch, _, message, _ = os.pullEvent()

    if e == "modem_message" then
        if message.name ~= config.name then
            print("[E] - received message on private communication but name did not match")
            print("[D] - channel" .. ch .. " name: " .. message.name)
            goto continue
        end

        if not message.direction then
            print("[E] - received message without direction")
            print("[D] - channel" .. ch .. " message: " .. serialize(message))
            goto continue
        end

        --
        -- print("[D] (incoming): " .. textutils.serialize(message))
        --

        if not minecartTraversing then
            if messageQueue:size() == 0 then
                -- minecart might not be traversing, but since the queue is empty we set up the rail beforehand
                -- we set minecartTraversing to true so if the cart is actually outside it does not trigger
                -- a dequeue when it enters
                print("{Q*}: ", serialize(message))
                handleIntersection(message.direction)

                minecartTraversing = true
            else
                -- enqueue message for the next cart
                print("{Q+}: ", serialize(message))
                messageQueue:enqueue(message)
            end

        else
            -- minecart is traversing, we enqueue the message
            print("{Q+}: ", serialize(message))
            messageQueue:enqueue(message)
        end

    elseif e == "redstone" then
        -- log.writeLine("queue" .. textutils.serialize(messageQueue))
        -- we assume there is enough time between carts so that
        -- all signals are off by the time the next cart passes
        if redstone.getInput(config.sensors.entry) == true then
            print("  [Dr] - entry sensor triggered")
            minecartTraversing = true
        end

        if minecartTraversing then
            if redstone.getInput(config.sensors.left) == true or redstone.getInput(config.sensors.right) == true then
                minecartTraversing = false
    
                -- set up track for next cart
                if (messageQueue:isEmpty()) then
                    print("  [Dr]: queue empty, waiting for next cart")
                else
                    message = messageQueue:dequeue()
                    print("  [Dr] - setting up for next cart: ")
                    print("{Q-}: ", serialize(message))
                    handleIntersection(message.direction)
                    os.sleep(0.2)  -- give time for the signals to turn off
                end
            end
        end

    end
end