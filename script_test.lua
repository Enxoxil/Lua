
function test_function()
	local RC_10 = rc:get_pwm(10)
	if arming:is_armed() and (RC_10 == 1500) then
		gcs:send_text(0,"BooooM activated!")
		gpio:pinMode(11,1)
		gpio:write(11,1)
	end
	return test_function(), 100
end