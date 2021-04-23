clc; clear all; close all;

% File location
log_file = "2021_04_18_flight_2_static_curves_no_thrust_211_roll";
csv_files_location = 'logs/csv/';
csv_log_file_location = csv_files_location + log_file;

% Output data
output_location = "static_curves/data/";

% Set common data time resolution
dt = 0.01;

% Read data
[t, state, input] = read_state_and_input_from_log(csv_log_file_location, dt);
q_NB = state(:,1:4);
w_B = state(:,5:7);
v_B = state(:,8:10);
u_MR = input(:,1:4);
u_FW = input(:,5:8);
sysid_indices = get_sysid_indices(csv_log_file_location, t);
[acc_B, acc_B_filtered] = read_accelerations(csv_log_file_location, t);
[V_a, V_a_validated] = read_airspeed(csv_log_file_location, t);

%% Calculate intermediate values
% Calculate total airspeed
V = sqrt(v_B(:,1).^2 + v_B(:,2).^2 + v_B(:,3).^2);

% Calculate Angle of Attack
AoA = rad2deg(atan2(v_B(:,3),v_B(:,1)));

%% Aggregate data
time_before_maneuver = 1; %s
time_after_maneuver_start = 3; %s

indices_before_maneuver = time_before_maneuver / dt;
indices_after_maneuver_start = time_after_maneuver_start / dt;
padding = 0.25 / dt;
maneuver_length_in_indices = 200 - 2 * padding;

maneuvers_to_aggregate = [3:7 12 13 17 24 25 29];
%maneuvers_to_aggregate = [2:9 11:27 29:31]; % All maneuvers without dropout
data_set_length = maneuver_length_in_indices * length(maneuvers_to_aggregate);

% state structure: [att ang_vel_B vel_B] = [q0 q1 q2 q3 p q r u v w]
% input structure: [top_rpm_1 top_rpm_2 top_rpm_3 top_rpm_4 aileron elevator rudder pusher_rpm]
%       = [nt1 nt2 nt3 nt4 np delta_a delta_e delta_r]
accelerations = zeros(data_set_length, 3);
input = zeros(data_set_length, 8);
state = zeros(data_set_length, 10);
airspeed = zeros(data_set_length, 1);

AIRSPEED_TRESHOLD_MIN = 21; % m/s
AIRSPEED_TRESHOLD_MAX = 25; % m/s

curr_maneuver_aggregation_index = 1;
num_aggregated_maneuvers = 0;
aggregated_maneuvers = zeros(100);
for i = maneuvers_to_aggregate
    maneuver_start_index = rc_sysid_indices(i) - indices_before_maneuver;
    maneuver_end_index = rc_sysid_indices(i) + indices_after_maneuver_start;
    % Move to correct start index
    for j = 1:4/dt
        [~, maneuver_top_index] = max(u_fw(maneuver_start_index:maneuver_end_index,2));
        maneuver_top_index = maneuver_start_index + maneuver_top_index;
    end
    
    t_maneuver = t(maneuver_start_index:maneuver_end_index);
    
    maneuver_start_index = maneuver_top_index - 200 + padding;
    maneuver_end_index = maneuver_top_index - padding; 

    % Save data chunk to training and test sets
    maneuver_state = [
        q_NB(maneuver_start_index:maneuver_end_index,:) ...
        w_B(maneuver_start_index:maneuver_end_index,:) ...
        v_B(maneuver_start_index:maneuver_end_index,:) ...
        ];
    maneuver_input = [
        u_mr(maneuver_start_index:maneuver_end_index,:) ...% TODO translate these from moments and thrust to individual motor rpms.
        u_fw(maneuver_start_index:maneuver_end_index,:) ...% TODO same here ...
        ];
    maneuver_accelerations = acc_B_filtered(maneuver_start_index:maneuver_end_index,:);
    maneuver_airspeed = V_a(maneuver_start_index:maneuver_end_index);
    
    v_B_maneuver = maneuver_state(:,8:10);
    V_maneuver = V_a(maneuver_start_index);
    
    % Calculate data cleanliness
    std_ang_rates = std(w_B(maneuver_start_index:maneuver_end_index,:));
    std_body_vel = std(v_B(maneuver_start_index:maneuver_end_index,:));

    total_std = std_ang_rates(1) + std_ang_rates(3 ) + std_body_vel(2);
    
    %Only add maneuvers that are above airspeed treshold
    if (V_maneuver(1) < AIRSPEED_TRESHOLD_MIN)
       display("skipping maneuver " + i + ": airspeed too low")
       continue 
    end
    if (V_maneuver(1) > AIRSPEED_TRESHOLD_MAX)
       display("skipping maneuver " + i + ": airspeed too high")
       continue
    end
    if (total_std > 0.7)
       display("skipping maneuver " + i + ": total std: " + total_std)
       continue
    end
    
    curr_maneuver_aggregation_index = num_aggregated_maneuvers * maneuver_length_in_indices + 1;
    state(...
        curr_maneuver_aggregation_index:curr_maneuver_aggregation_index + maneuver_length_in_indices ...
        ,:) = maneuver_state;
    input(...
        curr_maneuver_aggregation_index:curr_maneuver_aggregation_index + maneuver_length_in_indices ...
        ,:) = maneuver_input;
    accelerations(...
        curr_maneuver_aggregation_index:curr_maneuver_aggregation_index + maneuver_length_in_indices ...
        ,:) = maneuver_accelerations;
    airspeed(curr_maneuver_aggregation_index:curr_maneuver_aggregation_index + maneuver_length_in_indices)...
        = maneuver_airspeed;
    
    num_aggregated_maneuvers = num_aggregated_maneuvers + 1;
    aggregated_maneuvers(num_aggregated_maneuvers) = i;
    
    % plot data
    if 0
        t_maneuver = t(maneuver_start_index:maneuver_end_index);
        
        eul_deg = rad2deg(eul);
        
        figure
        subplot(5,1,1);
        plot(t_maneuver, eul_deg(maneuver_start_index:maneuver_end_index,:));
        legend('yaw', 'pitch','roll');
        title("attitude")

        subplot(5,1,2);
        plot(t_maneuver, w_B(maneuver_start_index:maneuver_end_index,:));
        legend('p','q','r');
        ylim([-3 3])
        title("ang vel body")

        subplot(5,1,3);
        plot(t_maneuver, v_B(maneuver_start_index:maneuver_end_index,:))
        legend('u','v','w');
        title("vel body")

        subplot(5,1,4);
        plot(t_maneuver, u_fw(maneuver_start_index:maneuver_end_index,:));
        legend('delta_a','delta_e','delta_r', 'T_fw');
        title("inputs")
    end
    
    % plot AoA, airspeed and pitch input
    if 1
        t_maneuver = t(maneuver_start_index:maneuver_end_index);
        
        fig = figure; 
        fig.Visible = 'off';
        fig.Position = [100 100 1600 1000];
        
        eul_deg = rad2deg(eul);
        
        subplot(9,1,1);
        plot(t_maneuver, u_fw(maneuver_start_index:maneuver_end_index,:));
        legend('delta_a','delta_e','delta_r', 'T_fw');
        title("inputs")

        subplot(9,1,2);
        plot(t_maneuver, [AoA(maneuver_start_index:maneuver_end_index,:) eul_deg(maneuver_start_index:maneuver_end_index,2)]);
        legend('AoA', 'pitch');
        title("Angle of Attack")
        
        eul_deg = rad2deg(eul);
        
        subplot(9,1,3);
        plot(t_maneuver, eul_deg(maneuver_start_index:maneuver_end_index,2:3));
        legend('pitch','roll');
        title("attitude")

        subplot(9,1,4);
        plot(t_maneuver, V(maneuver_start_index:maneuver_end_index,:)); hold on
        plot(t_maneuver, V_a(maneuver_start_index:maneuver_end_index,:)); hold on
        plot(t_maneuver, V_a_validated(maneuver_start_index:maneuver_end_index,:)); hold on
        legend('V','V_a','V_a_validated');
        title("Airspeed (assuming no wind)")

        subplot(9,1,5);
        plot(t_maneuver, acc_B(maneuver_start_index:maneuver_end_index,1)); hold on
        plot(t_maneuver, acc_B_filtered(maneuver_start_index:maneuver_end_index,1)); hold on
        plot(t_maneuver, bias_acc(maneuver_start_index:maneuver_end_index,1)); hold on
        legend('Acceleration', 'acc filtered', 'bias');
        title("a_x")

        subplot(9,1,6);
        plot(t_maneuver, acc_B(maneuver_start_index:maneuver_end_index,3)); hold on
        plot(t_maneuver, acc_B_filtered(maneuver_start_index:maneuver_end_index,3));
        plot(t_maneuver, bias_acc(maneuver_start_index:maneuver_end_index,3)); hold on
        legend('Acceleration', 'acc filtered', 'bias');
        title("a_z")
        
        subplot(9,1,7);
        plot(t_maneuver, abs(acc_N(maneuver_start_index:maneuver_end_index,3)+9.81));
        title("acc z compared to gravity")
        
        subplot(9,1,8);
        plot(t_maneuver, w_B(maneuver_start_index:maneuver_end_index,:))
        legend('p','q','r');
        ylim([-0.5 0.5])
        title("angular velocity")
        
        subplot(9,1,9);
        plot(t_maneuver, v_B(maneuver_start_index:maneuver_end_index,:))
        legend('u','v','w');
        ylim([-2 2])
        title("body velocity")

        filename = "half maneuver no: " + i;
        figure_title = "half maneuver no: " + i + " total std: " + total_std + ...
            ". std p: " + std_ang_rates(1) + ", std r: " + std_ang_rates(3 ) + ...
            ", std v: " + std_body_vel(2);
        sgtitle(figure_title)
        %saveas(fig, 'static_curves/data/maneuver_plots/' + filename, 'epsc')
        %savefig('static_curves/data/maneuver_plots/' + figure_title + '.fig')
        
    end
end

% Trim data
state = state(1:num_aggregated_maneuvers * maneuver_length_in_indices,:);
input = input(1:num_aggregated_maneuvers * maneuver_length_in_indices,:);
accelerations = accelerations(1:num_aggregated_maneuvers * maneuver_length_in_indices,:);
airspeed = airspeed(1:num_aggregated_maneuvers * maneuver_length_in_indices,:);

aggregated_maneuvers = aggregated_maneuvers(1:num_aggregated_maneuvers);
display("aggregated " + num_aggregated_maneuvers + " maneuvers")
disp(aggregated_maneuvers);



%% Functions
function [t, state, input] = read_state_and_input_from_log(csv_log_file_location, dt)
    ekf_data = readtable(csv_log_file_location + '_' + "estimator_status_0" + ".csv");
    angular_velocity = readtable(csv_log_file_location + '_' + "vehicle_angular_velocity_0" + ".csv");
    actuator_controls_mr = readtable(csv_log_file_location + '_' + "actuator_controls_0_0" + ".csv");
    actuator_controls_fw = readtable(csv_log_file_location + '_' + "actuator_controls_1_0" + ".csv");
    
    %%%
    % Common time vector
    
    t0 = ekf_data.timestamp(1) / 1e6;
    t_end = ekf_data.timestamp(end) / 1e6;

    t = t0:dt:t_end;
    N = length(t);
    
    %%%
    % Extract data from ekf2

    t_ekf = ekf_data.timestamp / 1e6;

    % q_NB = unit quaternion describing vector rotation from NED to Body. i.e.
    % describes transformation from Body to NED frame.
    % Note: This is the same as the output_predictor quaternion. Something is
    % wrong with documentation

    q0_raw = ekf_data.states_0_;
    q1_raw = ekf_data.states_1_;
    q2_raw = ekf_data.states_2_;
    q3_raw = ekf_data.states_3_;
    q_NB_raw = [q0_raw q1_raw q2_raw q3_raw];
    

    % Extrapolate to correct time
    q_NB = interp1q(t_ekf, q_NB_raw, t');
    % q_NB is the quat we are looking for for our state vector
    q0 = q_NB(:,1);
    q1 = q_NB(:,2);
    q2 = q_NB(:,3);
    q3 = q_NB(:,4);

    eul = quat2eul(q_NB);

    v_n = ekf_data.states_4_;
    v_e = ekf_data.states_5_;
    v_d = ekf_data.states_6_;
    v_N_raw = [v_n v_e v_d];

    % Extrapolate to correct time
    v_N = interp1q(t_ekf, v_N_raw, t');

    p_n = ekf_data.states_7_;
    p_e = ekf_data.states_8_;
    p_d = ekf_data.states_9_;
    p_N_raw = [p_n p_e p_d];
    p_N = interp1q(t_ekf, p_N_raw, t');

    %%%
    % Extract angular velocities from output predictor

    t_ang_vel = angular_velocity.timestamp / 1e6;

    % Angular velocity around body axes
    p_raw = angular_velocity.xyz_0_;
    q_raw = angular_velocity.xyz_1_;
    r_raw = angular_velocity.xyz_2_;
    w_B_raw = [p_raw q_raw r_raw];
    
    % Extrapolate to correct time
    w_B = interp1q(t_ang_vel, w_B_raw, t');
    p = w_B(:,1);
    q = w_B(:,2);
    r = w_B(:,3);

    %%%
    % Convert velocity to correct frames

    % This is rotated with rotation matrices only for improved readability,
    % as both the PX4 docs is ambiguous in describing q, and quatrotate() is
    % pretty ambigious too.
    R_NB = quat2rotm(q_NB);

    q_BN = quatinv(q_NB);
    R_BN = quat2rotm(q_BN);

    v_B = zeros(N, 3);
    for i = 1:N
       % Notice how the Rotation matrix has to be inverted here to get the
       % right result, indicating that q is in fact q_NB and not q_BN.
       v_B(i,:) = (R_BN(:,:,i) * v_N(i,:)')';
    end
    u = v_B(:,1);
    v = v_B(:,2);
    w = v_B(:,3);
    
    % The following line gives the same result, indicating that quatrotate() does not perform a
    % simple quaternion product: q (x) v (x) q_inv
    % v_B = quatrotate(q_NB, v_N);
    
    %%%
    % Extract input data
    t_u_mr = actuator_controls_mr.timestamp / 1e6;
    u_roll_mr = actuator_controls_mr.control_0_;
    u_pitch_mr = actuator_controls_mr.control_1_;
    u_yaw_mr = actuator_controls_mr.control_2_;
    u_throttle_mr = actuator_controls_mr.control_3_;
    u_mr_raw = [u_roll_mr u_pitch_mr u_yaw_mr u_throttle_mr];

    u_mr = interp1q(t_u_mr, u_mr_raw, t');

    t_u_fw = actuator_controls_fw.timestamp / 1e6;
    u_roll_fw = actuator_controls_fw.control_0_;
    u_pitch_fw = actuator_controls_fw.control_1_;
    u_yaw_fw = actuator_controls_fw.control_2_;
    u_throttle_fw = actuator_controls_fw.control_3_;
    u_fw_raw = [u_roll_fw u_pitch_fw u_yaw_fw u_throttle_fw];

    u_fw = interp1q(t_u_fw, u_fw_raw, t');
    
    
    %%%
    % Create state and input
    state = [q0 q1 q2 q3 p q r u v w];
    input = [u_mr u_fw];
    
end

function [sysid_indices] = get_sysid_indices(csv_log_file_location, t)
    input_rc = readtable(csv_log_file_location + '_' + "input_rc_0" + ".csv");
    
    % Extract RC sysid switch log
    sysid_rc_switch_raw = input_rc.values_6_; % sysis switch mapped to button 6
    t_rc = input_rc.timestamp / 1e6;
    RC_TRESHOLD = 1000;

    % Find times when switch was switched
    MAX_SYSID_MANEUVERS = 100;
    sysid_times = zeros(MAX_SYSID_MANEUVERS,1);
    sysid_maneuver_num = 1;
    sysid_found = false;
    for i = 1:length(t_rc)
      % Add time if found a new rising edge
      if sysid_rc_switch_raw(i) >= RC_TRESHOLD && not(sysid_found)
          sysid_times(sysid_maneuver_num) = t_rc(i);
          sysid_found = true;
          sysid_maneuver_num = sysid_maneuver_num + 1;
      end
      
      % If found a falling edge, start looking again
      if sysid_found && sysid_rc_switch_raw(i) < RC_TRESHOLD
         sysid_found = false; 
      end
    end
    
    % Plot
    if 0
        plot(t_rc, sysid_rc_switch_raw); hold on;
        plot(sysid_times, 1000, 'r*');
    end

    % Find corresponding indices in time vector
    sysid_indices = round(interp1(t,1:length(t),sysid_times));
end

function [acc_B, acc_B_filtered] = read_accelerations(csv_log_file_location, t)
    % Load data
    sensor_combined = readtable(csv_log_file_location + '_' + "sensor_combined_0" + ".csv");
    sensor_bias = readtable(csv_log_file_location + '_' + "estimator_sensor_bias_0" + ".csv");

    % Read raw sensor data
    t_acc = sensor_combined.timestamp / 1e6;
    acc_B_raw = [sensor_combined.accelerometer_m_s2_0_ sensor_combined.accelerometer_m_s2_1_ sensor_combined.accelerometer_m_s2_2_];

    % Check if significant bias
    t_sensor_bias = sensor_bias.timestamp / 1e6;
    bias_acc_raw = [sensor_bias.accel_bias_0_ sensor_bias.accel_bias_1_ sensor_bias.accel_bias_2_];
    bias_acc = interp1q(t_sensor_bias, bias_acc_raw, t');

    if 0
        figure
        subplot(2,1,1)
        plot(t, acc_B(:,1)); hold on
        plot(t, bias_acc(:,1));
        legend('acc x','bias')

        subplot(2,1,2)
        plot(t, acc_B(:,3)); hold on
        plot(t, bias_acc(:,3));
        legend('acc z','bias')
    end

    % Filter data at ~40 Hz
    f_cutoff = 40;
    T_c = 1/f_cutoff;
    temp = filloutliers(t_acc(2:end) - t_acc(1:end-1), 'linear');
    dt_acc = mean(temp);
    alpha = dt_acc / (T_c + dt_acc);

    acc_B_raw_filtered = zeros(size(acc_B_raw));
    acc_B_raw_filtered(1,:) = acc_B_raw(1,:);
    for i = 2:length(acc_B_raw)
       acc_B_raw_filtered(i,:) = alpha * acc_B_raw(i,:) + (1 - alpha) * acc_B_raw_filtered(i-1,:);
    end

    % Frequency analysis
    if 0
        plot_fft(acc_B_raw, dt);
        plot_fft(acc_B_raw_filtered, dt);
    end

    % Fuse to common time horizon
    acc_B = interp1q(t_acc, acc_B_raw, t');
    acc_B_filtered = interp1q(t_acc, acc_B_raw_filtered, t');
end

function [V_a, V_a_validated] = read_airspeed(csv_log_file_location, t)
    airspeed_data = readtable(csv_log_file_location + '_' + "airspeed_0" + ".csv");
    airspeed_validated_data = readtable(csv_log_file_location + '_' + "airspeed_validated_0" + ".csv");

    t_airspeed = airspeed_data.timestamp / 1e6;
    V_a_raw = airspeed_data.true_airspeed_m_s;
    V_a = interp1q(t_airspeed, V_a_raw, t');

    t_airspeed_validated = airspeed_validated_data.timestamp / 1e6;
    V_a_validated_raw = airspeed_validated_data.true_airspeed_m_s;
    V_a_validated = interp1q(t_airspeed_validated, V_a_validated_raw, t');
end

function plot_fft(data, dt)
    % Frequency analysis
    figure
    Y = fft(data);
    L = length(data);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    Fs = 1/dt;
    f = Fs*(0:(L/2))/L;
    plot(f,P1)
    title('Single-Sided Amplitude Spectrum of X(t)')
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
end


