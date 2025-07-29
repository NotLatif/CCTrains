return {
    name = nil, -- give a UNIQUE NAME (UNIQUE TO THE STATION) (can be any string)

    -- Sides where detector rails are connected (detect minecart presence)
    sensors = {
        left = "front",    -- sensor for left rail
        right = "back",  -- sensor for right rail
        entry = "left",   -- sensor for entry rail
    },

    go_right = false, -- is a redstone signal needed to go right?

    -- Side where the relay output is connected (controls the rail switch)
    relay_output = "top",

    -- Station controller channel or ID (for communication)
    controller_channel = 302,
}