function [t, y] = ScaleData(t0, data)

	data_min = min(data);
	data_max = max(data);

	y        = (data - data_min) / (data_max - data_min);
    
    t0_min   = min(t0);
    t0_max   = max(t0);

    t        = 2*pi * (t0 - t0_min)/(t0_max - t0_min); 
end