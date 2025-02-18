function [c_l, c_m, c_n] = calc_moment_coeffs(p, q, r, u, v, w, p_dot, q_dot, r_dot)
    dyn_pressure = calc_dyn_pressure(u, v, w);
    airframe_static_properties; % get wingspan, MAC and planform
    inertia_properties; 

    %Q = calc_torque_pusher(n_p); Neglect moment from pusher motor
    c_l = (J_xx * p_dot - J_xz * (r_dot + p .* q) + q .* r * (J_zz - J_yy)) ./ (dyn_pressure * wingspan_m * planform_sqm);
    c_m = (J_yy * q_dot + r .* p * (J_xx - J_zz) + J_xz * (p .^ 2 - r .^ 2)) ./ (dyn_pressure * mean_aerodynamic_chord_m * planform_sqm);
    c_n = (J_zz * r_dot - J_xz * (p_dot - q .* r) + p .* q * (J_yy - J_xx)) ./ (dyn_pressure * wingspan_m * planform_sqm);
end

% function Q = calc_torque_pusher(n_p)
%     aircraft_properties; % Load rho, diam and torque coeff
%     Q = rho * prop_diam_pusher^5 * c_Q_pusher * n_p.^2;
% end