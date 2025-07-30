return {
    name = "I2",

    -- Sides where sensors are connected (detect minecart presence)
    sensors = {
        left = "left",    -- sensor for left rail
        right = "front",  -- sensor for right rail
        entry = "back",   -- sensor for entry rail
    },

    signal_goes_right = false, -- does a redstone signal make the rail go to the right?

    -- Side where the relay output is connected (controls the rail switch)
    relay_output = "top",

    -- Station controller channel or ID (for communication)
    controller_channel = 302,
}