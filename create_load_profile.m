function LoadScaling = create_load_profile(mpc, N, inputData)
%create_load_profile Creates a load scaling profile for the planning
%horizon N. Reads load from the specified file.
%
% LoadScaling = create_load_profile(mpc, N)
%
% Outputs
%   LoadScaling: Structure with the following fields   
%         profile - scaling coefficients relative to the base load
%                   defined in the mpc, size nbuses x N or 1 x N
%         delta_t - length of a time period in hours  
%
% Inputs
%   mpc       - Nominal Matpower case
%   N         - Number of time periods in the planning horizon
%   inputData - File containing the load data
%

%Hourly 10 day load pattertn for Ticino
addpath('./data');
profile = csvread(inputData);
hours = linspace(0, 2*pi, length(profile));
[hours, profile] = ScaleData(hours, profile);


%% compute min and max generation capabilities

%generator limits idx
GEN_STATUS = 8;
PMAX = 9;
PMIN = 10;
QMIN = 5;
QMAX = 4;

%nominal load idx
PD = 3;
QD = 4;

%identify ON generators
generatorsON = find(mpc.gen(:,GEN_STATUS) > 0);

PGmin_sum = sum(mpc.gen(generatorsON,PMIN));
PGmax_sum = sum(mpc.gen(generatorsON,PMAX));
QGmin_sum = sum(mpc.gen(generatorsON,QMIN));
QGmax_sum = sum(mpc.gen(generatorsON,QMAX));

PD_sum = sum(mpc.bus(:,PD));
QD_sum = sum(mpc.bus(:,QD));

%% scaling of the nominal load is within 30-100% of the nominal load
%% or within PGmin and PGmax, not considering transmission losses
scaling_min = PGmin_sum / PD_sum;
scaling_max = PGmax_sum / PD_sum;

ALPHA_MIN = 0.3;
ALPHA_MAX = 1.0;

scaling_min = max( scaling_min, ALPHA_MIN);
scaling_max = min( scaling_max, ALPHA_MAX);

% scale the profile to make sure that load does not exceed generation
profile = (scaling_max - scaling_min) * profile + scaling_min;

%% adjust size of the load scaling matrix to match N
Nprofile = size(profile,1);
if (N <= Nprofile)
    profile = profile(1:N);
else
    profile = repmat(profile, ceil(N/Nprofile), 1);
    profile = profile(1:N);
end

LoadScaling.profile = profile;
LoadScaling.delta_t = 1;

end