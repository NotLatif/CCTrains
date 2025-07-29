
-- THE MODEM CONNECTED TO THE STATION MUST BE IN THE BACK SIDE
-- the intersection redstone relay can be on any other side
-- only one relay is allowed.
-- relay output is FRONT (where the face is)

-- we use 2 modems to avoid lan pollution/interfeerence with other intersections
-- one intersection computer is needed for every junction due to computercraft limitation
local config = require "config"
local Queue = require "queue"
print("Intersection: " .. config.name)

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



local function handleIntersection(direction)
    if direction == "left" then
        local active = config.go_right and true or false
        redstone.setOutput(config.relay_output, active)

    elseif direction == "right" then
        local active
        if config.go_right then active = false
        else active = true end

        redstone.setOutput(config.relay_output, active)
    else
        print("[E] - invalid dir received from station", textutils.serialize(direction))
    end

    return
end


local messageQueue = Queue.new()
local minecartTraversing = false
-- now we wait.
while true do
    ::continue::
    local e, _, ch, _, message, _ = os.pullEvent()

    if e == "modem_message" then
        if message.name ~= config.name then
            print("ERROR - received message on private communication but name did not match")
            print("DEBUG - channel" .. ch .. " name: " .. message.name)
            goto continue
        end

        --
        print("[D] (incoming): " .. textutils.serialize(message))
        --

        if not minecartTraversing then
            
            if messageQueue:size() == 0 then
                print("bypassing queue as there is only 1 message and track is empty")
                handleIntersection(message.direction)

                minecartTraversing = true
            else
                print("{Q +}: ", textutils.serialize(message))
                messageQueue:enqueue(message)
            end

        else
            print("{Q +}: ", textutils.serialize(message))
            messageQueue:enqueue(message)
        end

    elseif e == "redstone" then
        -- we assume there is enough time between carts so that
        -- all signals are off by the time the next cart passes
        if not minecartTraversing then
            if redstone.getInput(config.entry) == true then
                minecartTraversing = true
                message = messageQueue:dequeue()
                print("{Q -}: ", textutils.serialize(message))
                handleIntersection(message.direction)
            end

            if redstone.getInput(config.left) or redstone.getInput(config.right) then
                minecartTraversing = false
            end
        end
    end
end