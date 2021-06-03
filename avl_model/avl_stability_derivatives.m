aircraft_properties;

% Directly from AVL
% See stability_derivatives_trim.txt
c_L_alpha = 4.732;
c_L_q = 7.375 ;
c_L_delta_e = 0.00632 ;
c_D_delta_e = 0.000257; % Trefftz drag
c_Y_p = 0.112085;
c_Y_r = 0.258965;
c_Y_delta_a = -0.000570;
c_Y_delta_r = 0.005580;

c_l_p = -0.472;
c_l_r = 0.141;
c_l_delta_a = 0.00494;
c_l_delta_r = -0.000145;
c_m_0 = -0.18;
c_m_alpha = -0.974;
c_m_q = -11.882 ;
c_m_delta_e = -0.0208;
c_n_p = -0.0635;
c_n_r = -0.0869;
c_n_delta_a = 0.00018;
c_n_delta_r = -0.0019;

% Sideslip parameters
c_Y_beta =  -0.351976;
c_l_beta =  -0.024980;
c_n_beta =   0.111040;

% Convert all control derivatives to rad instead of deg
c_L_delta_e = c_L_delta_e * 180 / pi;
c_D_delta_e = c_D_delta_e * 180 / pi;
c_l_delta_a = c_l_delta_a * 180 / pi;
c_l_delta_r = c_l_delta_r * 180 / pi;
c_m_delta_e = c_m_delta_e * 180 / pi;
c_n_delta_a = c_n_delta_a * 180 / pi;
c_n_delta_r = c_n_delta_r * 180 / pi;

% Non-dimensionalize ang rate derivatives
% NOTE: The values from AVL are already dimensionless. See this post:
% https://www.researchgate.net/post/Does-anyone-know-if-the-derivatives-output-from-AVL-Athena-Vortex-Lattice-are-dimensional-or-dimensionless


