function LINE(config_file)
% LINE is the main (wrapper) script of the LINE tool
% This function sets the profile of the parallel server using the default 
% local profile
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.
fprintf('\n------------------------------------------------\n');
fprintf('LINE\nLayered Queueing Network Engine\n');
fprintf('Copyright (c) 2012-2017, Imperial College London\n');
fprintf('All rights reserved.\n');
fprintf('------------------------------------------------\n');

setmcruserdata('ParallelProfile', 'lineClusterProfile.settings');
LINEserver(config_file)
end