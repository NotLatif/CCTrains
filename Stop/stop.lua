-- script that handles train stops
local config = require "config"
print("Stop: " .. config.name)

local modem = peripheral.find("modem") or print("ERROR, no modem found")
if modem == nil then return end

modem.closeAll()
modem.open(302)

local stationChannel = nil
while true do
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")

    -- step 1
    if (message == "DISCOVERY") then
        print("< > DISCOVERY EXCHANGE")
        modem.transmit(replyChannel, 302, {message = "DACK", name = config.name, type = "stop"})
        stationChannel = replyChannel

    -- step 2
    elseif (type(message) == "table" and message.message == "SETCHANNEL" and message.name == config.name) then
        print("< SETCHANNEL " .. message.channel)
        modem.open(message.channel)
        modem.close(302) -- close discovery channel
        print('[I] Opened channel ' .. message.channel )
        print('[I] Closed channel 302' )
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

while true do
    local e, _, ch, _, message, _ = os.pullEventRaw()

    if e == "modem_message" then
        if type(message) == "table" then
            print("Received message but stop does not care.")
            print("- Message: " .. serialize(message))
        end
   
    elseif e == "redstone" then
        if redstone.getInput("top") then
            -- minecart entered stop
            print("Minecart entered stop: " .. config.name)
            redstone.setOutput("back", false) -- stop cart
            modem.transmit(stationChannel, 302, {stop = true, name = config.name, type = "stop"})

            os.sleep(config.stopping_time) -- wait for configured seconds before allowing the cart to leave
            redstone.setOutput("back", true) -- allow cart to leave
            modem.transmit(stationChannel, 302, {stop = false, name = config.name, type = "stop"})
            print("Minecart left stop: " .. config.name)
            
            os.sleep(1) -- set up for next cart
            redstone.setOutput("back", false) -- reset output
        end
    end


end