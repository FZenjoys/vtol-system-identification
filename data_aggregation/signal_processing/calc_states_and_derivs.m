function [t, phi, theta, psi, p, q, r, u, v, w, a_x, a_y, a_z, p_dot, q_dot, r_dot] = ...
    calc_states_and_derivs(dt_desired, t_recorded, phi_recorded, theta_recorded, psi_recorded, v_N_recorded, v_E_recorded, v_D_recorded)
    
    t_0 = t_recorded(1);
    t_end = t_recorded(end);
    
    % Calc u, v and w from kinematic relationships
    [u_recorded, v_recorded, w_recorded] = calc_body_vel(phi_recorded, theta_recorded, psi_recorded, v_N_recorded, v_E_recorded, v_D_recorded);
    
    % Smooth signals
    temp = smooth_signal([phi_recorded theta_recorded psi_recorded]);
    phi = temp(:,1);
    theta = temp(:,2);
    psi = temp(:,3);
    
    temp = smooth_signal([u_recorded v_recorded w_recorded]);
    u = temp(:,1);
    v = temp(:,2);
    w = temp(:,3);
    
    % Calculate piecewise spline approximations of signals
    dt_knots = 0.1;
    phi_spline = slmengine(t_recorded, phi,'knots',t_0:dt_knots:t_end + dt_knots, 'plot', 'off'); % add 'plot', 'on' to see fit
    theta_spline = slmengine(t_recorded, theta,'knots',t_0:dt_knots:t_end + dt_knots);
    psi_spline = slmengine(t_recorded, psi,'knots',t_0:dt_knots:t_end + dt_knots);
        
    u_spline = slmengine(t_recorded, u,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    v_spline = slmengine(t_recorded, v,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    w_spline = slmengine(t_recorded, w,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    
    % Set desired time vector
    t = (t_0:dt_desired:t_end)';
    
    % Calculate derivatives and attitude angles at desired times
    phi = slmeval(t, phi_spline);
    phi_dot = slmeval(t, phi_spline, 1);
    theta = slmeval(t, theta_spline);
    theta_dot = slmeval(t, theta_spline, 1);
    psi = slmeval(t, psi_spline);
    psi_dot = slmeval(t, psi_spline, 1);
    
    u = slmeval(t, u_spline);
    u_dot = slmeval(t, u_spline, 1);
    v = slmeval(t, v_spline);
    v_dot = slmeval(t, v_spline, 1);
    w = slmeval(t, w_spline);
    w_dot = slmeval(t, w_spline, 1);
    
    % Calc p, q and r from kinematic relationships
    [p, q, r] = calc_ang_vel(phi, theta, phi_dot, theta_dot, psi_dot);
    
    % Calc translational accelerations
    aircraft_properties; % to get g
    [a_x, a_y, a_z] = calc_trans_acc(g, phi, theta, p, q, r, u, v, w, u_dot, v_dot, w_dot);
    
    % Calc angular accelerations
    p_spline = slmengine(t, p,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    q_spline = slmengine(t, q,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    r_spline = slmengine(t, r,'knots',t_0:.1:t_end + 0.1, 'plot', 'off');
    
    p_dot = slmeval(t, p_spline, 1);
    q_dot = slmeval(t, q_spline, 1);
    r_dot = slmeval(t, r_spline, 1);
end