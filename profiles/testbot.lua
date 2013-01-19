-- Testbot profile

-- Moves at fixed, well-known speeds, practical for testing speed and travel times:

-- Primary road:	36km/h = 36000m/3600s = 100m/10s
-- Secondary road:	18km/h = 18000m/3600s = 100m/20s
-- Tertiary road:	12km/h = 12000m/3600s = 100m/30s

speed_profile = { 
	["primary"] = 36,
	["secondary"] = 18,
	["tertiary"] = 12,
	["default"] = 24
}

-- these settings are read directly by osrm

take_minimum_of_speeds 	= true
obey_oneway 			= true
obey_bollards 			= true
use_restrictions 		= true
ignore_areas 			= true	-- future feature
traffic_signal_penalty 	= 7		-- seconds
u_turn_penalty 			= 20

function limit_speed(speed, limits)
    -- don't use ipairs(), since it stops at the first nil value
    for i=1, #limits do
        limit = limits[i]
        if limit ~= nil and limit > 0 then
            if limit < speed then
                return limit        -- stop at first speedlimit that's smaller than speed
            end
        end
    end
    return speed
end

function node_function (node)
	local traffic_signal = node.tags:Find("highway")

	if traffic_signal == "traffic_signals" then
		node.traffic_light = true;
		-- TODO: a way to set the penalty value
	end
	return 1
end

function way_function (way, numberOfNodesInWay)
	-- A way must have two nodes or more
	if(numberOfNodesInWay < 2) then
		return 0;
	end
	
	local highway = way.tags:Find("highway")
	local name = way.tags:Find("name")
	local oneway = way.tags:Find("oneway")
	local route = way.tags:Find("route")
	local duration = way.tags:Find("duration")
    local maxspeed = tonumber(way.tags:Find ( "maxspeed"))
    local maxspeed_forward = tonumber(way.tags:Find( "maxspeed:forward"))
    local maxspeed_backward = tonumber(way.tags:Find( "maxspeed:backward"))
	
	print('---')
	print(name)
	print(tostring(maxspeed))
	print(tostring(maxspeed_forward))
	print(tostring(maxspeed_backward))
	
	way.name = name

  	if route ~= nil and durationIsValid(duration) then
		way.ignore_in_grid = true
		way.speed = math.max( 1, parseDuration(duration) / math.max(1, numberOfNodesInWay-1) )
	 	way.is_duration_set = true
	else
		way.speed = speed_profile[highway] or speed_profile['default']

    	if highway == "river" then
    		local temp_speed = way.speed;
    		way.speed = temp_speed*3/2
    		way.backward_speed = temp_speed*2/3
    	else
    	    way.backward_speed = way.speed
    	end
        
        way.speed = limit_speed( way.speed, {maxspeed_forward, maxspeed} )
        way.backward_speed = limit_speed( way.backward_speed, {maxspeed_backward, maxspeed} )

    	-- print( 'limit forw: '  .. tostring(way.speed))
    	-- print( 'limit back: '  .. tostring(way.backward_speed))
	end
	
	if oneway == "no" or oneway == "0" or oneway == "false" then
		way.direction = Way.bidirectional
	elseif oneway == "-1" then
		way.direction = Way.opposite
	elseif oneway == "yes" or oneway == "1" or oneway == "true" then
		way.direction = Way.oneway
	else
		way.direction = Way.bidirectional
	end
	
	way.type = 1
	return 1
end
