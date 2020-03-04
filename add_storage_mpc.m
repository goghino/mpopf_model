function MPmpc_storage = add_storage_mpc(MPmpc, N, Storages, delta_t)
% add_storage_mpc Inserts the storage devices into the mpc structure by
% creating additional 'virtual' generators and the creates the energy constraints.
%
% MPmpc_storage = add_storage_mpc(mpc_multiperiod, N, Storages, TimestepHours)
%
% Outputs
%    MPmpc_storage: Matpower MPOPF case file with the storage devices
%
% Inputs
%   MPmpc     - Multiperiod Matpower case
%   N         - Number of time periods
%   delta_t   - Length of a time period in hours
%   Storages  - Structure containing the following fields:
%                  Buses  - Bus at which storage is installed
%                  E_max  - Max capacity relative to a PD at given bus
%                  E_0    - Initial state of charge, fraction of E_max
%                  Pmax_d - Maximum discharging power in MW 
%                  Pmax_c - Maximum charging power in MW
%                  eta_d  - Discharing coefficient                       
%                  eta_c  - Dharging coefficient

define_constants;

Nbuses                = size(MPmpc.bus,1);       %number of buses in all time periods
nbuses                = Nbuses/N;                %number of buses in a single period
Ngenerators           = size(MPmpc.gen,1);       %number of generators in all time periods 
ngenerators           = Ngenerators/N;           %number of generators in a single period
nstorages             = length(Storages.Buses);  %number of storages in a single period
Nstorages             = nstorages*N;             %number of storages in all time periods
MPmpc_storage         = MPmpc;

mpversion             = mpver; %determine Matpower version

%% create list of the storage device locations
storage_buses   = repmat(Storages.Buses,[N,1]);
offset = 0;
for n = 1:N
    period_n_storages = offset+(1:nstorages); offset = offset + nstorages;
    storage_buses(period_n_storages) = storage_buses(period_n_storages) + (n-1)*nbuses;
end

if find(MPmpc_storage.bus(storage_buses,BUS_TYPE)==REF)
    error('Cannot add storage device to the slack bus')
end

%all storage buses are now PV (previously colud be PQ)
MPmpc_storage.bus(storage_buses,BUS_TYPE) = PV;

    
%% Append the storages to the generator data
ncols = size(MPmpc_storage.gen,2);

%Matpower before v.7.0 uses different ordering of the generators
%(sorted according to increasing bus number in ext2int function)
if (mpversion(1) < '7')
    MPmpc_storage.gen = [MPmpc_storage.gen;
                        %bus Pg Qg Qmax Qmin Vg mBase status Pmax Pmin Pc1 Pc2 Qc1min Qc1max Qc2min Qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
                        [storage_buses, repmat([ones(nstorages,1)*[0 0 0 0 1 0 1],  Storages.Pmax_d,  0*Storages.Pmax_d, zeros(nstorages,ncols-10)], [N,1]) ];  % discharger
                        [storage_buses, repmat([ones(nstorages,1)*[0 0 0 0 1 0 1],0*Storages.Pmax_c,    Storages.Pmax_c, zeros(nstorages,ncols-10)], [N,1]) ]   % charger
                       ]; 
else
    generators =  MPmpc_storage.gen; MPmpc_storage.gen = [];
    period_n_gens = 1:ngenerators;
    period_n_storages = 1:nstorages;
    for i = 1:N
        MPmpc_storage.gen= [MPmpc_storage.gen;
                           generators(period_n_gens, :);
                           %bus Pg Qg Qmax Qmin Vg mBase status Pmax Pmin Pc1 Pc2 Qc1min Qc1max Qc2min Qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
                           [storage_buses(period_n_storages), [ones(nstorages,1)*[0 0 0 0 1 0 1],  Storages.Pmax_d,  0*Storages.Pmax_d, zeros(nstorages,ncols-10)] ];  % discharger
                           [storage_buses(period_n_storages), [ones(nstorages,1)*[0 0 0 0 1 0 1],0*Storages.Pmax_c,    Storages.Pmax_c, zeros(nstorages,ncols-10)]]    % charger 
                          ];
      period_n_gens = period_n_gens + ngenerators;
      period_n_storages = period_n_storages + nstorages;
    end
end

%% generator cost data (zero cost for the storage devices)
% %   1   startup shutdown    n   x1  y1  ... xn  yn
% %   2   startup shutdown    n   c(n-1)  ... c0

if (mpversion(1) < '7')
    MPmpc_storage.gencost = [MPmpc_storage.gencost;
                             ones(nstorages*N*2,1)*[POLYNOMIAL 0 0 3 0 0 0]];
else
    gencost = MPmpc_storage.gencost; MPmpc_storage.gencost = [];
    period_n_gens = 1:ngenerators;
    for i = 1:N
        MPmpc_storage.gencost= [MPmpc_storage.gencost;
                               gencost(period_n_gens, :);
                               ones(nstorages*2,1)*[POLYNOMIAL 0 0 3 0 0 0]];
        period_n_gens = period_n_gens + ngenerators;
    end
end

                   

%% Create linear constraints representing the energy of the storage device
%% x                 = [theta_bus, Vm_bus, P_gen, Q_gen]
%% P_gen             = [ Pgen_1  ...  Pgen_N, Pdischarge_1 ... Pdischarge_N , Pcharge_1 ... Pcharge_N]
%% Pdischarge_i      = [ Pdischarge_1_i  ...   Pdischarge_nstorage_i]
%% Pcharge_i         = [ Pcharge_1_i  ...   Pcharge_nstorage_i]
A                    = sparse(N*nstorages,2*(Nbuses+Ngenerators+2*Nstorages) );
l                    = zeros(N*nstorages,1); 
u                    = l;

M_diag_discharge = sparse(1:nstorages,1:nstorages,1./Storages.eta_d);
M_diag_charge    = sparse(1:nstorages,1:nstorages,Storages.eta_c);

%% 0 < E_0 + B*P1 < E_max
%% 0 < E_0 + B*(P1+P2) < E_max 
%% 0 < E_0 + B*(P1+P2+...) < E_max
%% where Pi = [P_discharge, P_charge]
row_offset = 0;
col_offset_generators = 2*Nbuses; 
col_offset_discharge  = 2*Nbuses+Ngenerators;
col_offset_charge     = 2*Nbuses+Ngenerators+Nstorages;


% gen1 gen2 ... dis1 dis2 ... ch1 ch2 ...
if (mpversion(1) < '7')
    for n = 1:N
        rows = row_offset+(1:nstorages); row_offset = row_offset + nstorages;

        %discharge
        A(rows, col_offset_discharge+(1:(n*nstorages))) = ...
           [ -repmat(MPmpc.baseMVA*delta_t*M_diag_discharge, [1, n])];

        %charge
        A(rows, col_offset_charge+(1:(n*nstorages))) = ...
           [ -repmat(MPmpc.baseMVA*delta_t*M_diag_charge, [1,n])];
    end
% gen1 dis1 ch1, gen2 dis2 ch2, ...    
else
    for n = 1:N
        rows = row_offset+(1:nstorages); row_offset = row_offset + nstorages;

        A_single_period = [sparse(nstorages, ngenerators), ...          %regular generators
                           MPmpc.baseMVA*delta_t*M_diag_discharge, ...  %discharge
                           MPmpc.baseMVA*delta_t*M_diag_charge];        %charge
        
        A(rows, col_offset_generators+(1:(n*(ngenerators+2*nstorages)))) = ...
           [ -repmat(A_single_period, [1, n])];
    end
end
                                                                              
l(1:(N*nstorages)) = repmat(-Storages.E_0,[N,1]);
u(1:(N*nstorages)) = repmat(Storages.E_max-Storages.E_0,[N,1]);


%% Create the storage related fields in the new mpc structure
MPmpc_storage.A                         = sparse(A);
MPmpc_storage.l                         = l;
MPmpc_storage.u                         = u;
clear A;

MPmpc_storage.Storages                  = Storages;
end