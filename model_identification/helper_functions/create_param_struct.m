function [parameters] = create_param_struct(type)
    aircraft_properties;
    
    [par_name_base, par_fixed_base, par_min_base, par_max_base, par_value_base]...
        = create_common_model_params();
    
    if type == "lon"     
        [par_name_lon, par_fixed_lon, par_min_lon, par_max_lon, par_value_lon] = create_lon_model_params();
        
        ParName = [par_name_base par_name_lon];
        ParMin = [par_min_base par_min_lon];
        ParMax = [par_max_base par_max_lon];
        ParFixed = [par_fixed_base par_fixed_lon];
        ParValue = [par_value_base par_value_lon];
    
    elseif type == "lat"
        [par_name_lat, par_fixed_lat, par_min_lat, par_max_lat, par_value_lat] = create_lat_model_params();

        ParName = [par_name_base par_name_lat];
        ParMin = [par_min_base par_min_lat];
        ParMax = [par_max_base par_max_lat];
        ParFixed = [par_fixed_base par_fixed_lat];
        ParValue = [par_value_base par_value_lat];

    elseif type == "full"
        [par_name_lon, par_fixed_lon, par_min_lon, par_max_lon, par_value_lon] = create_lon_model_params();
        [par_name_lat, par_fixed_lat, par_min_lat, par_max_lat, par_value_lat] = create_lat_model_params();
        
        ParName = [par_name_base par_name_lon par_name_lat];
        ParMin = [par_min_base par_min_lon par_min_lat];
        ParMax = [par_max_base par_max_lon par_max_lat];
        ParFixed = [par_fixed_base par_fixed_lon par_fixed_lat];
        ParValue = [par_value_base par_value_lon par_value_lat];
    end

    parameters = struct('Name', ParName, ...
        'Unit', '',...
        'Value', ParValue, ...
        'Minimum', ParMin, ...
        'Maximum', ParMax, ...
        'Fixed', ParFixed);
end

function [ParName, ParFixed, ParMin, ParMax, ParValue] = create_common_model_params()
    approx_zero = eps;
    aircraft_properties;
    
    ParName = {
        'g',                ...
        'half_rho_planform', ...
        'rho_diam_top_pwr_four', ...
        'rho_diam_pusher_pwr_four', ...
        'rho_diam_top_pwr_five', ...
        'rho_diam_pusher_pwr_five', ...
        'mass',					...
        'mean_chord_length',              ...
        'wingspan',					...
        'nondim_constant_lon', ...
        'nondim_constant_lat', ...
        'lam',				...
        'J_yy' ,            ...
        'servo_time_constant',...
        'servo_rate_lim_rad_s',...
        'aileron_trim_rad',...
        'elevator_trim_rad',...
        'rudder_trim_rad',...
        'c_T_pusher',...
        'c_T_top',...
        'c_Q_top',...
    };

    ParFixed = {
        true,... % g,                  ...
        true,... % half_rho_planform, ...
        true,... % rho_diam_top_pwr_four
        true,... % rho_diam_pusher_pwr_four
        true,... % rho_diam_top_pwr_five
        true,... % rho_diam_pusher_pwr_five
        true,... % mass_kg,					...
        true,... % mean_chord_length,              ...
        true,... % wingspan,					...
        true,... % nondim_constant_lon
        true,... % nondim_constant_lat
        true,... % lam,				...
        true,... % Jyy, ...
        true,... % servo_time_const,...
        true,... % servo_rate_lim_rad_s,...
        true,... % aileron_trim_rad
        true,... % elevator_trim_rad
        true,... % rudder_trim_rad
        true,... % c_T_pusher
        true,... % c_T_top
        true,... % c_Q_top
    };

    ParMin = {
        approx_zero,... % g,                  ...
        approx_zero,... % half_rho_planform, ...
        -Inf,... % rho_diam_top_pwr_four
        -Inf,... % rho_diam_pusher_pwr_four
        -Inf,... % rho_diam_top_pwr_five
        -Inf,... % rho_diam_pusher_pwr_five
        approx_zero,... % mass_kg,					...
        approx_zero,... % mean_chord_length,              ...
        approx_zero,... % wingspan,					...
        approx_zero,... % nondim_constant_lon
        approx_zero,... % nondim_constant_lat
        -Inf,... % lam,				...
        approx_zero,... % Jyy, ...
        approx_zero,... % servo_time_const,...
        approx_zero,... % servo_rate_lim_rad_s,...
        -Inf,... % aileron_trim_rad
        -Inf,... % elevator_trim_rad
        -Inf,... % rudder_trim_rad
        -Inf,... % c_T_pusher
        -Inf,... % c_T_top
        -Inf,... % c_Q_top
    };

    ParMax = {
        Inf,... % g,                  ...
        Inf,... % half_rho_planform, ...
        Inf,... % rho_diam_top_pwr_four
        Inf,... % rho_diam_pusher_pwr_four
        Inf,... % rho_diam_top_pwr_five
        Inf,... % rho_diam_pusher_pwr_five
        Inf,... % mass_kg,					...
        Inf,... % mean_chord_length,              ...
        Inf,... % wingspan,					...
        Inf,... % nondim_constant_lon
        Inf,... % nondim_constant_lat
        Inf,... % lam,				...
        Inf,... % Jyy, ...
        Inf,... % servo_time_const,...
        Inf,... % servo_rate_lim_rad_s,...
        Inf,... % aileron_trim_rad
        Inf,... % elevator_trim_rad
        Inf,... % rudder_trim_rad
        Inf,... % c_T_pusher
        Inf,... % c_T_top
        Inf,... % c_Q_top
    };

    ParValue = {
        g,                  ...
        half_rho_planform, ...
        rho_diam_top_pwr_four, ...
        rho_diam_pusher_pwr_four, ...
        rho_diam_top_pwr_five, ...
        rho_diam_pusher_pwr_five, ...
        mass_kg,					...
        mean_aerodynamic_chord_m,              ...
        wingspan_m,					...
        nondim_constant_lon, ...
        nondim_constant_lat, ...
        lam,				...
        Jyy, ...
        servo_time_const_s, ...
        servo_rate_lim_rad_s,...
        delta_a_trim_rad,...
        delta_e_trim_rad,...
        delta_r_trim_rad,...
        c_T_pusher,...
        c_T_top,...
        c_Q_top,...
    };
end

function [par_name_lat, par_fixed_lat, par_min_lat, par_max_lat, par_value_lat] = create_lat_model_params()
    initial_guess_lat;
    approx_zero = eps;
    
    par_name_lat = {
        'c_Y_beta', ... % Definitively negative, think about how a positive beta will give a negative y-axis force
        'c_Y_p', ... % should be close to zero/negligible
        'c_Y_r', ... % I guess this should be close to zero/negligible, by looking at values in McClain
        'c_Y_delta_a', ... % Negative according to AVL
        'c_Y_delta_r', ... % Positive according to AVL
        'c_l_beta', ... % Negative for static roll stability
        'c_l_p', ... % Roll damping. Always negative
        'c_l_r', ... % Cross-coupling, roll moment due to yawing. Should be positive
        'c_l_delta_a', ... % Roll moment due to ailerons. Always positive
        'c_l_delta_r', ... % Roll moment due to rudder. Should be small
        'c_n_beta', ... % Positive for weathercock stability
        'c_n_p', ... % Cross-coupling, yaw moment due to rolling. Sign unknown
        'c_n_r', ... % Yaw damping. Always negative
        'c_n_delta_a', ... % Yaw moment due to ailerons. Would guess positive?
        'c_n_delta_r', ... % Yaw moment due to rudder. Always negative
    };

    par_min_lat = {
        -Inf,...% c_Y_beta
        -Inf,...% c_Y_p
        -Inf,...% c_Y_r
        -Inf,...% c_Y_delta_a
        -Inf,...% c_Y_delta_r
        -Inf,...% c_l_beta
        -Inf,...% c_l_p
        approx_zero,...% c_l_r
        approx_zero,...% c_l_delta_a
        -Inf,...% c_l_delta_r
        approx_zero,...% c_n_beta
        -Inf,...% c_n_p
        -Inf,...% c_n_r
        -Inf,...% c_n_delta_a
        -Inf,...% c_n_delta_r
    };

    par_max_lat = {
        -approx_zero,...% c_Y_beta
        Inf,...% c_Y_p
        Inf,...% c_Y_r
        Inf,...% c_Y_delta_a
        Inf,...% c_Y_delta_r
        -approx_zero,...% c_l_beta
        -approx_zero,...% c_l_p
        Inf,...% c_l_r
        Inf,...% c_l_delta_a
        Inf,...% c_l_delta_r
        Inf,...% c_n_beta
        Inf,...% c_n_p
        -approx_zero,...% c_n_r
        Inf,...% c_n_delta_a
        Inf,...% c_n_delta_r
    };

    par_fixed_lat = {
        false,...% c_Y_beta
        false,...% c_Y_p
        false,...% c_Y_r
        false,...% c_Y_delta_a
        false,...% c_Y_delta_r
        false,...% c_l_beta
        false,...% c_l_p
        false,...% c_l_r
        false,...% c_l_delta_a
        false,...% c_l_delta_r
        false,...% c_n_beta
        false,...% c_n_p
        false,...% c_n_r
        false,...% c_n_delta_a
        false,...% c_n_delta_r
    };

    par_value_lat = {
        c_Y_beta,...
        c_Y_p,...
        c_Y_r,...
        c_Y_delta_a,...
        c_Y_delta_r,...
        c_l_beta,...
        c_l_p,...
        c_l_r,...
        c_l_delta_a,...
        c_l_delta_r,...
        c_n_beta,...
        c_n_p,...
        c_n_r,...
        c_n_delta_a,...
        c_n_delta_r,...
    };
end

function [par_name_lon, par_fixed_lon, par_min_lon, par_max_lon, par_value_lon] = create_lon_model_params()
    initial_guess_lon;
    approx_zero = eps;
    
    par_name_lon = {
        'c_L_0',				...
        'c_L_alpha',      	...
        'c_L_q',          	...
        'c_L_delta_e',    	...
        'c_D_p',				...
        'c_D_alpha',				...
        'c_D_alpha_sq',				...
        'c_D_q',          	...
        'c_D_delta_e',    	...
        'c_m_0',				...
        'c_m_alpha',          ...
        'c_m_q',				...
        'c_m_delta_e',		...
    };

    par_fixed_lon = {
        false,... % c_L_0,				...
        false,... % c_L_alpha,      	...
        false,... % c_L_q,          	...
        false,... % c_L_delta_e,    	...
        false,... % c_D_p,				...
        false,... % c_D_alpha,          ...
        false,... % c_D_alpha_sq,          ...
        false,... % c_D_q,          	...
        false,... % c_D_delta_e,    	...
        false,... % c_m_0,				...
        false,... % c_m_alpha,          ...
        false,... % c_m_q,				...
        false,... % c_m_delta_e,		...
    };

    % Do not allow static curve params to change a lot
    max_stat_change = 0.3;
    stat_lower_lim = 1 - max_stat_change;
    stat_upper_lim = 1 + max_stat_change;
    par_min_lon = {
        c_L_0 * stat_lower_lim,... % c_L_0,				...
        c_L_alpha * stat_lower_lim,... % c_L_alpha,      	...
        -Inf,... % c_L_q,          	...
        -Inf,... % c_L_delta_e,    	...
        c_D_p * stat_lower_lim, ... % c_D_p,				...
        c_D_alpha * stat_lower_lim, ...% c_D_alpha,          ...
        c_D_alpha_sq * stat_lower_lim, ...% c_D_alpha_sq,          ...
        -Inf,... % c_D_q,          	...
        approx_zero,... % c_D_delta_e,    	...
        -Inf,... % c_m_0,				...
        -Inf,... % c_m_alpha,          ...
        -Inf,... % c_m_q,				...
        -Inf,... % c_m_delta_e,		...
    };

    par_max_lon = {
        c_L_0 * stat_upper_lim,... % c_L_0,				...
        c_L_alpha * stat_upper_lim,... % c_L_alpha,      	...
        Inf,... % c_L_q,          	...
        Inf,... % c_L_delta_e,    	...
        c_D_p * stat_upper_lim, ... % c_D_p,				...
        c_D_alpha * stat_upper_lim, ...% c_D_alpha,          ...
        c_D_alpha_sq * stat_upper_lim, ...% c_D_alpha_sq,          ...
        Inf,... % c_D_q,          	...
        Inf,... % c_D_delta_e,    	...
        Inf,... % c_m_0,				...
        -approx_zero,... % c_m_alpha,          ...
        -approx_zero,... % c_m_q,				...
        -approx_zero,... % c_m_delta_e,		...
    };

    par_value_lon = {
        c_L_0,				...
        c_L_alpha,      	...
        c_L_q,          	...
        c_L_delta_e,    	...
        c_D_p,				...
        c_D_alpha,          ...
        c_D_alpha_sq,          ...
        c_D_q,          	...
        c_D_delta_e,    	...
        c_m_0,				...
        c_m_alpha,          ...
        c_m_q,				...
        c_m_delta_e,		...
    };
end