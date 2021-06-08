function [dy_dt] = lon_dynamics(t, y, input_seq, lat_state_seq, all_params)
    %input = interp1q(t_seq, input_seq, t); % Get value of input now
    %lat_state = interp1q(t_seq, lat_state_seq, t); % Get value of lat state now
    
    dy_dt = test_function_c(t, y, [input_seq(1,:) lat_state_seq(1,:)], all_params);
end
