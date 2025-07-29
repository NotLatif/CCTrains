-- timetable, contains department time for stations
local timetable = {
    ["7:00"] = {
        {
            dep = "S1",
            arr = "S5",
            stops = {
                "S3", "S4"
            },
            intersections = {
                ["I3"] = true,
                ["I5"] = false
            }
        }
    }
}




local function getHourMinute()
    local timeStr = textutils.formatTime(os.time(), true)

    local hour, minute = timeStr:match("^(%d+):(%d+)$")
    -- hour = tonumber(hour)
    -- minute = tonumber(minute)

    if not hour or not minute then
        print("Failed to parse time string: " .. timeStr)
        return nil, nil
    end

    return hour, minute
end

-- while true do
--     local h, m = getHourMinute()
--     if h and m then
--         print(h .. ":" .. m)
--     else
--         print("Failed to parse time")
--     end

--     os.sleep(0) --yield
-- end

return {timetable = timetable, getHourMinute = getHourMinute}