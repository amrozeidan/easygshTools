% pick a telemac dictionary based on the chosen telemac module to be used
% for telemac variables extraction in b_extelemac

function telemac_dict = pick_dict(telemac_module)


switch telemac_module
    case '2D'
        telemac_dict = {'VELOCITY U','velocity_u' , 'U';
            'VELOCITY V','velocity_v' , 'V';
            'CELERITY' , 'celerity' , 'C' ;
            'WATER DEPTH','water_depth' , 'H';
            'FREE SURFACE','free_surface' , 'S';
            'BOTTOM','bottom' , 'B';
            'FROUDE NUMBER' , 'froude_number' , 'F';
            'SCALAR FLOWRATE' , 'scalar_flowrate' , 'Q';
            'SALINITY','salinity' , 'SLNT';
            'TURBULENT ENERG.' , 'turbulent_energie' , 'K' ;
            'DISSIPATION' , 'dissipation' , 'E' ;
            'LONG. DISPERSION' , 'longitudinal_dispersion' , 'D' ;
            'VISCOSITY' , 'viscosity' , 'D' ;
            'FLOWRATE ALONG X' , 'flow_rate_x' , 'I';
            'FLOWRATE ALONG Y' , 'flow_rate_y' , 'J' ;
            'SCALAR VELOCITY' , 'scalar_velocity' , 'M';
            'WIND ALONG X','wind_x' , 'X';
            'WIND ALONG Y','wind_y' , 'Y';
            'AIR PRESSURE','air_pressure' , 'P';
            'BOTTOM FRICTION' , 'bottom_friction' , 'W';
            'DRIFT ALONG X' , 'drift_x' , 'A';
            'DRIFT ALONG Y' , 'drift_y' , 'G';
            'COURANT NUMBER' , 'courant_number' , 'L';
            'HIGH WATER MARK' , 'high_water_mark' , 'MAXZ';
            'HIGH WATER TIME' , 'high_water_time' , 'TMXZ';
            'HIGHEST VELOCITY' , 'highest_velocity' , 'MAXV';
            'TIME OF HIGH VEL' , 'time_of_highest_velocity' , 'TMXV';
            'FRICTION VEL.' , 'friction_velocity' , 'US';
            'TAU_S' , 'tau_s' , 'TAU_S';
            '1/R' , 'one_over_R' , '1/R';
            'WALLDIST' , 'wall_dist' , 'WDIST'};
        
    case '3D'
        telemac_dict = {'ELEVATION Z' , 'elevation_z' , 'Z';
            'VELOCITY U','velocity_u' , 'U';
            'VELOCITY V','velocity_v' , 'V';
            'VELOCITY W' , 'velocity_w' , 'W';
            'NUX FOR VELOCITY' , 'nux_velocity' , 'NUX';
            'NUY FOR VELOCITY' , 'nuy_velocity' , 'NUY' ; 
            'NUZ FOR VELOCITY' , 'nuz_velocity' , 'NUZ';
            'TURBULENT ENERGY' , 'turbulent_energy' , 'K' ;
            'DISSIPATION' , 'dissipation' , 'EPS' ;
            'RICHARDSON NUMB' , 'richardson_number' , 'RI';
            'RELATIVE DENSITY' , 'relative_density' , 'RHO';
            'DYNAMIC PRESSURE' , 'dynamic_pressure' , 'DP' ; 
            'HYDROSTATIC PRES' , 'hydrostatic_pressure' , 'PH' ;
            'U ADVECTION' , 'advection_u' , 'UCONV' ;
            'V ADVECTION' , 'advection_u' , 'VCONV' ;
            'W ADVECTION' , 'advection_u' , 'WCONV' ;
            'OLD VOLUMES' , 'old_volumes' , '?' ;
            'DM1' , 'dm1' , 'DM1' ; 
            'DHHN' , 'dhhn' , 'DHHN';
            'UCONVC' , 'convc_u' , 'UCONVC';
            'VCONVC' , 'convc_v' , 'VCONVC';
            'UD', 'ud' , 'UD' ;
            'VD' , 'vd' , 'VD' ; 
            'WD' , 'wd' , 'WD'};
    
end




