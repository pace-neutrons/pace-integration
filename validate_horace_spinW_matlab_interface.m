function err = validate_horace_spinW_matlab_interface(varargin)
% Run unit tests on Horace-spinW integration using MATLAB
%
% Expected to run with github or jenkins actions
%
%
% Exits with non-zero error code if any tests failed
%
if isempty(which('horace_on'))
    horace_path = getenv('HORACE_PATH');
    if isempty(horace_path)
        error('HORACE:validate_horace:runtime_error', 'Horace is not installed and the path to Horace is unknown')
    end
    current_path = pwd;
    spinw_path = fullfile(fileparts(horace_path),'spinw');
    admin_path = fullfile(horace_path,'admin');
    cd(admin_path);
    horace_install('spinW_folder',spinw_path);
    cd(current_path);
end

if isempty(which('horace_init'))
    horace_on();
end

% Parse arguments
% ---------------
options = {'-talkative',  '-nomex',  '-forcemex','-exit_on_completion'};
[ok, mess, talkative, nomex, forcemex, ...
    exit_on_completion,test_folders] = ...
    parse_char_options(varargin, options);
if ~ok
    error('HORACE:validate_horace:invalid_argument', mess)
end

if isempty(test_folders)
    % no tests specified on command line - run them all
    test_folders = ...
        {'test_spinW_horace_matlab', ...
        };
end


% Generate full test paths to unit tests
% --------------------------------------
pths = horace_paths;
test_path = pths.test;
test_folders_full = fullfile(test_path, test_folders);

hor = hor_config();
hpc = hpc_config();
par = parallel_config();
% Validation must always return Horace and Herbert to their initial states,
% regardless of any changes made in the test routines

% On exit always revert to initial Horace and Herbert configurations
% ------------------------------------------------------------------
initial_warn_state = warning();
warning('off', 'MATLAB:class:DestructorError');

% only get the public i.e. not sealed, fields
cur_horace_config = hor.get_data_to_store();
cur_hpc_config = hpc.get_data_to_store();
cur_par_config = par.get_data_to_store();

% remove configurations from memory. Ensure only stored configurations are
% stored
clear config_store;

% Create cleanup object (*** MUST BE DONE BEFORE ANY CHANGES TO CONFIGURATIONS)
cleanup_obj = onCleanup(@() ...
    validate_horace_cleanup(cur_horace_config, ...
    cur_hpc_config, ...
    cur_par_config, ...
    test_folders, ...
    initial_warn_state));

hor.init_tests = true;
% Run unit tests
% --------------
argi = {};
if talkative
    argi = [argi, {'-verbose'}];
end

test_ok = false(1, numel(test_folders_full));
time = bigtic();
for i = 1:numel(test_folders_full)
    test_stage_reset(i, hor, hpc, par, nomex, forcemex, talkative);
    test_ok(i) = runtests(test_folders_full{i}, argi{:});
end

bigtoc(time,  '===COMPLETED UNIT TESTS RUN ');


close all
clear config_store;

err = ~all(test_ok);

if exit_on_completion
    exit(err);
end

end
%-------------------------------------------------------------------------------
function test_stage_reset(icount, hor, hpc, par, nomex, forcemex, talkative)
% Run before each stage
% Set Horace configurations to the defaults (but don't save)
% (The validation should be done starting with the defaults, otherwise an error
%  may be due to a poor choice by the user of configuration parameters)

% Set the default configurations, printing warning only the first time round to
% avoid copious warning messages
warn_state = warning();
cleanup_obj = onCleanup(@()warning(warn_state));
if icount>1
    warning('off',  'all');
end

set(hor, 'defaults');
set(hpc, 'defaults');
% set(par, 'defaults');

% Return warning state to incoming state
warning(warn_state)

% Special unit tests settings.
hor.init_tests = true; % initialise unit tests
hor.use_mex = ~nomex;
hor.force_mex_if_use_mex = forcemex;

if talkative
    hor.log_level = 1; % force log level high.
else
    hor.log_level = -1; % turn off informational output
end

end
%--------------------------------------------------------------------------
function validate_horace_cleanup(cur_horace_config, cur_hpc_config, ...
    cur_par_config, test_folders, initial_warn_state)
% Reset the configurations, and remove unit test folders from the path

set(hor_config, cur_horace_config);
set(hpc_config, cur_hpc_config);
set(parallel_config, cur_par_config);

warning('off',  'all'); % avoid warning on deleting non-existent path

% Clear up the test folders, previously placed on the path
for i = 1:numel(test_folders)
    rmpath(test_folders{i});
end

warning(initial_warn_state);
end
