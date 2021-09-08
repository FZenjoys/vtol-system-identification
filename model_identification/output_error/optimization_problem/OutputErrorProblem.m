classdef OutputErrorProblem
    properties
        DynamicsModel
        FprData
        ManeuverTypes
        CurrOptData
        NomParams
        ParamPerturbation = 0.001
        NParamsLat = 18
        NOutputsLat = 4
        CurrManeuverData
    end
    methods
        function obj = OutputErrorProblem(fpr_data, dynamics_model, maneuver_types)
            obj.FprData = fpr_data;
            obj.DynamicsModel = dynamics_model;
            obj.ManeuverTypes = maneuver_types;
            obj.CurrOptData.iteration_number = 0;
            obj.CurrOptData.reached_convergence = false;
            obj.CurrOptData.params.CoeffsLat = dynamics_model.CoeffsLat;
            obj.CurrOptData.params.CoeffsLon = dynamics_model.CoeffsLon;
            obj.NomParams.CoeffsLat = dynamics_model.CoeffsLat;
            obj.NomParams.CoeffsLon = dynamics_model.CoeffsLon;
            obj.CurrOptData.cost_history = [];
        end
        
        function obj = solve(obj)
            for maneuver_type = obj.ManeuverTypes(1)
                for maneuver_i = 1
                    % Get maneuver data
                    maneuver = obj.FprData.training.(maneuver_type)(maneuver_i);
                    obj = obj.update_curr_maneuver_data(maneuver);
                    
                    % Calculate initial values
                    % Simulate current parameters
                    obj.CurrManeuverData.y_pred = obj.sim_model(obj.CurrOptData.params.CoeffsLat, obj.CurrOptData.params.CoeffsLon);
                    obj.CurrManeuverData.residuals = obj.calc_residuals_lat(obj.CurrManeuverData.z, obj.CurrManeuverData.y_pred);

                    % Covariance matrix for Newton-Raphson step
                    obj.CurrManeuverData.R_hat = obj.est_noise_covariance(obj.CurrManeuverData.residuals, obj.CurrManeuverData.N);

                    % Calculate cost
                    obj.CurrManeuverData.cost = obj.calc_cost_lat(obj.CurrManeuverData.R_hat, obj.CurrManeuverData.residuals);
                    obj.CurrManeuverData.cost_history = obj.CurrManeuverData.cost;
                    disp("Cost: " + obj.CurrManeuverData.cost);
                    
                    obj.CurrOptData.parameters_converged = false;
                    obj.CurrOptData.error_covariance_converged = false;
                    
                    figure;
                    fig_cost_axes = axes;
                    obj.draw_cost_function_history(fig_cost_axes, obj.CurrManeuverData.cost_history);
                    
                    while ~obj.CurrOptData.error_covariance_converged
                        step_i = 0;
                        while ~obj.CurrOptData.parameters_converged
                            % Optimization step
                            step_i = step_i + 1;
                            disp("Performing Newton-Raphson step: " + step_i)
                            tic
                            [delta_theta, information_matrix, cost_gradient] = obj.do_newton_raphson_step();
                            toc
                            
                            % Perform simple line search to find alpha
                            alphas = linspace(0.1,1,10);

                            min_cost = inf;
                            for potential_alpha = alphas
                                % Update parameters
                                params_lat_new = obj.CurrOptData.params.CoeffsLat + potential_alpha * reshape(delta_theta, size(obj.CurrOptData.params.CoeffsLat));

                                % Simulate new parameters
                                y_pred_new = obj.sim_model(params_lat_new, obj.CurrOptData.params.CoeffsLon);
                                residuals_new = obj.calc_residuals_lat(obj.CurrManeuverData.z, y_pred_new);

                                % Update cost
                                cost_new = obj.calc_cost_lat(obj.CurrManeuverData.R_hat, residuals_new);
                                disp("Cost: " + cost_new + " with alpha: " + potential_alpha);
                                if cost_new < min_cost
                                    min_cost = cost_new;
                                    alpha = potential_alpha;
                                end
                            end
                            
                            disp("chose alpha = " + alpha)
                            params_lat_new = obj.CurrOptData.params.CoeffsLat + alpha * reshape(delta_theta, size(obj.CurrOptData.params.CoeffsLat));
                            
                            % Simulate new parameters
                            y_pred_new = obj.sim_model(params_lat_new, obj.CurrOptData.params.CoeffsLon);
                            residuals_new = obj.calc_residuals_lat(obj.CurrManeuverData.z, y_pred_new);

                            % Update cost
                            cost_new = obj.calc_cost_lat(obj.CurrManeuverData.R_hat, residuals_new);
                            
                            disp("Cost: " + cost_new);
                            
                            % Convergence
                            % Parameter change
                            eucl_params_change = norm(reshape((params_lat_new - obj.CurrOptData.params.CoeffsLat),[obj.NParamsLat 1]),2);
                            eucl_prev_params = norm(reshape((obj.CurrOptData.params.CoeffsLat),[obj.NParamsLat 1]),2);
                            param_change_ratio = eucl_params_change / eucl_prev_params;
                            disp("param_change_ratio: " + param_change_ratio);
                            if param_change_ratio < 0.001
                               disp("converged");
                               obj.CurrOptData.parameters_converged = true;
                               obj.CurrOptData.ConvergenceReason = "Parameter change smaller than specified threshold";
                            end
                            
                            abs_cost_change = abs((cost_new - obj.CurrManeuverData.cost) / obj.CurrManeuverData.cost);
                            disp("abs_cost_change: " + abs_cost_change);
                            if abs_cost_change < 0.001
                               disp("converged");
                               obj.CurrOptData.parameters_converged = false;
                               obj.CurrOptData.ConvergenceReason = "Cost change smaller than specified threshold";
                            end
                            
                            fprintf(['cost_gradient: ' repmat('%s ', 1, length(cost_gradient)) '\n'], cost_gradient) 
                            if all(abs(cost_gradient) < 0.05)
                               disp("converged");
                               obj.CurrOptData.parameters_converged = false;
                               obj.CurrOptData.ConvergenceReason = "All gradients smaller than specificed treshold";
                            end
                            
                            % Save all data and move on to next iteration
                            obj.CurrOptData.params.CoeffsLat = params_lat_new;
                            obj.CurrManeuverData.y_pred = y_pred_new;
                            obj.CurrManeuverData.residuals = residuals_new;
                            obj.CurrManeuverData.cost = cost_new;
                            obj.CurrManeuverData.cost_history = [obj.CurrManeuverData.cost_history obj.CurrManeuverData.cost];
                            
                            obj.draw_cost_function_history(fig_cost_axes, obj.CurrManeuverData.cost_history);
                            
                            disp(" ")
                        end
                        
                        % Update noise covariance matrix
                        disp("Updating R_hat")
                        R_hat_new = obj.est_noise_covariance(obj.CurrManeuverData.residuals, obj.CurrManeuverData.N);
                        
                        % Start optimization routine over again
                        obj.CurrOptData.parameters_converged = false;
                        
                        noise_covar_change = diag(obj.CurrManeuverData.R_hat - R_hat_new) ./ (diag(obj.CurrManeuverData.R_hat));
                        if all(noise_covar_change) < 0.05
                            disp("converged");
                            obj.CurrOptData.error_covariance_converged = false;
                            obj.CurrOptData.ConvergenceReason = "All covariances smaller than specified treshold";
                        end
                    end
                    
                    %maneuver.plot_lateral_validation({maneuver.Time, maneuver.Time}, {obj.CurrManeuverData.y_pred, y_pred_new}, ...
                    %    ["Real data", "Initial", "New"], ["-", "--", "-"], true, false, "", "");
                    disp("")
                    

                    % Check for convergence
                    
%                     % Run until convergence
%                     while ~obj.CurrOptData.reached_convergence
%                         obj.CurrOptData.iteration_number = obj.CurrOptData.iteration_number + 1;
%                         disp("Running iteration: " + obj.CurrOptData.iteration_number);
%                         
%                         [R_hat_new, cost_new, params_new] = evaluate_iteration_for_maneuver(obj, maneuver);
%                         obj.CurrOptData.reached_convergence = check_for_convergence(obj, params_new, cost_new, R_hat_new);
%                     end
%                     disp("Reached convergence after " + obj.CurrOptData.iteration_number + " iterations");
                end
            end
        end
        
        function draw_cost_function_history(obj, fig_axes, cost_history)
            plot(fig_axes, cost_history);
            title("Cost function")
            xlabel("Iteration")
            drawnow;
        end
        
        function obj = update_curr_maneuver_data(obj, maneuver)
            obj.CurrManeuverData.t_data_sequence = maneuver.Time;
            obj.CurrManeuverData.tspan = [maneuver.Time(1) maneuver.Time(end)];
            obj.CurrManeuverData.N = length(obj.CurrManeuverData.t_data_sequence);
            obj.CurrManeuverData.z = maneuver.get_lat_state_sequence();
            obj.CurrManeuverData.y_0 = maneuver.get_lat_state_initial();
            obj.CurrManeuverData.lon_state_sequence = maneuver.get_lon_state_sequence();
            obj.CurrManeuverData.input_sequence = maneuver.get_lat_input_sequence();
        end
        
        function [delta_theta, M, dJ_dtheta] = do_newton_raphson_step(obj)            
            % Compute S (sensitivity matrices) for lateral parameters
%             disp("Computing sensitivies")
%             tic
            S_all_i = zeros(obj.CurrManeuverData.N, obj.NOutputsLat, obj.NParamsLat);
            for j = 1:obj.NParamsLat
                % Compute sensitivies by using first order central differences
                delta_theta_j = obj.CurrOptData.params.CoeffsLat(j) * obj.ParamPerturbation;
                % Handle parameters set to 0
                if delta_theta_j == 0
                   delta_theta_j = obj.ParamPerturbation;
                end
                perturbed_params_lat_pos = obj.create_perturbed_params_matrix(delta_theta_j, obj.CurrOptData.params.CoeffsLat, j, 1);
                perturbed_params_lat_neg = obj.create_perturbed_params_matrix(delta_theta_j, obj.CurrOptData.params.CoeffsLat, j, -1);
                    
                %tic
                y_pos = obj.sim_model(perturbed_params_lat_pos, obj.CurrOptData.params.CoeffsLon);
                y_neg = obj.sim_model(perturbed_params_lat_neg, obj.CurrOptData.params.CoeffsLon);
                %toc
                
                dy_dtheta_j = (y_pos - y_neg) ./ (2 * delta_theta_j);
                S_all_i(:,:,j) = dy_dtheta_j;
            end
            S_all_i = permute(S_all_i,[2 3 1]); % Get S in the correct dimensions: (n_outputs, n_params, n_timesteps)
            %toc
            
            % Calculate M (information matrix)
            %disp("Computing information matrix")
            %tic
            M_all_i = zeros(obj.NParamsLat, obj.NParamsLat, obj.CurrManeuverData.N);
            for timestep_i = 1:obj.CurrManeuverData.N
                M_all_i(:,:,timestep_i) = S_all_i(:,:,timestep_i)' * (obj.CurrManeuverData.R_hat \ S_all_i(:,:,timestep_i));    
            end
            M = sum(M_all_i,3);
            %toc
            
            % Calculate g
            %disp("Computing g")
            %tic
            dJ_dtheta_all_i = zeros(obj.NParamsLat, 1, obj.CurrManeuverData.N);
            for timestep_i = 1:obj.CurrManeuverData.N
                dJ_dtheta_all_i(:,:,timestep_i) = S_all_i(:,:,timestep_i)' * (obj.CurrManeuverData.R_hat \ obj.CurrManeuverData.residuals(timestep_i,:)');    
            end
            dJ_dtheta = -sum(dJ_dtheta_all_i,3);
            %toc
            
            % Compute param_update
            delta_theta = - M \ dJ_dtheta;
        end
        
        function perturbed_params_matrix = create_perturbed_params_matrix(~, delta_theta_j, params, j, sign)
            perturbed_params_matrix = params;
            perturbed_params_matrix(j) = perturbed_params_matrix(j) + sign * delta_theta_j;
        end
        
        function y_pred = sim_model(obj, lat_params, lon_params)
            obj.DynamicsModel = obj.DynamicsModel.set_params(lat_params, lon_params);
            [t_pred, y_pred] = ode45(@(t,y) ...
                obj.DynamicsModel.dynamics(t, y, ...
                    obj.CurrManeuverData.t_data_sequence, obj.CurrManeuverData.input_sequence, obj.CurrManeuverData.lon_state_sequence), obj.CurrManeuverData.tspan, obj.CurrManeuverData.y_0...
                    );
            y_pred = interp1(t_pred, y_pred, obj.CurrManeuverData.t_data_sequence); % change y_pred to correct time before returning
        end
        
        function v = calc_residuals_lat(~, z, y_pred)
            v = z - y_pred; % residuals
        end

        function cost = calc_cost_lat(~, R_hat, residuals)
            cost = 0.5 * sum(diag(residuals / R_hat * residuals'));
        end        
        
        function R_hat = est_noise_covariance(~, residuals, N)
            R_hat = diag(diag(residuals' * residuals) / N); % Assumes cross-covariances to be zero ny neglecting nondiagonal terms
        end
   end
end