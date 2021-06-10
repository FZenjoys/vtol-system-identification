clc; clear all; close all;
%load_data;

% Load constants
aircraft_properties;
const_params = [rho, mass_kg, g, wingspan_m, mean_aerodynamic_chord_m, planform_sqm, V_nom,...
     servo_time_const_s, servo_rate_lim_rad_s,...
     prop_diam_pusher^4, c_T_pusher,...
     gam_1, gam_2, gam_3, gam_4, gam_5, gam_6, gam_7, gam_8, J_yy,...
     ]';

% Initial guesses from equation-error
% c_X_0 = 0.8702;
% c_X_u = -1.8743;
% c_X_u_sq = 0.7885;
% c_X_w = 0.2157;
% c_X_w_sq = 2.4828;
% c_X_q = -3.1194;
% c_X_n_p = 0.0024;

c_X_0 = 0.3660;
c_X_u = -0.8596;
c_X_u_sq = 0.4201;
c_X_w = 0.2029;
c_X_w_sq = 2.6789;
c_X_q = -3.1729;
c_X_n_p = -3.0610e-04;

c_Z_0 = -0.5384;
c_Z_w = -5.4921;
c_Z_w_sq = 7.2941;
c_Z_q = -14.9348;
c_Z_delta_e = -0.7653;
c_Z_delta_e_sq = -0.9647;

c_m_0 = 0.0099;
c_m_w = -1.2951;
c_m_q = -19.9529;
c_m_delta_e = -0.8361;
c_m_delta_e_sq = -0.5335;

x0 = [
     c_X_0, c_X_u, c_X_w, c_X_w_sq, c_X_q, c_X_n_p,...
     c_Z_0, c_Z_w, c_Z_w_sq, c_Z_delta_e,...
     c_m_0, c_m_w, c_m_q, c_m_delta_e,...
     ];
 
param_names = [
    "c_{X_0}", "c_{X_u}", "c_{X_w}", "c_{X_{w^2}}", "c_{X_q}", "c_{X_{np}}",...
    "c_{Z_0}", "c_{Z_w}", "c_{Z_{w^2}}", "c_{Z_{\delta_e}}",...
    "c_{m_0}", "c_{m_w}", "c_{m_q}", "c_{m_{\delta_e}}"
    ];

%%
% Collect recorded data
t_seq = t;
y_lon_seq = [theta q u w];
y_lat_seq = [phi, psi, p, r, v];
input_seq = [delta_a_sp, delta_e_sp, delta_r_sp, n_p];


%%
% Optimization

% Variable bounds
allowed_param_change = 0.6;
LB = min([x0 * (1 - allowed_param_change); x0 * (1 + allowed_param_change)]);
UB = max([x0 * (1 - allowed_param_change); x0 * (1 + allowed_param_change)]);

weight = diag([2 2 1 1]);

% Opt settings
rng default % For reproducibility
numberOfVariables = length(x0);
options = optimoptions('ga');%'UseParallel', true, 'UseVectorized', false);
    %'PlotFcn',@gaplotbestf,'Display','iter');
options.InitialPopulationMatrix = x0;
options.FunctionTolerance = 1e-02;

% Run optimization problem on each maneuver separately
xs = zeros(num_maneuvers, length(x0));
for maneuver_i = 1:num_maneuvers
    disp("== Solving for maneuver " + maneuver_i + " ==");
    
    % Organize data for maneuver
    [t_seq_m, y_lon_seq_m, y_lat_seq_m, input_seq_m] = extract_man_data_lon(maneuver_i, maneuver_indices, t_seq, y_lon_seq, y_lat_seq, input_seq);
    delta_e_m = input_seq(:,1);
    y0 = [y_lon_seq_m(1,:) delta_e_m(1)]; % Add actuator dynamics
    data_seq_maneuver = [t_seq_m input_seq_m y_lat_seq_m];
    N = length(data_seq_maneuver);
    residual_weight = diag(linspace(1,0,N)); % Weight states in the beginning more
    tspan = [t_seq_m(1) t_seq_m(end)];

    % Initial calculations for maneuver
    residuals_0 = calc_residuals(y_lon_seq_m, data_seq_maneuver, const_params, x0, dt, tspan, y0);
    R_hat_0 = diag(diag(residuals_0' * residuals_0) / N); % Assume cross-covariances to be zero
    fval_0 = cost_fn_lon(x0, weight, residual_weight, R_hat_0, dt, data_seq_maneuver, y0, tspan, y_lon_seq_m, const_params);
    
    % Set initial values
    x = x0;
    fval = fval_0;
    R_hat = R_hat_0;
    
    reached_convergence = false;
    i = 0;
    tic
    while ~reached_convergence
        disp("Iteration " + i);
        fprintf(['R_hat: ' repmat('%2.5f  ',1,length(diag(R_hat))) '\n'], diag(R_hat))
        % Save values from last iteration
        x_prev = x;
        fval_prev = fval;
        R_hat_prev = R_hat;

        % Solve optimization problem with previous covariance matrix
        options.InitialPopulationMatrix = x;
        FitnessFunction = @(x) cost_fn_lon(x, weight, residual_weight, R_hat, dt, data_seq_maneuver, y0, tspan, y_lon_seq_m, const_params);
        [x,fval] = ga(FitnessFunction,numberOfVariables,[],[],[],[],LB,UB,[],options);
        
        % Calc new covariance matrix
        residuals = calc_residuals(y_lon_seq_m, data_seq_maneuver, const_params, x, dt, tspan, y0);
        N = length(data_seq_maneuver);
        R_hat = diag(diag(residuals' * residuals) / N); % Assume cross-covariances to be zero
        
        % Check for convergence
        abs_param_change = abs(x_prev - x);
        abs_fval_change = abs((fval - fval_prev) / fval_prev);
        abs_covar_change = abs(diag(R_hat_prev - R_hat)./(diag(R_hat_prev)));
        
        if all(abs_param_change < 1e-5)
            reached_convergence = true;
        end
        if abs_fval_change < 0.001
            reached_convergence = true;
        end
        if all(abs_covar_change < 0.05)
            reached_convergence = true;
        end
        i = i + 1;
    end
    toc
    
    fprintf(['abs_param_change: ' repmat('%2.4f  ',1,length(abs_param_change)) '\n'], abs_param_change)
    disp("abs_fval_change: " + abs_fval_change);
    fprintf(['abs_covar_change: ' repmat('%2.4f  ',1,length(abs_covar_change)) '\n'], abs_covar_change)
    
    xs(maneuver_i,:) = x;
    
    writematrix(xs, "lon_params.txt")
end

%%

xs = readmatrix("lon_params.txt");
xs = rmoutliers(xs);
chosen_params = median(xs);
param_mads = mad(xs);

%%

figure
num_params = length(x0);
for i = 1:num_params
    subplot(3,5,i)
    errorbar(0,chosen_params(i),param_mads(i),'-s','MarkerSize',10,...
        'MarkerEdgeColor','red','MarkerFaceColor','red')
    title(param_names(i));
end

%% Validate model

% Load validation data
maneuver_type = "pitch_211";
data_path = "data/aggregated_data/" + maneuver_type + "/";
data = readmatrix(data_path + "data_val.csv");
maneuver_start_indices = readmatrix(data_path + "maneuver_start_indices_val.csv");

[t_seq, phi, theta, psi, p, q, r, u, v, w, a_x, a_y, a_z, p_dot, q_dot, r_dot, delta_a_sp, delta_e_sp, delta_r_sp, delta_a, delta_e, delta_r, n_p, c_X, c_Y, c_Z, c_l, c_m, c_n]...
    = extract_variables_from_data(data);
dt = t(2) - t(1);

% Test plot maneuver
maneuver_i = 3;

all_params = [const_params;
              chosen_params'];
[t_m, phi_m, theta_m, psi_m, p_m, q_m, r_m, u_m, v_m, w_m, a_x_m, a_y_m, a_z_m, delta_a_sp_m, delta_e_sp_m, delta_r_sp_m, delta_a_m, delta_e_m, delta_r_m, n_p_m]...
    = get_maneuver_data(maneuver_i, maneuver_start_indices, t_seq, phi, theta, psi, p, q, r, u, v, w, a_x, a_y, a_z, delta_a_sp, delta_e_sp, delta_r_sp, delta_a, delta_e, delta_r, n_p);

N = length(t_m);
y0 = [theta_m(1) q_m(1) u_m(1) w_m(1) delta_e_m(1)];

input_seq_m = [delta_a_sp_m delta_e_sp_m delta_r_sp_m n_p_m];
lat_state_seq_m = [phi_m, psi_m, p_m, r_m, v_m];
maneuver_seq = [t_m input_seq_m lat_state_seq_m];

tspan = [t_m(1) t_m(end)];

[t_pred, y_pred] = ode45(@(t,y) lon_dynamics_c(t, y, [t_m input_seq_m lat_state_seq_m], all_params), tspan, y0);
y_pred = interp1(t_pred, y_pred, tspan(1):dt:tspan(2));

z = [theta_m q_m v_m w_m delta_e_m];
z_bar = mean(z)';
R_sq = (diag(y_pred' * z) - N * z_bar.^2) ./ (diag(z' * z) - N * z_bar.^2);
fprintf(['R_sq: ' repmat('%2.2f  ',1,length(R_sq)) '\n'], R_sq)

plot_maneuver("maneuver" + maneuver_i, t_m, phi_m, theta_m, psi_m, p_m, q_m, r_m, u_m, v_m, w_m, delta_a_sp_m, delta_e_sp_m, delta_r_sp_m, n_p_m,...
    t_m, y_pred,...
    false, true, "");


%% Test stuff. TODO remove this
if 1
    %tic
    for maneuver_i = 1
        [t_m, phi_m, theta_m, psi_m, p_m, q_m, r_m, u_m, v_m, w_m, a_x_m, a_y_m, a_z_m, delta_a_m, delta_e_m, delta_r_m, n_p_m]...
         = get_maneuver_data(maneuver_i, maneuver_start_indices, t_seq, phi, theta, psi, p, q, r, u, v, w, a_x, a_y, a_z, delta_a, delta_e, delta_r, n_p);

        all_params = [const_params;
                      x'];

        % Integration interval
        y0 = [theta_m(1) q_m(1) u_m(1) w_m(1) delta_e(1)];

        input_seq_m = [delta_a_m delta_e_m delta_r_m n_p_m];
        lat_state_seq_m = [phi_m, psi_m, p_m, r_m, v_m];
        maneuver_seq = [t_m input_seq_m lat_state_seq_m];

        tspan = [t_m(1) t_m(end)];
        
        %dy_dt = lon_dynamics_c(t_m(1), y0, maneuver_seq, all_params)
        [t_pred, y_pred] = ode45(@(t,y) lon_dynamics_c(t, y, maneuver_seq, all_params), tspan, y0);
        y_pred = interp1(t_pred, y_pred, tspan(1):dt:tspan(2));
        
        plot_maneuver("maneuver" + maneuver_i, t_m, phi_m, theta_m, psi_m, p_m, q_m, r_m, u_m, v_m, w_m, delta_a_m, delta_e_m, delta_r_m, n_p_m,...
            t_m, y_pred,...
            false, true, "");
    end
    %toc
end

% tic
% cost = cost_fn_lon(x0, dt, t_seq, y_lon, y_lat, input, const_params, maneuver_indices);
% toc
