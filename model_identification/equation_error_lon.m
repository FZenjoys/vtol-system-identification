clc; clear all; close all;
maneuver_types = ["pitch_211"];
load_data;

%%
%%%%%%%%%%%%%%%%%%%%%%%
% Stepwise regression %
%%%%%%%%%%%%%%%%%%%%%%%

%%%% Initialize SR %%%%%%

F_in = 4;

z = c_Z; % output (= dependent variable)
N = length(z);
one = ones(N, 1);

% Calculate total Sum of Squares
z_bar = mean(z);
SS_T = (z - z_bar)' * (z - z_bar);

X_curr = [one]; % Chosen regressors

regr = [u_hat w_hat q_hat delta_e n_p]; % Basis regressors

X_pool = [regr regr.^2]; % TODO: Add cross-terms?
pool_names = ["u_hat" "w_hat" "q_hat" "delta_e" "n_p" ...
    "u_hat_sq" "w_hat_sq" "q_hat_sq" "delta_e_sq" "n_p_sq"
    ];
chosen_regressors_names = [];

%%%%%%% START %%%%%

% Find most correlated regressor
top_corr_i = pick_next_regressor_i(X_pool, z);

% Select corresponding regressor from original pool
new_regr = X_pool(:, top_corr_i);
chosen_regressors_names = [chosen_regressors_names pool_names(top_corr_i)];

% Remove chosen regressor from pool
X_pool(:, top_corr_i) = [];
pool_names(top_corr_i) = [];

% Add regressor to currently chosen regressors
X_curr = [X_curr new_regr];

% Do regression with new regressors
[th_hat, y_hat, v, R_sq, F_0] = regression_round(X_curr, z, SS_T);

fprintf(['Chosen regressors: ' repmat('%s ', 1, length(chosen_regressors_names)) '\n'], chosen_regressors_names)
disp("F_0 = " + F_0);
disp("R_sq = " + R_sq + "%");
disp(" ")

if F_0 < F_in
    disp("F value too low");
end

figure
plot(t_plot, z, t_plot, y_hat); hold on
legend("$z$", "$\hat{z}$", 'Interpreter','latex')

while true
    % Calculate new dependent variable that is orthogonal to regressors
    % currently in model (= residuals)
    z_ort = v;

    % Make regressor pool orthogonal to current regressors
    z_interm = [one new_regr];
    interm_th_hat = LSE(z_interm, X_pool);
    X_pool_ort = X_pool - z_interm * interm_th_hat;
    
    % Find strongest correlation between regressor and dependent variable
    % that is orthogonal to current model
    top_corr_i = pick_next_regressor_i(X_pool_ort, z_ort);
    
    % Select corresponding regressor from original pool
    new_regr = X_pool(:, top_corr_i);
    chosen_regressors_names = [chosen_regressors_names pool_names(top_corr_i)];
    
    % Remove chosen regressor from pool
    X_pool(:, top_corr_i) = [];
    pool_names(top_corr_i) = [];
    
    % Add regressor to currently chosen regressors
    X_curr = [X_curr new_regr];

    % Do regression with new regressors
    [th_hat, y_hat, v, R_sq, F_0] = regression_round(X_curr, z, SS_T);
    
    % Print status
    fprintf(['Chosen regressors: ' repmat('%s ', 1, length(chosen_regressors_names)) '\n'], chosen_regressors_names)
    disp("F_0 = " + F_0);
    disp("R_sq = " + R_sq + "%");
    disp(" ")
    
    % Show plot
    plot(t_plot, y_hat);
end

function [th_hat, y_hat, v, R_sq, F_0] = regression_round(X, z, SS_T)
    % Do LSE with new set of regressors
    th_hat = LSE(X, z);

    % Estimate output
    y_hat = X * th_hat; % Estimated output

    % Calculate Regression Sum of Squares
    z_bar = mean(z);
    SS_R = (y_hat - z_bar)' * (y_hat - z_bar);
    
    % Coefficient of Determination
    R_sq = SS_R / SS_T * 100;

    v = z - y_hat; % Residuals
    [N, p] = size(X);
    p = p - 1; % Do not count bias term
    s_sq = (v' * v) / (N - p - 1); % Fit error variance

    % Calculate partial F statistics
    F_0 = SS_R / s_sq;
end

function [top_corr_i] = pick_next_regressor_i(X_pool, z)
    r = calc_corr_coeff(X_pool, z);
    [~, top_corr_i] = max(abs(r));
end

function [th_hat] = LSE(X, z)
    D = (X' * X)^(-1);
    th_hat = D * X' * z;
end

function [r] = calc_corr_coeff(X, z)
    X_bar = mean(X);
    z_bar = mean(z);
    
    cov_Xz = (X - X_bar)' * (z - z_bar);
    var_X = diag((X - X_bar)' * (X - X_bar));
    var_z = diag((z - z_bar)' * (z - z_bar));
    r = cov_Xz ./ sqrt(var_X * var_z);
end