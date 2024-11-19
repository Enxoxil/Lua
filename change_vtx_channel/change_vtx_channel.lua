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

local frequencies = {first_freq, second_freq, third_freq, fourth_freq, fifth_freq};

local aux_for_change_VTX_channel = nil;
local RC_state = nil;
local current_channel_index = 1;
local last_button_state = 0;

local function initialize_parameters()
	-- get parameters
	frequencies[first_freq] = param:get('SCR_USER1');
	frequencies[second_freq] = param:get('SCR_USER1');
	frequencies[third_freq] = param:get('SCR_USER1');
	frequencies[fourth_freq] = param:get('SCR_USER1');
	frequencies[fifth_freq] = param:get('SCR_USER1');
	aux_for_change_VTX_channel = param:get('SCR_USER6');

	-- Check if parameters are loaded
	if not frequencies[first_freq] or not frequencies[second_freq] or not frequencies[third_freq] or not frequencies[fourth_freq] or not frequencies[fifth_freq] or not aux_for_change_VTX_channel then
		gcs:send_text(0, "Error: One or more parameters not loaded. Retrying...");
		return initialize_parameters, 1000;
	else
		gcs:send_text(0, "Parameters loaded successfully.");
		return update, 100;
	end
end;

local function get_vtx_channel(table, index)
	return table[index];
end;

local function set_vtx_channel(freq)
	if freq then
		param:set('VTX_FREQ', freq);
	else
		gcs:send_text(0, "Error: band or channel is nil");
	end;
end;

function update()
	local button_state = rc:get_pwm(aux_for_change_VTX_channel);
	local current_freq = nil;

	if button_state and button_state > 1500 and last_button_state <= 1500 then
		if (current_channel_index == 5) then 
			current_channel_index = 1
			set_vtx_channel(get_vtx_channel(frequencies, current_channel_index))
		else 
			current_channel_index = current_channel_index + 1;
			set_vtx_channel(get_vtx_channel(frequencies, current_channel_index))
		end
	end

		last_button_state = button_state or 0;

	return update, 100;
end;

-- initialize_parameters with delay
return initialize_parameters();
