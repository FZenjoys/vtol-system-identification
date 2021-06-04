% Model type
model_type = "full_lat_fixed";
num_states = 10; % [e0 e1 e2 e3 q u w delta_a delta_e delta_r]
num_outputs = 7; % [e0 e1 e2 e3 q u w]
num_inputs = 11; % [nt1 nt2 nt3 nt4 delta_a_sp delta_e_sp delta_r_sp np p r v]

% Create model path
models_path = "runs/" + string(today('datetime')) + "/" + model_type + "/";


run_to_read = 5;
model_i = 1;

path = models_path + "run_" + run_to_read + "/";
params_table = readtable(path + "params.dat", "ReadRowNames", true);

%function [] = print_std_dev(std_dev_table)
colors = ["Green" "Yellow" "Red"];

[N_params, N_models] = size(params_table);
param_names = params_table.Properties.RowNames;
model_names = params_table.Properties.VariableNames;

% Print model names
fprintf(["%15s"], "Parameters")
fprintf([repmat('%s',1,length(model_names)) '\n'], cell2mat(model_names))

for param_i = 1:N_params
    % Print param name
    param_name = param_names{param_i};
    fprintf("%*s", 10, param_name);

    % Print models std
    param_stds = params_table{param_i,:};

    color = colors(1);

end
%end