--
-- @component change_vtx_channel ver.2;
-- @description Change VTX channel for MILELRS with
-- auto detection of the number of channels;
-- @Author: @alex_jackson.01 (signal);
-- @For To use with MILELRS a couple of steps are required;
-- 				1) Enable option "VTX_CHANGE_ENABLE" to 1;
-- 				2) Specify the Channel (aux) that will switch vtx,
-- 				in parameter "VTX_CHANGE_RC" from 5 to 16;
-- 				3) Specify the frequencies of the desired vtx channels
-- 				in the same order as specified in the MILELRS settings,
-- 				in parameters "FREQ1" to "FREQ8";
-- @end;
--

-- consts START --
local TABLE_KEY = 11
local TABLE_PREFIX = "VTX_CHANGE"
local LOOP_INTERVAL = 500
local VTX_FREQ = "VTX_FREQ"
local RC_RANGE = 1000
-- consts END --

-- var START --
local RC_channel = nil
local frequencies = {}
local RC_channel_value = 0
local current_freq = 0
local pref_freq = 0
local is_add_param_table = false
local is_init_vtx_freq = false
local range_step = 0
local enable = 0
local is_enable = false
local is_init_RC_channel = false
local PARAMS = {
	VTX_CHANGE_ENABLE = "VTX_CHANGE_ENABLE",
	VTX_CHANNEL_RC = "VTX_CHANGE_RC",
	FREQS = {
		"FREQ1",
		"FREQ2",
		"FREQ3",
		"FREQ4",
		"FREQ5",
		"FREQ6",
		"FREQ7",
		"FREQ8"
	}
}
-- var END --

-- main START --
local function loop()
	RC_channel_value = rc:get_pwm(RC_channel)
	if RC_channel_value == 0 then
		return loop, LOOP_INTERVAL
	end

	for i, freq in ipairs(frequencies) do
		local lowerBound = 1000 + (i - 1) * range_step
		local upperBound = lowerBound + range_step

		if RC_channel_value > lowerBound and RC_channel_value <= upperBound then
			param:set(VTX_FREQ, freq)
			current_freq = freq
			break
		end
	end

	if current_freq ~= pref_freq then
		gcs:send_text(6, "Current VTX freq: " .. current_freq)
		pref_freq = current_freq
	end

	return loop, LOOP_INTERVAL
end

-- main END --

-- init START --
local function init()
	-- add param table

	local count = 0
	if not is_add_param_table then
		gcs:send_text(6, "Initialize VTX control")

		assert(param:add_table(TABLE_KEY, TABLE_PREFIX, 10), "The parameter table wasn`t created")
		param:add_param(TABLE_KEY, 1, PARAMS.VTX_CHANGE_ENABLE, 0)
		param:add_param(TABLE_KEY, 2, PARAMS.VTX_CHANNEL_RC, 0)
		param:add_param(TABLE_KEY, 3, PARAMS.FREQ1, 0)
		param:add_param(TABLE_KEY, 4, PARAMS.FREQ2, 0)
		param:add_param(TABLE_KEY, 5, PARAMS.FREQ3, 0)
		param:add_param(TABLE_KEY, 6, PARAMS.FREQ4, 0)
		param:add_param(TABLE_KEY, 7, PARAMS.FREQ5, 0)
		param:add_param(TABLE_KEY, 8, PARAMS.FREQ6, 0)
		param:add_param(TABLE_KEY, 9, PARAMS.FREQ7, 0)
		param:add_param(TABLE_KEY, 10, PARAMS.FREQ8, 0)

		is_add_param_table = true

		return init, 2000
	end

	-- check enable vtx channel change mode
	if not is_enable then
		enable = get_param(PARAMS.VTX_CHANGE_ENABLE) or 0

		if enable == 0 and count < 10 then
			count = count + 1
			return init, 1000
		else if enable == 0 and count >= 10 then
			gcs:send_text(6, "VTX control disabled")
		end
		
		is_enable = true
		return init, 1000
	end

	-- set init freq
	if (is_add_param_table and is_enable) then
		gcs:send_text(6, "Set init freq")
		local init_freq = get_param(PARAMS.FREQ1) or 0
		param:set(VTX_FREQ, init_freq)

		is_init_vtx_freq = true
		return init, 1000
	end

	-- set RC channel
	if (is_init_vtx_freq) then
		RC_channel = get_param(PARAMS.VTX_CHANNEL_RC) or nil
		if RC_channel == nil or RC_channel < 5 then
			gcs:send_text(6, "VTX channel not found")
			return init, 1000
		end
		is_init_RC_channel = true
		return init, 1000
	end

	if (is_init_RC_channel) then
		for _, paramName in ipairs(PARAMS.FREQS) do
			local freq = get_param(paramName) or 0
			if freq > 1 then
				table.insert(frequencies, freq)
			end
		end

		if #frequencies == 0 then
			return init, 1000
		end

		range_step = RC_RANGE / #frequencies
	end
	return loop, LOOP_INTERVAL
end
return init, 2000

-- init END --
