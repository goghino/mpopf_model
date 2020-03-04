function buses = get_storage_locations(mpc, Ns)
%get_storage_locations Returns locations of the storage devices.
%
% buses = get_storage_locations(mpc, Ns)
%
% Outputs
%    buses: Vector of bus indices, indicating the location
%           of the storage devices. Devices are located at 
%           the buses with the largest load, exept the slack bus.
%
% Inputs
%   mpc: Matpower case file
%   Ns: Number of storage devices

    define_constants;

    [load_sorted, load_sorted_buses] = sort(mpc.bus(:,PD), 'descend');
    Ns_applied = min(Ns,length(load_sorted));
    buses = load_sorted_buses(1:Ns_applied);

    % Do not place storage to the REF bus
    ref_idx = find(mpc.bus(buses, BUS_TYPE) == 3);
    if(ref_idx)
        buses(ref_idx) = [];
        if(length(load_sorted_buses) >= Ns_applied+1 )
        buses = [buses; load_sorted_buses(Ns_applied+1)];
        end
    end

    if(Ns_applied < 1)
       error('Number of storateges has to be > 0');
    elseif (Ns_applied ~= Ns)
       error('Could not determine location for all requested storage devices');
    end

end