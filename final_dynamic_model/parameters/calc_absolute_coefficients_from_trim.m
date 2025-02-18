%clc; clear all; close all;

trim_values;
aerodynamic_coeffs_relative_to_trim;

c_m_0 = c_m_0 - c_m_alpha * alpha_trim;

c_D_0 = c_D_0 - c_D_alpha * alpha_trim + c_D_alpha_sq * alpha_trim^2;
c_D_alpha = c_D_alpha - 2 * c_D_alpha_sq * alpha_trim;

c_L_0 = c_L_0 - c_L_alpha * alpha_trim + c_L_alpha_sq * alpha_trim^2;
c_L_alpha = c_L_alpha - 2 * c_L_alpha_sq * alpha_trim;