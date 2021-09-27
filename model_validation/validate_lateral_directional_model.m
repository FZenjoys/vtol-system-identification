clear all; close all; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LATERAL MODEL VALIDATION %
% State = [v p r phi]
% Input = [delta_a delta_r]
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

model_type = "lateral-directional";
maneuver_types = [
    "pitch_211"
    %"roll_211",...
    %"yaw_211",...
    ];

state_names = ["v","p","r","\phi"];
state_names_latex = ["$v$","$p$","$r$","$\phi$"];
param_names = ["cY0" "cYb" "cYp" "cYr" "cYda" "cYdr"...
    "cl0" "clb" "clp" "clr" "clda" "cldr"...
    "cn0" "cnb" "cnp" "cnr" "cnda" "cndr"];
param_names_latex = ["$c_{Y 0}$" "$c_{Y \beta}$" "$c_{Y p}$" "$c_{Y r}$" "$c_{Y {\delta_a}}$" "$c_{Y {\delta_r}}$"...
    "$c_{l 0}$" "$c_{l \beta}$" "$c_{l p}$" "$c_{l r}$" "$c_{l {\delta_a}}$" "$c_{l {\delta_r}}$"...
    "$c_{n 0}$" "$c_{n \beta}$" "$c_{n p}$" "$c_{n r}$" "$c_{n {\delta_a}}$" "$c_{n {\delta_r}}$"];

%%%%%%%%%%%%%
% LOAD DATA %
%%%%%%%%%%%%%

% Load FPR data which contains training data and validation data
load("data/flight_data/selected_data/fpr_data_lat.mat");
load("data/flight_data/selected_data/fpr_data_lon.mat");
fpr_data = fpr_data_lon;


% Load coeffients

% Import ss model from AVL
%avl_state_space_model;

% Load coefficients
load("avl_model/avl_results/avl_coeffs_lat.mat");
load("model_identification/equation_error/results/equation_error_coeffs_lat.mat");
load("model_identification/output_error/results/output_error_lat_coeffs.mat");
load("model_identification/output_error/results/output_error_lat_coeffs_all_free.mat");
load("model_identification/output_error/results/output_error_lat_coeffs_final.mat");
%%
model_coeffs = {equation_error_coeffs_lat, output_error_lat_coeffs, output_error_lat_coeffs_all_free, output_error_lat_coeffs_final};
model_names = ["EquationError" "OutputError" "OutputErrorAllFree" "OutputErrorFinal"];
models = create_models_from_coeffs(model_coeffs, model_type);

% Load Cramer-Rao lower bounds
load("model_identification/output_error/results/output_error_lat_cr_bounds.mat");
load("model_identification/output_error/results/output_error_lat_all_free_cr_bounds.mat");
load("model_identification/output_error/results/output_error_lat_final_cr_bounds.mat");

cr_bounds = {zeros(size(output_error_lat_cr_bounds)) output_error_lat_cr_bounds output_error_lat_all_free_cr_bounds output_error_lat_final_cr_bounds};

% Call validation function
validate_models(...
    model_type, test_avl_models, test_nonlin_models, show_maneuver_plots,...
    state_names, state_names_latex, param_names, param_names_latex,...
    show_error_metric_plots, show_cr_bounds_plots, show_param_map_plot,...
    maneuver_types, models, model_coeffs, model_names, cr_bounds, fpr_data...
    );