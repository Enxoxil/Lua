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

local vtx_freq_for_first_value_rc = nil;
local vtx_freq_for_second_value_rc = nil;
local vtx_freq_for_third_value_rc = nil;
local vtx_freq_for_fourth_value_rc = nil;
local vtx_freq_for_fifth_value_rc = nil;

local aux_for_change_VTX_channel = nil;
local RC_state = nil;
local button_counter = 0;

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

local function set_vtx_channel(freq)
	if freq then
		param:set('VTX_FREQ', freq);
	else
		gcs:send_text(0, "Error: band or channel is nil");
	end;
end;

function update()
	local state_switch_pwm = rc:get_pwm(aux_for_change_VTX_channel);
	local current_freq = nil;

	if (RC_state ~= state_switch_pwm) then
		if state_switch_pwm > 800 and state_switch_pwm < 1301 then
			current_freq = vtx_freq_for_first_value_rc;
			set_vtx_channel(current_freq);

		elseif state_switch_pwm > 1300 and state_switch_pwm < 1801 then
			current_freq = vtx_freq_for_second_value_rc;
			set_vtx_channel(current_freq);

		elseif state_switch_pwm > 1800 and state_switch_pwm < 2200 then
			current_freq = vtx_freq_for_third_value_rc;
			set_vtx_channel(current_freq);
	
		else
			gcs:send_text(0, "PWM out of expected range");
		end;
	end
	RC_state = state_switch_pwm;
	
	return update, 100;
end;

-- initialize_parameters with delay
return initialize_parameters();
