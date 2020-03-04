function MPmpc = create_multiperiod_mpc(mpc, N, LoadScaling, Storages)
% create_multiperiod_mpc Creates a multiperiod case file from a given mpc,
% load scaling and storages.
%
% MPmpc = create_multiperiod_mpc(mpc, N, LoadScaling, Storages)
%
% Outputs
%    MPmpc: Matpower case file representing the MPOPF problem
%
% Inputs
%   mpc         - Nominal Matpower case
%   N           - Number of time periods
%   LoadScaling - Structure with the load scaling data
%                  profile - scaling coefficients relative to the base load
%                            defined in the mpc
%                  delta_t - length of a time period in hours                                       
%   Storages    - Structure containing the following fields:
%                  Buses  - Bus at which storage is installed
%                  E_max  - Max capacity relative to a PD at given bus
%                  E_0    - Initial state of charge, fraction of E_max
%                  Pmax_d - Maximum discharging power in MW 
%                  Pmax_c - Maximum charging power in MW
%                  eta_d  - Discharing coefficient                       
%                  eta_c  - Dharging coefficient

    if N < 2
        MPmpc = mpc;
        return;
    end
    assert(N==size(LoadScaling.profile,1));
    define_constants;

    %fix the mpc
    mpc = ext2int(mpc);
    mpc.branch(mpc.branch(:,RATE_A)==0,RATE_A) = 9900; %all lines need to have flow limit
    mpc.gen(:,PMIN) = 0;


    %% create multiperiod case by repeating the base mpc
    MPmpc = repmpc(mpc, LoadScaling.profile);

    %% add the storage devices represented by additional generators
    MPmpc = add_storage_mpc(MPmpc, N, Storages, LoadScaling.delta_t);
end 


function MPmpc = repmpc(mpc, LoadScalingMatrix)
%repmpc Replicates the base mpc for each time period and scales
%the load according to the load scaling profile.
%
%function MPmpc      = repmpc(mpc, LoadScalingMatrix)
%
%Outputs
%    MPmpc: Matpower case file representing the MPOPF problem
%
% Inputs
%   mpc                   - Nominal Matpower case  
%   LoadScalingMatrix     - Scaling of the nominal load over the time horizon

    define_constants;

    N               = length(LoadScalingMatrix);
    nb              = size(mpc.bus,1);
    nl              = size(mpc.branch,1);
    ng              = size(mpc.gen,1);

    if not(min(mpc.bus(:,1) == (1:nb)'))
        error('Buses not properly numbered, concecutive numbering 1:nnodes is required');
    end

    % create the multiperiod case by copying some information first
    MPmpc.version       = mpc.version;
    MPmpc.baseMVA       = mpc.baseMVA;

    % replicate the bus matrix for each time period and do the load scaling
    MPmpc.bus           = repmat(mpc.bus,[N,1]);
    MPmpc.bus(:,BUS_I)  = 1:(nb*N);
    offset = 0;
    for n = 1:N
        period_n = offset+(1:nb); offset = offset + nb;
        MPmpc.bus(period_n,PD)     = MPmpc.bus(period_n,PD).*LoadScalingMatrix(n); 
        MPmpc.bus(period_n,QD)     = MPmpc.bus(period_n,QD).*LoadScalingMatrix(n);
    end

    % replicate the branch matrix for each time period and fix the bus indexing
    MPmpc.branch          = repmat(mpc.branch,[N,1]);
    offset = 0;
    for n = 1:N
        period_n = offset+(1:nl); offset = offset + nl;
        MPmpc.branch(period_n,F_BUS) = MPmpc.branch(period_n,F_BUS) + (n-1)*nb;
        MPmpc.branch(period_n,T_BUS) = MPmpc.branch(period_n,T_BUS) + (n-1)*nb;
    end

    % replicate the generator and its cost matrix for each time period
    MPmpc.gen                 = repmat(mpc.gen,[N,1]);
    MPmpc.gencost             = repmat(mpc.gencost,[N,1]); %% same marginal cost for all time steps
    offset = 0;
    for n = 1:N
        period_n = offset+(1:ng); offset = offset + ng;
        MPmpc.gen(period_n,GEN_BUS)      = MPmpc.gen(period_n,GEN_BUS) + (n-1)*nb;
    end
end
