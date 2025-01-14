% Moment of Inertia around NED body frame
% Calculated from 3D CAD file
% units: grams * square millimeters;

J_xx = 731622502.52;
J_xy = 303.62;
J_xz = 127693250.72;
J_yx = 303.62;
J_yy = 1066367479.22;
J_yz = 18495.48;
J_zx = 127693250.72;
J_zy = 18495.48;
J_zz = 1691708225.72;

J_grams_sqmm = [J_xx J_xy J_xz;
                J_yx J_yy J_yz
                J_zx J_zy J_zz];

grams_sqmm_to_kg_sqm = 1e-3 * 1e-3^2;
J = J_grams_sqmm * grams_sqmm_to_kg_sqm;

% Redefine these with correct units (this is bad coding style)
J_xx = J(1,1);
J_xy = J(1,2);
J_xz = J(1,3);
J_yx = J(2,1);
J_yy = J(2,2);
J_yz = J(2,3);
J_zx = J(3,1);
J_zy = J(3,2);
J_zz = J(3,3);

% Convenience constants for more easily defining angular accelerations
gam_det = J_xx * J_zz - J_xz ^ 2;
gam_1 = J_xz * (J_xx - J_yy + J_zz) / gam_det;
gam_2 = (J_zz * (J_zz - J_yy) + J_xz ^ 2) / gam_det;
gam_3 = J_zz / gam_det;
gam_4 = J_xz / gam_det;
gam_5 = (J_zz - J_xx) / J_yy;
gam_6 = J_xz / J_yy;
gam_7 = (J_xx * (J_xx - J_yy) + J_xz ^ 2) / gam_det;
gam_8 = J_xx / gam_det;
gam = [gam_1 gam_2 gam_3 gam_4 gam_5 gam_6 gam_7 gam_8];