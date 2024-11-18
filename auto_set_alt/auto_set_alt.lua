
local rangefinder_alt = require("rangefinder_alt") 
-- Import rangefinder_alt.lua script

local isAtivatedAutoMode = false;
-- Flag activate for automatic mode

gcs:send_text(0,"Auto mode activated!");
-- Script for automatic mode with lidar or GPS or Barometer

local rangefinder_thresh_dist = param:get('RNGFND1_MAX_CM') * 0.01;
-- max distance for rangefinder to activate

function activatedAutoMode()
    vehicle:set_mode("LOITER");
end;

function update()
    local rangefinder_dist_trigger = 0;
    local current_rangefinder_alt = 0;
    local getActivatedAutoMode = rc:get_pwm(7);

    if (getActivatedAutoMode == 2000) then
        isAtivatedAutoMode = true;
    else
        isAtivatedAutoMode = false;
    end;
    


    current_rangefinder_alt = rangefinder_alt.get_alt();

    if (current_rangefinder_alt > rangefinder_thresh_dist) then
        
    end;

    return update();
end;

