

local routes = {
    ["B1"] = {
        {name = "I3", direction = "left"},
        {name = "I2", direction = "left"},
    },
    ["B2"] = {
        {name = "I3", direction = "left"},
        {name = "I2", direction = "right"},
        {name = "I1", direction = "left"},
    },
    ["B3"] = {
        {name = "I3", direction = "left"},
        {name = "I2", direction = "right"},
        {name = "I1", direction = "right"},
    },
    ["B4"] = {
        {name = "I3", direction = "right"},
    }
}


return {
    routes = routes
}