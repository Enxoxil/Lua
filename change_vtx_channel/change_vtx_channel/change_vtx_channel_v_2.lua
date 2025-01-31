--
-- @component control_vtx_parameters ver.2;
-- @description Control VTX channel and power lvl for MILELRS with
-- auto detection of the number of channels and power lvl;
-- @Author: @alex_jackson.01 (signal);
-- @For To use with MILELRS a couple of steps are required;
-- 				1) Enable option "VTX_CHANGE_EN" to 1;
-- 				2) Specify the Channel (aux) that will switch vtx,
-- 				in parameter "VTX_CHANGE_RC" from 6 to 16;
-- 				3) Specify the frequencies of the desired vtx channels
-- 				in the same order as specified in the MILELRS settings,
-- 				in parameters "FREQ1" to "FREQ8";
-- @end;
--

-- var START --
local TABLE_KEY = 52
local TABLE_PREFIX = "VTX_"
local LOOP_INTERVAL = 200
local VTX_FREQ = "VTX_FREQ"
local VTX_POWER = "VTX_POWER"
local RC_RANGE = 1010
local RC_channel = nil
local RC_plvl_channel = nil
local RC_channel_value = 0
local RC_plvl_value = 0
local prev_freq = 0
local prev_plvl = 0
local ch_range_step = 0
local plvl_range_step = 0
local is_init_vtx_freq = false
local is_add_param_table = false
local is_enable_vtx_control = false
local is_init_RC_channel = false
local is_init_boundaries = false
local is_init = false
local count = 0
local frequencies = {}
local plvls = {}
local chn_boundaries = {}
local plvl_boundaries = {}
local PARAMS = {
	CHANGE_ENABLE = "CTRL_EN",
	CHANNEL_RC = "CH_RC",
	PWRLVL = "PLVL_RC",
	FREQS = {
		"FREQ1",
		"FREQ2",
		"FREQ3",
		"FREQ4",
		"FREQ5",
		"FREQ6",
		"FREQ7",
		"FREQ8"
	},
	PWRLVLS = {
		"PLVL1",
		"PLVL2",
		"PLVL3",
		"PLVL4",
		"PLVL5",
		"PLVL6"
	}
}
-- var END --

-- main START --
local function loop()
	RC_channel_value = rc:get_pwm(RC_channel)
	RC_plvl_value = rc:get_pwm(RC_plvl_channel)

	for i, freq in ipairs(frequencies) do
		local lower_b = chn_boundaries[i].lower
		local upper_b = chn_boundaries[i].upper

		if RC_channel_value > lower_b and RC_channel_value <= upper_b then
			if freq ~= prev_freq then
				gcs:send_text(6, "Current VTX freq: " .. freq)
				prev_freq = freq
				param:set(VTX_FREQ, freq)
				break
			end
		end
	end

	for i, plvl in ipairs(plvls) do
		local lower_b = plvl_boundaries[i].lower
		local upper_b = plvl_boundaries[i].upper

		if RC_plvl_value > lower_b and RC_plvl_value <= upper_b then
			if plvl ~= prev_plvl then
				gcs:send_text(6, "Current VTX power lvl: " .. plvl)
				prev_plvl = plvl
				param:set(VTX_POWER, plvl)
				break
			end
		end
	end

	return loop, LOOP_INTERVAL
end
-- main END --

-- helpers START --
local function get_range_step(range, values)
	return range / values
end

local function set_boundaries(array, boundaries, step)
	local lower_bound = 0
	local upper_bound = 0

	for i, _ in ipairs(array) do
		lower_bound = 990 + (i - 1) * step
		upper_bound = lower_bound + step

		table.insert(boundaries, {lower = lower_bound, upper = upper_bound})
		gcs:send_text(6, i .. " - " .. lower_bound .. ", " .. upper_bound .. " Hz;")
	end
end
-- helpers END --

-- init START --
local function init()
	-- add param table

	if not is_add_param_table then
		gcs:send_text(6, " - * - * - * - * - * - * - * - * - * - * - * - ")
		gcs:send_text(6, " ")
		gcs:send_text(6, "0 : Initialize VTX control")
		gcs:send_text(6, " ")

		assert(param:add_table(TABLE_KEY, TABLE_PREFIX, 17), "The parameter table wasn`t created")
		param:add_param(TABLE_KEY, 1, PARAMS.CHANGE_ENABLE, 0)
		param:add_param(TABLE_KEY, 2, PARAMS.CHANNEL_RC, 0)
		param:add_param(TABLE_KEY, 3, PARAMS.FREQS[1], 0)
		param:add_param(TABLE_KEY, 4, PARAMS.FREQS[2], 0)
		param:add_param(TABLE_KEY, 5, PARAMS.FREQS[3], 0)
		param:add_param(TABLE_KEY, 6, PARAMS.FREQS[4], 0)
		param:add_param(TABLE_KEY, 7, PARAMS.FREQS[5], 0)
		param:add_param(TABLE_KEY, 8, PARAMS.FREQS[6], 0)
		param:add_param(TABLE_KEY, 9, PARAMS.FREQS[7], 0)
		param:add_param(TABLE_KEY, 10, PARAMS.FREQS[8], 0)
		param:add_param(TABLE_KEY, 11, PARAMS.PWRLVLS[1], 0)
		param:add_param(TABLE_KEY, 12, PARAMS.PWRLVLS[2], 0)
		param:add_param(TABLE_KEY, 13, PARAMS.PWRLVLS[3], 0)
		param:add_param(TABLE_KEY, 14, PARAMS.PWRLVLS[4], 0)
		param:add_param(TABLE_KEY, 15, PARAMS.PWRLVLS[5], 0)
		param:add_param(TABLE_KEY, 16, PARAMS.PWRLVLS[6], 0)
		param:add_param(TABLE_KEY, 17, PARAMS.PWRLVL, 0)
		is_add_param_table = true

		return init, 1000
	end

	-- check enable vtx control mode
	if not is_enable_vtx_control then
		local enable = param:get(TABLE_PREFIX .. PARAMS.CHANGE_ENABLE) or 0

		if enable == 1 then
			gcs:send_text(6, "1 : VTX control enable!")
			gcs:send_text(6, " ")
			is_enable_vtx_control = true
			return init, 1000
		end

		if enable == 0 and count < 5 then
			count = count + 1
			return init, 100
		elseif enable == 0 and count >= 5 then
			gcs:send_text(6, "1 : VTX control disabled!")
			gcs:send_text(6, " ")
			return
		end
		return init, 100
	end

	-- set init freq
	if (is_add_param_table and is_enable_vtx_control) and not is_init_vtx_freq then
		local init_freq = param:get(TABLE_PREFIX .. PARAMS.FREQS[1]) or 0
		if init_freq > 0 then
			gcs:send_text(6, "2 : Set init freq ... " .. init_freq)
			param:set(VTX_FREQ, init_freq)
			is_init_vtx_freq = true
			gcs:send_text(6, "2 : Done! ")
			gcs:send_text(6, " ")
			return init, 100
		end
	end

	-- set RC channel
	if not is_init_RC_channel then
		RC_channel = param:get(TABLE_PREFIX .. PARAMS.CHANNEL_RC) or nil
		RC_plvl_channel = param:get(TABLE_PREFIX .. PARAMS.PWRLVL) or nil
		if RC_channel == nil or RC_channel < 6 then
			gcs:send_text(6, "3 : VTX RC channel not found!")
			gcs:send_text(6, " ")
			return init, 100
		end
		if RC_plvl_channel == nil or RC_plvl_channel < 6 then
			gcs:send_text(6, "3 : VTX plvl RC channel not found!")
			gcs:send_text(6, " ")
			return init, 100
		end
		gcs:send_text(6, "3 : Set RC channel ... " .. RC_channel)
		gcs:send_text(6, "3 : Set plvl RC channel ... " .. RC_plvl_channel)
		gcs:send_text(6, "3 : Done!")
		gcs:send_text(6, " ")
		is_init_RC_channel = true
		return init, 100
	end

	if not is_init then
		gcs:send_text(6, "4: Set RC range ... ")
		for _, paramName in ipairs(PARAMS.FREQS) do
			local freq = param:get(TABLE_PREFIX .. paramName) or 0
			if freq > 1 then
				table.insert(frequencies, freq)
			end
		end

		for _, paramName in ipairs(PARAMS.PWRLVLS) do
			local plvl = param:get(TABLE_PREFIX .. paramName) or 0
			if plvl > 1 then
				table.insert(plvls, plvl)
			end
		end

		ch_range_step = get_range_step(RC_RANGE, #frequencies)
		plvl_range_step = get_range_step(RC_RANGE, #plvls)

		gcs:send_text(6, "4 : Done!")
		gcs:send_text(6, " ")
		is_init = true
		return init, 100
	end

	if not is_init_boundaries then
		gcs:send_text(6, "5 : Create boundaries table ... ")
		gcs:send_text(6, " ")
		gcs:send_text(6, " - - - - - - - - - - - - - - - -")

		set_boundaries(frequencies, chn_boundaries, ch_range_step)

		gcs:send_text(6, " ")
		gcs:send_text(6, " - - - - - - - - - - - - - - - -")
		gcs:send_text(6, " ")

		set_boundaries(plvls, plvl_boundaries, plvl_range_step)

		gcs:send_text(6, " - - - - - - - - - - - - - - - -")
		gcs:send_text(6, " ")
		gcs:send_text(6, "5 : Done!")
		gcs:send_text(6, " ")
		is_init_boundaries = true
		gcs:send_text(6, "Initialize complete!!!")
		gcs:send_text(6, " - * - * - * - * - * - * - * - * - * - * - * - ")
		gcs:send_text(6, " ")
		return loop, LOOP_INTERVAL
	end
end
return init, 100
-- init END --
