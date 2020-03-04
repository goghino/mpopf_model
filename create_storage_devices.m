function Storages = create_storage_devices(mpc, Ns, Emax, E0, rmax, rmin, eta_d, eta_c)
% create_storage_devices Creates storage device with specified properties.
%
% function Storages = create_storage_devices(mpc, Ns, Emax,  E0,  rmax,  rmin,  eta_d,  eta_c)
%
% Outputs
%   Storages  - Structure containing the following fields:
%                  Buses  - Bus at which storage is installed
%                  E_max  - Max capacity relative to a PD at given bus
%                  E_0    - Initial state of charge, fraction of E_max
%                  Pmax_d - Maximum discharging power in MW 
%                  Pmax_c - Maximum charging power in MW
%                  eta_d  - Discharing coefficient                       
%                  eta_c  - Dharging coefficient
% Inputs
%   mpc      - Matpower case 
%   Ns       - Number of installed storage devices
%   Emax     - Max capacity, fraction of PD at the given bus
%   E0       - Initial state of charge, fraction of E_max
%   rmax     - Maximum discharging rate, fraction of the capacity, MW_per_MWh
%   rmin     - Maximum charging rate, fraction of the capacity, MW_per_MWh 
%   eta_d    - Discharing coefficient                       
%   eta_c    - Charing coefficient                        

    Storages = [];
    if (Ns < 1)
        return;
    end

    define_constants;
    
    % location of storage devices
    Storages.Buses   =  get_storage_locations(mpc, Ns);        
    % storage capacity in MWh
    Storages.E_max   =  Emax * abs(mpc.bus(Storages.Buses,PD));  
    % initial charge in MWh
    Storages.E_0     =  E0 * Storages.E_max;                   
    % maximum discharging power in MW
    Storages.Pmax_d   =  rmax * Storages.E_max;                
    % maximum charging power in MW
    Storages.Pmax_c   =  rmin * Storages.E_max;               
    % discharging efficiency coefficient
    Storages.eta_d   =  eta_d;                                  
    % charging efficiency coefficient
    Storages.eta_c   =  eta_c;                                  
end