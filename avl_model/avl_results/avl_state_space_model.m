% see avl_outputs/state_space_matrix

% Longitudinal dynamics
% x_lon = [u, w, q, theta]^T=
% x_lon_dot = A_lon * x_lon + B_lon * delta_e;

A_lon = [-0.0056  0.4887 -0.9705 -9.8100
         -0.7699 -3.2958 20.0172  0.0
          0.1293 -2.7615 -2.9048  0.0
               0  0.0000  1.0000  0.0];

B_lon = [ 0.2638E-02
         -0.9143E-01
         -0.8113
          0.0000] * 180 / pi; % delta_e is defined in AVL as degrees
% Note that delta_T is not yet included here!
     
lon_sys = ss(A_lon, B_lon, eye(4),0,...
    'StateName',{'u','w','q','th'},...
    'OutputName',{'u','w','q','th'},...
    'InputName',{'delta_e'});

% Lateral dynamics
% x_lat = [v, p, r, phi]^T=
% x_lat_dot = A_lat * x_lat + B_lat * [delta_a
%                                      delta_r];

A_lat = [-0.2484    1.1028  -20.7073    9.8100
         -0.7526  -16.6670    4.8338    0.0000
          1.3694   -2.6875   -1.1071    0.0000
          0.0000    1.0000    0.0000    0.0000];

B_lat = [-0.8295E-02    0.8197E-01
          2.868        -0.1713
          0.2725       -0.5258
          0.0000        0.0000] * 180 / pi; % delta_e is defined in AVL as degrees
      
lat_sys = ss(A_lat, B_lat, eye(4),0,...
    'StateName',{'v','p','r','phi'},...
    'OutputName',{'v','p','r','phi'},...
    'InputName',{'delta_a','delta_r'});

% % Plot impulse responses
% figure
%impulse(lon_sys,10)
% figure
% impulse(lat_sys,10)
