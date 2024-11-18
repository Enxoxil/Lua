local rangefinder_alt = {};

function rangefinder_alt.get_alt()
	local rngfnd_distance_m = 0;

	if (rangefinder:has_data_orient() and rangefinder:healthy()) then
			rngfnd_distance_m = rangefinder:distance_cm_orient() * 0.01;
	else 
			rngfnd_distance_m = 0;
	end
	return rngfnd_distance_m;
end

return rangefinder_alt;