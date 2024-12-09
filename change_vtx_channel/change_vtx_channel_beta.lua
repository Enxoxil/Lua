--
-- @component change_vtx_channel ver.2
-- @description Change VTX channel for MILELRS with slider
-- @Author: @alex_jackson.01 (signal)
-- For To use with MILELRS a couple of steps are required.
-- 1) Specify the Channel (aux) that will switch vtx, in parameter SCR_USER6
-- 2) Specify the frequencies of the desired vtx channels in the same order as
-- specified in the MILELRS settings, in parameters SCR_USER1 to SCR_USER5.
-- @end
--

local TABLE_KEY = 11
local TABLE_PREFIX = "VTX_CHANNEL"
local LOOP_INTERVAL = 1000
local isAddParamTable = false
local isCheckParamTable = false

local PARAMS = {
	ENABLE = "ENABLE",
	CHANNEL = "CHANNEL",
	FREQUENCIES = {
		"FREQ1",
		"FREQ2",
		"FREQ3",
		"FREQ4",
		"FREQ5",
		"FREQ6"
	}
}

local function loop()
	local enable = get_param(PARAMS.ENABLE) or 0

	if enable ~= 1 then
		return loop, LOOP_INTERVAL_MS
	end

	local channel = get_param(PARAMS.CHANNEL) or nil

	if channel == nil or channel < 5 then
		return loop, LOOP_INTERVAL_MS
	end

	local channelValue = rc:get_pwm(channel)
	if channelValue == 0 then
		return loop, LOOP_INTERVAL_MS
	end

	-- Получаем доступные частоты
	local frequencies = {}
	for _, paramName in ipairs(PARAMS.FREQUENCIES) do
		local freq = get_param(paramName) or 0
		if freq > 1 then
			table.insert(frequencies, freq)
		end
	end

	-- Проверяем, есть ли доступные частоты
	if #frequencies == 0 then
		return loop, LOOP_INTERVAL_MS
	end

	-- Разделяем диапазон на количество частот
	local rangeStep = 800 / #frequencies -- Диапазон PWM от 1100 до 1900 = 800

	for i, freq in ipairs(frequencies) do
		local lowerBound = 1100 + (i - 1) * rangeStep
		local upperBound = lowerBound + rangeStep

		if channelValue > lowerBound and channelValue <= upperBound then
			param:set(VTX_CUSTOM_FREQ, freq)
			current_freq = freq
			break
		end
	end

	if current_freq ~= pref_freq then
		gcs:send_text(6, "VTX freq: " .. current_freq)
		pref_freq = current_freq
	end

	return loop, LOOP_INTERVAL_MS
end
