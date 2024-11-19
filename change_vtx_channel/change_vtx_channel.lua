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

local first_freq = nil;
local second_freq = nil;
local third_freq = nil;
local fourth_freq = nil;
local fifth_freq = nil;

local frequencies = {};

local aux_for_change_VTX_channel = nil;
local RC_state = nil;

local function initialize_parameters()
	-- get parameters
	frequencies[1] = param:get('SCR_USER1');
	frequencies[2] = param:get('SCR_USER1');
	frequencies[3] = param:get('SCR_USER1');
	frequencies[4] = param:get('SCR_USER1');
	frequencies[5] = param:get('SCR_USER1');

	aux_for_change_VTX_channel = param:get('SCR_USER6');

	-- Check if parameters are loaded
	if not frequencies[first_freq] or not frequencies[second_freq] or not frequencies[third_freq] or not frequencies[fourth_freq] or not frequencies[fifth_freq] or not aux_for_change_VTX_channel  then
		gcs:send_text(0, "Error: One or more parameters not loaded. Retrying...");
		return initialize_parameters, 1000;
	else
		gcs:send_text(0, "Parameters loaded successfully.");
		return update, 100;
	end
end;

local function get_vtx_channel(index)
	return frequencies[index]
end

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

	if RC_state ~= state_switch_pwm then
		if state_switch_pwm > 999 and state_switch_pwm < 1201 then
			set_vtx_channel(get_vtx_channel(1))
		elseif state_switch_pwm > 1200 and state_switch_pwm < 1401 then
			set_vtx_channel(get_vtx_channel(2))
		elseif state_switch_pwm > 1400 and state_switch_pwm < 1601 then
			set_vtx_channel(get_vtx_channel(3))
		elseif state_switch_pwm > 1600 and state_switch_pwm < 1801 then
			set_vtx_channel(get_vtx_channel(4))
		elseif state_switch_pwm > 1800 and state_switch_pwm < 2001 then
			set_vtx_channel(get_vtx_channel(5))
		else
			gcs:send_text(0, "PWM out of expected range")
		end
		RC_state = state_switch_pwm
	end
	
	return update, 100;
end;

-- initialize_parameters with delay
return initialize_parameters();
