% path to the Matpower library (update to reflect the location at your system)
addpath( ...
    '../matpower7.0/lib', ...
    '../matpower7.0/data', ...
    '../matpower7.0/mips/lib', ...
    '-end' );

% path to the BELTISTOS library (update to reflect the location at your system)
addpath( ...
    '../beltistos', ...
    '-end' );

% set number of threads
setenv('OMP_NUM_THREADS','1');

constants;

%% load the Matpower case and create Matpower options
mpc        = case118;

N          = 24;              % number of time periods
Ns         = 10;              % number of storage devices

OPFvoltage = POLAR;           % voltage representation
OPFbalance = POWER;           % type of nodal balance equation
OPFstart   = MPC;             % initial guess
OPFsolver  = BELTISTOSmpopf;  % AC MPOPF solver

mpopt      = create_options(mpc, N, Ns, OPFsolver, OPFstart, OPFvoltage, OPFbalance);

%% prepare storage data
Emax = 2.0; E0 = 0.7; rmax = 1/3; rmin = -1/2; eta_d = 0.97; eta_c = 0.95;
Storages = create_storage_devices(mpc, Ns, Emax, E0, rmax, rmin, eta_d, eta_c);


%% load scaling profile
LoadScaling  = create_load_profile(mpc, N, 'data/TI240hrs.dat');

%% create the multiperiod case
MPmpc = create_multiperiod_mpc(mpc, N, LoadScaling, Storages);

%% solve the MPOPF
[RESULTS, SUCCESS] = runopf(MPmpc, mpopt);
