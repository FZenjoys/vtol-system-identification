clc; clear all; close all;

% The script will automoatically load all maneuvers in "data_raw/experiments/*"

% This script takes in raw maneuver data from csv files and calculates all
% the required signals and their derivatives. This includes states, their
% derivatives, coefficients, and inputs.
 
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex');

%disp("Setting random seed to default to guarantee reproducability");
rng default % Always shuffle the maneuvers in the same way for reproducability

% Load metadata
metadata_filename = "data/flight_data/metadata.json";
metadata = read_metadata(metadata_filename);

% Data settings
time_resolution = 0.02; % 50 Hz
knot_points_for_spline_derivation_dt = 0.1;

% Plot settings
save_raw_plots = false;
save_kinematic_consistency_plots = false;
save_lateral_signal_plots = false;
save_longitudinal_signal_plots = false;

%model_type = "lateral_directional";
model_type = "longitudinal";

% Maneuver settings
maneuver_types = [
    %"roll_211",...
    %"yaw_211",...
    "pitch_211",...
    %"freehand"
    ];

% These maneuvers are skipped either because they contain dropouts or
% because they are part of another maneuver sequence.
% The entire data loading scheme would benefit from being reconsidered, but
% there is not time for this.
maneuvers_to_skip = {};
maneuvers_to_skip.("roll_211") = [6 11 12 14 20];
maneuvers_to_skip.("yaw_211") = [1:11 18 22:27 29 30 35:39 41];
maneuvers_to_skip.("pitch_211") = [2 3 7 8 9 11 14 17 18 19 20 21 24 25 32 35 40];
maneuvers_to_skip.("freehand") = [];

% Save raw maneuver data
fpr_data = {};
for maneuver_type = maneuver_types
    maneuvers_to_skip_for_curr_type = maneuvers_to_skip.(maneuver_type);
    disp("Processing " + maneuver_type + " maneuvers.");
    
    % Read raw data recorded from logs
    [t_state_all_maneuvers, q_NB_all_maneuvers, v_NED_all_maneuvers, p_NED_all_maneuvers, t_u_fw_all_maneuvers, u_fw_all_maneuvers, maneuver_start_indices_state, maneuver_start_indices_u_fw] ...
        = read_data_from_experiments(metadata, maneuver_type);
    
    all_maneuvers = create_maneuver_objects_from_raw_data(maneuver_type, t_state_all_maneuvers, q_NB_all_maneuvers, v_NED_all_maneuvers, p_NED_all_maneuvers, t_u_fw_all_maneuvers, u_fw_all_maneuvers, maneuver_start_indices_state, maneuver_start_indices_u_fw);
    
    % Pick only selected maneuvers to move on with
    selected_maneuvers = [];
    for maneuver_i = 1:length(all_maneuvers)
        if ~any(maneuvers_to_skip_for_curr_type(:) == maneuver_i)
            selected_maneuvers = [selected_maneuvers; all_maneuvers(maneuver_i)];
        end
    end
    
    % Plot selected raw maneuvers if desired
    for maneuver_i = 1:length(selected_maneuvers)
        % Plot raw data from maneuvers
        if save_raw_plots
            plot_location = "data/flight_data/selected_data/" + model_type + "_data/full_plots/";
            selected_maneuvers(maneuver_i).RawData.save_plot(plot_location);
        end
    end
    
    % Flight Path Reconstruction from raw maneuver data
    for maneuver_i = 1:length(selected_maneuvers)
        selected_maneuvers(maneuver_i) = selected_maneuvers(maneuver_i).calc_fpr_from_rawdata(time_resolution, knot_points_for_spline_derivation_dt);
    end
    
    % Kinematic Consistency Checks
    if save_kinematic_consistency_plots
        for maneuver_i = 1:length(selected_maneuvers)
            plot_location = "data/flight_data/selected_data/" + model_type + "_data/kinematic_consistency_checks/";
            selected_maneuvers(maneuver_i).check_kinematic_consistency(false, true, plot_location);
        end
    end
    
    % Calcululate coefficients
    for maneuver_i = 1:length(selected_maneuvers)
        selected_maneuvers(maneuver_i) = selected_maneuvers(maneuver_i).calc_force_coeffs();
        selected_maneuvers(maneuver_i) = selected_maneuvers(maneuver_i).calc_moment_coeffs();
    end
    
    % Calculate explanatory variables
    for maneuver_i = 1:length(selected_maneuvers)
        selected_maneuvers(maneuver_i) = selected_maneuvers(maneuver_i).calc_explanatory_vars();
    end
    
    % Save plot for all relevant lateral data signals
    if save_lateral_signal_plots
        for maneuver_i = 1:length(selected_maneuvers)
            plot_location = "data/flight_data/selected_data/" + model_type + "_data/model_signals/";
            selected_maneuvers(maneuver_i).save_plot_lateral(plot_location);
        end
    end
    
    % Save plot for all relevant lateral data signals
    if save_longitudinal_signal_plots
        for maneuver_i = 1:length(selected_maneuvers)
            plot_location = "data/flight_data/selected_data/" + model_type + "_data/model_signals/";
            selected_maneuvers(maneuver_i).save_plot_longitudinal(plot_location);
        end
    end
    
    fpr_data.(maneuver_type) = selected_maneuvers;
end

% Manually pick sequenced maneuvers as validation data

if strcmp(model_type, "lateral_directional")
    fpr_data_lat = {};
    % Roll maneuvers
    num_roll_maneuvers = length(fpr_data.roll_211);
    random_indices = randperm(num_roll_maneuvers);
    num_training_maneuvers = floor(0.8 * num_roll_maneuvers);
    
    fpr_data_lat.training.roll_211 = fpr_data.roll_211(random_indices(1:num_training_maneuvers));
    fpr_data_lat.validation.roll_211 = fpr_data.roll_211(random_indices(num_training_maneuvers + 1:end));
    
    % Yaw maneuvers
    num_yaw_maneuvers = length(fpr_data.yaw_211);
    random_indices = randperm(num_yaw_maneuvers);
    num_training_maneuvers = floor(0.8 * num_yaw_maneuvers);
    
    fpr_data_lat.training.yaw_211 = fpr_data.yaw_211(random_indices(1:num_training_maneuvers));
    fpr_data_lat.validation.yaw_211 = fpr_data.yaw_211(random_indices(num_training_maneuvers + 1:end));

    % Save FPR data to file
    save("data/flight_data/selected_data/fpr_data_lat.mat", "fpr_data_lat");
elseif strcmp(model_type, "longitudinal")
    num_maneuvers = length(fpr_data.pitch_211);
    random_indices = randperm(num_maneuvers);
    num_training_maneuvers = floor(0.8 * num_maneuvers);
    
    fpr_data_lon = {};
    fpr_data_lon.training.pitch_211 = fpr_data.pitch_211(random_indices(1:num_training_maneuvers));
    fpr_data_lon.validation.pitch_211 = fpr_data.pitch_211(random_indices(num_training_maneuvers + 1:end));
    
    % Save FPR data to file
    save("data/flight_data/selected_data/fpr_data_lon.mat", "fpr_data_lon");
end
