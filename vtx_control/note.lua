local PARAM_TABLE_KEY = 55
local PARAM_PREFIX = "VTX_C_"
local LOOP_INTERVAL_MS = 1000
local VTX_CUSTOM_FREQ = "VTX_CUSTOM_FREQ"
local current_freq = 0
local pref_freq = 0
local count = 0

local PARAMS = {
	ENABLE = "ENABLE",
	CHANNEL = "CHANNEL",
	FREQ1 = "FREQ1",
	FREQ2 = "FREQ2",
	FREQ3 = "FREQ3",
	FREQ4 = "FREQ4",
	FREQ5 = "FREQ5",
	FREQ6 = "FREQ6"
}

local function get_param(key)
	return param:get(PARAM_PREFIX .. key)
end

local function loop()
	local enable = get_param(PARAMS.ENABLE) or 0

	if (enable ~= 1) then
		return loop, LOOP_INTERVAL_MS
	end

	local channel = get_param(PARAMS.CHANNEL) or nil

	if (channel == nil or channel < 5) then
		return loop, LOOP_INTERVAL_MS
	end

	local channelValue = rc:get_pwm(channel)
	local freq1 = get_param(PARAMS.FREQ1) or 0
	local freq2 = get_param(PARAMS.FREQ2) or 0
	local freq3 = get_param(PARAMS.FREQ3) or 0
	local freq4 = get_param(PARAMS.FREQ4) or 0
	local freq5 = get_param(PARAMS.FREQ5) or 0
	local freq6 = get_param(PARAMS.FREQ6) or 0

	if (channelValue == 0) then
		return loop, LOOP_INTERVAL_MS
	end

	if (channelValue < 1100 and freq1 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq1)
		current_freq = freq1
	end

	if (channelValue > 1100 and channelValue < 1300 and freq2 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq2)
		current_freq = freq2
	end

	if (channelValue > 1300 and channelValue < 1550 and freq3 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq3)
		current_freq = freq3
	end

	if (channelValue > 1550 and channelValue < 1700 and freq4 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq4)
		current_freq = freq4
	end

	if (channelValue > 1700 and channelValue < 1900 and freq5 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq5)
		current_freq = freq5
	end

	if (channelValue > 1900 and freq6 > 1) then
		param:set(VTX_CUSTOM_FREQ, freq6)
		current_freq = freq6
	end

	if (current_freq ~= pref_freq) then
		gcs:send_text(6, "VTX freq: " .. current_freq)
		pref_freq = current_freq
	end

	return loop, LOOP_INTERVAL_MS
end

local function init()
	if (count == 0) then
		gcs:send_text(6, "Init VTX RC control")

		assert(param:add_table(PARAM_TABLE_KEY, PARAM_PREFIX, 9), "could not add param table")
		param:add_param(PARAM_TABLE_KEY, 1, PARAMS.ENABLE, 0)
		param:add_param(PARAM_TABLE_KEY, 2, PARAMS.CHANNEL, 8)
		param:add_param(PARAM_TABLE_KEY, 3, PARAMS.FREQ1, 0)
		param:add_param(PARAM_TABLE_KEY, 4, PARAMS.FREQ2, 0)
		param:add_param(PARAM_TABLE_KEY, 5, PARAMS.FREQ3, 0)
		param:add_param(PARAM_TABLE_KEY, 6, PARAMS.FREQ4, 0)
		param:add_param(PARAM_TABLE_KEY, 7, PARAMS.FREQ5, 0)
		param:add_param(PARAM_TABLE_KEY, 8, PARAMS.FREQ6, 0)

		param:set(VTX_CUSTOM_FREQ, 0)

		count = 1

		return init, 1e3
	end

	if (count == 1) then
		gcs:send_text("6", "set init freq")
		local freq1 = get_param(PARAMS.FREQ1) or 0

		param:set(VTX_CUSTOM_FREQ, freq1)

		count = 2
		return init, 3e3
	end

	if (count == 2) then
		gcs:send_text("6", "Set post init freq")
		param:set(VTX_CUSTOM_FREQ, 0)

		count = 3
		return init, 3e3
	end

	if (count == 3) then
		return loop, 1e3
	end
end

return init, 10e3
