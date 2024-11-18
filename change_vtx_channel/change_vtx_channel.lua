-- 
-- @component change_vtx_channel
-- @description Change VTX channel
-- @Author: @moishe_rubinstein.01 (signal)
-- For To use with MILELRS a couple of steps are required.
-- 1) Specify the Channel (aux) that will switch vtx, in parameter SCR_USER6
-- 2) Specify the frequencies of the desired vtx channels in the same order as
-- specified in the MILELRS settings, in parameters SCR_USER1 to SCR_USER5.
-- A maximum of 5 channels can be switched.
-- @end
-- 



local frequency_map = {
	-- Band X = 8 
	[4990] = { 8, 0 }, [5020] = { 8, 1 }, [5050] = { 8, 2 },
	[5080] = { 8, 3 }, [5110] = { 8, 4 }, [5140] = { 8, 5 },
	[5170] = { 8, 6 }, [5200] = { 8, 7 },

	-- Band R = 4
	[5658] = { 4, 0 }, [5695] = { 4, 1 }, [5732] = { 4, 2 },
	[5769] = { 4, 3 }, [5806] = { 4, 4 }, [5843] = { 4, 5 },
	[5880] = { 4, 6 }, [5917] = { 4, 7 },
};

local vtx_freq_for_first_value_rc = nil;
local vtx_freq_for_second_value_rc = nil;
local vtx_freq_for_third_value_rc = nil;
local vtx_freq_for_fourth_value_rc = nil;
local vtx_freq_for_fifth_value_rc = nil;

local aux_for_change_VTX_channel = nil;
local RC_state = nil;

local function initialize_parameters()
	-- get parameters
	vtx_freq_for_first_value_rc = param:get('SCR_USER1');
	vtx_freq_for_second_value_rc = param:get('SCR_USER2');
	vtx_freq_for_third_value_rc = param:get('SCR_USER3');
	vtx_freq_for_fourth_value_rc = param:get('SCR_USER4');
	vtx_freq_for_fifth_value_rc = param:get('SCR_USER5');
	aux_for_change_VTX_channel = param:get('SCR_USER6');

	-- Check if parameters are loaded
	if not vtx_freq_for_first_value_rc or not vtx_freq_for_second_value_rc or not vtx_freq_for_third_value_rc or not vtx_freq_for_fourth_value_rc or not vtx_freq_for_fifth_value_rc or not aux_for_change_VTX_channel then
		gcs:send_text(0, "Error: One or more parameters not loaded. Retrying...");
		return initialize_parameters, 1000;
	else
		gcs:send_text(0, "Parameters loaded successfully.");
		return update, 100;
	end
end;

local function get_vtx_channel(freq, map)
	return map[freq];
end;

local function set_vtx_channel(band, channel, freq)
	if band and channel then
		-- param:set('VTX_BAND', band);
		-- param:set('VTX_CHANNEL', channel);
		param:set('VTX_FREQ', freq);
	else
		gcs:send_text(0, "Error: band or channel is nil");
	end;
end;

function update()
	local data = nil;
	local state_switch_pwm = rc:get_pwm(aux_for_change_VTX_channel);
	local current_freq = nil;

	if (RC_state ~= state_switch_pwm) then
		if state_switch_pwm > 800 and state_switch_pwm < 1301 then
		data = get_vtx_channel(vtx_freq_for_first_value_rc, frequency_map);
		current_freq = vtx_freq_for_first_value_rc;
		elseif state_switch_pwm > 1300 and state_switch_pwm < 1801 then
		data = get_vtx_channel(vtx_freq_for_second_value_rc, frequency_map);
		current_freq = vtx_freq_for_second_value_rc;
		elseif state_switch_pwm > 1800 and state_switch_pwm < 2200 then
		data = get_vtx_channel(vtx_freq_for_third_value_rc, frequency_map);
		current_freq = vtx_freq_for_third_value_rc;
		else
		gcs:send_text(0, "PWM out of expected range");
		end;

		if data then
			set_vtx_channel(data[1], data[2], current_freq);
		else
			gcs:send_text(0, "Error: Frequency not found in frequency_map for selected range");
		end;
	end
	RC_state = state_switch_pwm;
	
	return update, 100;
end;

-- initialize_parameters with delay
return initialize_parameters();
