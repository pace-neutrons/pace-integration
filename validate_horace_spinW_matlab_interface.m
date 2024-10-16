function err = validate_horace_spinW_matlab_interface(varargin)
% Run unit tests on Horace-spinW integration using MATLAB
%
% Expected to run with github or jenkins actions
%
%
% Exits with non-zero error code if any tests failed
% TODO: Currently throws HORACE:spinw_validation:runtime_error if any test fails
%       This should be fixed by modifying github actions workflow to
%       correctly process return codes
% NOTE:
% This scipt is extract from validate_horace script.
%%
horace_path = getenv('HORACE_PATH');
% expect spinW is located alongside Horace in the same folder.
install_horace_and_spinw(horace_path);

if isempty(which('horace_init'))
    % enable Horace if not already enabled
    horace_on();
else
    fprintf("**********   Horace already initialized\n")
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
% This is not a good practice but what is currently supported by github
% actions
% TODO:
% make it more aligned with standard unit test practice. Change will
% probably affect this and gihub actions workflow.
if err
    n_failed = sum(~test_ok);
    error('HORACE:spinw_validation:runtime_error', ...
        '%d out of %d unit tests have failed',n_failed,numel(test_ok));
end

end


function install_horace_and_spinw(horace_path)
% Given horace_path, install horace and spinw if Horace has not been
% installed.
% If Horace was installed, we expect horace_on script initialize spinw.
%
% spinw expected to be located alongside Horace
%
% store reference point to avoid function's side-effects
current_path = pwd;

if isempty(which('horace_on'))
    fprintf("**********   Installing Horace with spinw\n")
    % install Horace first

    if isempty(horace_path)
        % are we already in the folder requested?
        this_path = fullfile(fileparts(mfilename("fullpath")));
        if isfolder(fullfile(this_path,'admin'))
            horace_path = this_path;
        else
            error('HORACE:validate_horace:runtime_error', ...
                'Horace is not installed and the path %s does not refer to Horace', ...
                this_path)
        end
    end
    spinw_path = fullfile(fileparts(horace_path),'spinw_git');

    if ~isfolder(spinw_path)
        error('HORACE:validate_horace:runtime_error', ...
            'Can not find spinW at path: %s',spinw_path);
    else
        cd(spinw_path)
        install_spinw('silent',true);
    end
    if isfile(fullfile(horace_path,'horace_install.m'))
        admin_path  = horace_path;
    else
        admin_path = fullfile(horace_path,'admin');  % do not check further
        % it will fail on the next step anyway, if not found
    end

    cd(admin_path);
    horace_install('spinW_folder',spinw_path);
    %horace_install();
    cd(current_path);
    fprintf("**********   completed Horace&SpinW installation\n")
else
    fprintf("**********   Horace already installed. SpinW should be initialized by horace_on\n")
end
end