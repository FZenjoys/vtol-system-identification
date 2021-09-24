clear all; close all; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LONGITUDINAL MODEL VALIDATION %
% State = [u w q theta]
% Input = [delta_e delta_t]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS FOR VALIDATION FUNCTION %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot options
test_avl_models = false;
test_nonlin_models = true;
show_maneuver_plots = true;
show_error_metric_plots = true;
show_cr_bounds_plots = true;
show_param_map_plot = true;

model_type = "longitudinal";
maneuver_types = ["pitch_211"];

state_names = ["u","w","q","\theta"];
state_names_latex = ["$u$","$w$","$q$","$\theta$"];
param_names = ["cD0" "cDa" "cDa2" "cDq" "cDde" "cL0" "cLa" "cLa2" "cLq" "cLde" "cm0" "cma" "cma2" "cmq" "cmde"];
param_names_latex = ["$c_{D 0}$" "$c_{D \alpha}$" "$c_{D \alpha^2}$" "$c_{D q}$" "$c_{D {\delta_e}}$"...
    "$c_{L 0}$" "$c_{L \alpha}$" "$c_{L \alpha^2}$" "$c_{L q}$" "$c_{L {\delta_e}}$"...
    "$c_{m 0}$" "$c_{m \alpha}$" "$c_{m \alpha^2}$" "$c_{m q}$" "$c_{m {\delta_e}}$"];

%%%%%%%%%%%%%
% LOAD DATA %
%%%%%%%%%%%%%

% Load FPR data which contains training data and validation data
load("data/flight_data/selected_data/fpr_data_lon.mat");
fpr_data = fpr_data_lon;

% Import ss model from AVL
%avl_state_space_model;

% Load coefficients
load("avl_model/avl_results/avl_coeffs_lon.mat");
load("model_identification/equation_error/results/equation_error_coeffs_lon.mat");
load("model_identification/output_error/results/output_error_lon_coeffs.mat");
load("model_identification/output_error/results/output_error_lon_all_free_coeffs.mat");
load("model_identification/output_error/results/output_error_coeffs_lon_final_coeffs.mat");

model_coeffs = {equation_error_coeffs_lon, output_error_lon_coeffs, output_error_lon_all_free_coeffs, output_error_coeffs_lon_final_coeffs};
model_names = ["EquationError" "OutputError" "OutputErrorAllFree" "OutputErrorFinal"];
models = create_models_from_coeffs(model_coeffs, model_type);

% Load Cramer-Rao lower bounds
load("model_identification/output_error/results/output_error_lon_cr_bounds.mat");
load("model_identification/output_error/results/output_error_lon_all_free_cr_bounds.mat");
load("model_identification/output_error/results/output_error_coeffs_lon_final_cr_bounds.mat");
cr_bounds = {zeros(size(output_error_lon_cr_bounds)) output_error_lon_cr_bounds output_error_lon_all_free_cr_bounds output_error_coeffs_lon_final_cr_bounds};

% Call validation function
validate_models(...
    model_type, test_avl_models, test_nonlin_models, show_maneuver_plots,...
    state_names, state_names_latex, param_names, param_names_latex,...
    show_error_metric_plots, show_cr_bounds_plots, show_param_map_plot,...
    maneuver_types, models, model_coeffs, model_names, cr_bounds, fpr_data...
    );