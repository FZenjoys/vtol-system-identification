%%%%%%
%%% Aircraft properties
%%%%%%

%%% Mass properties
% Mass
mass_g = 12630.00;
mass_kg = mass_g * 1e-3;

% Moment of Inertia around NED body frame
% Calculated from 3D CAD file
% units: grams * square millimeters;
Jxx = 1025160985.28;
Jxy = 36558.56;
Jxz = 131913617.37;
Jyx = 36558.56;
Jyy = 12553415.26;
Jyz = 32858.06;
Jzx = 131913617.37;
Jzy = 32858.06;
Jzz = 2028820899.68;

J_grams_sqmm = [Jxx Jxy Jxz;
     Jyx Jyy Jyz
     Jzx Jzy Jzz];

grams_sqmm_to_kg_sqm = 1e-3 * 1e-3^2;
J = J_grams_sqmm * grams_sqmm_to_kg_sqm;

% Redefine these (bad coding style)
Jxx = J(1,1);
Jxy = J(1,2);
Jxz = J(1,3);
Jyx = J(2,1);
Jyy = J(2,2);
Jyz = J(2,3);
Jzx = J(3,1);
Jzy = J(3,2);
Jzz = J(3,3);

lam_det = Jxx * Jzz - Jxz ^ 2;
lam_1 = Jxz * (Jxx - Jyy + Jzz) / lam_det;
lam_2 = (Jzz * (Jzz - Jyy) + Jxz ^ 2) / lam_det;
lam_3 = Jzz / lam_det;
lam_4 = Jxz / lam_det;
lam_5 = (Jzz - Jxx) / Jyy;
lam_6 = Jxz / Jyy;
lam_7 = (Jxx * (Jxx - Jyy) + Jxz ^ 2) / lam_det;
lam_8 = Jxx / lam_det;
lam = [lam_1 lam_2 lam_3 lam_4 lam_5 lam_6 lam_7 lam_8];

%%% Wings
% Planform
% From CAD 3D model
half_tail_planform_sqmm = 67225.12;
one_wing_planform_sqmm = 263626.10;
planform_sqmm = 2 * half_tail_planform_sqmm + 2 * one_wing_planform_sqmm;
planform_sqm = planform_sqmm * 1e-3^2;

% Mean chord length
% From CAD 3D model
chord_length_body_side_mm = 300;
chord_length_wingtip_side_mm = 195.4;
mean_chord_length_m = (chord_length_body_side_mm + chord_length_wingtip_side_mm) / 1e3 / 2;

% Wingspan
wingspan_mm = 2560; % TODO this is not accurate yet!
wingspan_m = wingspan_mm / 1e3;

% Aspect ratio
aspect_ratio = wingspan_m^2 / planform_sqm;

%%% Motor placement
% From CAD 3D model
% Motor placements in body frame (z-axis is pointing down)
r_t1_B_mm = [353.2; 400.0; -52.0];
r_t2_B_mm = [-446.8; -400.0; -52.0];
r_t3_B_mm = [353.2; -400.0; -52.0];
r_t4_B_mm = [-446.8; 400.0; -52.0];
r_t1_B = r_t1_B_mm / 1e3;
r_t2_B = r_t1_B_mm / 1e3;
r_t3_B = r_t1_B_mm / 1e3;
r_t4_B = r_t1_B_mm / 1e3;

%%% Physical constants
rho = 1.225; % kg / m^3 (air density at sea level)
g = 9.81; % m / s^2

%%% Propellers and motors
kINCH_TO_METER = 0.0254;
prop_diam_top_in_inches = 16;
prop_diam_top = prop_diam_top_in_inches * kINCH_TO_METER;
prop_diam_pusher_in_inches = 15;
prop_diam_pusher = prop_diam_pusher_in_inches * kINCH_TO_METER;
c_T_top = 0;
c_T_pusher = 2.3906e-05; % See motor_id.m for calculation off this
c_Q_top = 0;
c_Q_pusher = 0;