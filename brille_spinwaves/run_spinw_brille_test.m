% Set up Python
py_ex_path = getenv('PYTHON_EX_PATH');
disp(py_ex_path)
try
  % Pyenv only introduced in 2019b
  pyenv('Version', py_ex_path)
catch ME
  if (strcmp(ME.identifier,'MATLAB:UndefinedFunction'))
    % Pyversion is deprecated but use if pyenv not available
    pyversion(py_ex_path)
  else
    rethrow(ME);
  end
end

% Install and load Horace
this_dir = fileparts(mfilename('fullpath'));
parent_dir = split(this_dir, filesep);
parent_dir = join(parent_dir(1:end-1), filesep);
parent_dir = parent_dir{1};
cd(fullfile(parent_dir, 'Horace'));
horace_install;
horace_on;
addpath(genpath(fullfile(parent_dir, 'spinw')));
cd(parent_dir);
addpath('brille_spinwaves');

toolboxes = matlab.addons.toolbox.installedToolboxes;
for i = 1:length(toolboxes)
    if strcmp(toolboxes(i).Name, 'brillem')
        matlab.addons.toolbox.uninstallToolbox(toolboxes(i));
        break;
    end
end
matlab.addons.toolbox.installToolbox('brillem.mltbx');
matlab.addons.toolbox.installedToolboxes

%% Runs the actual test
proj = projaxes([1, 0, 0], [0, 1, 0], 'type', 'rrr');
w1 = cut_sqw('brille_spinwaves/pcsmo_cut1.sqw', proj, ...
             [-1, 0.05, 1], [-1, 0.05, 1], [-10, 10], [10, 20]);

Jvec = [-11.39, 1.5, -1.35, 1.5, 0.88, 0.074];
Jv = mat2cell(Jvec,1,ones(1,6)); [J1,J2,J3,J4,J5,J6] = Jv{:};
swo = pcsmo_model(J1, J2, J3, J4, J5, J6);

cpars = {'mat', {'JF1', 'JA', 'JF2', 'JF3', 'Jperp', 'D(3,3)'}, ...
    'hermit', false, 'useFast', false, 'formfact', true, ...
    'resfun', 'gauss', 'coordtrans', diag([2 2 1 1]), ...
    'optmem', 100};

frac = 1e-6;
cpars_brille = {'use_brille', true, 'node_volume_fraction', frac, ...
    'use_vectors', false, 'Qtrans', diag(1./[4 4 1])};

%w1 = mask_random_fraction_pixels(w1, 0.1);
rng(12345, 'twister')
kk = multifit_sqw(w1);
kk = kk.set_fun(@swo.horace_sqw, {[J1 J2 J3 J4 J5 J6 0.1] cpars{:}});
tic
wsim = kk.simulate();
tsim = toc;
fprintf('Time to run SpinW normally = %0.2f s\n', tsim)

rng(12345, 'twister')
kk = multifit_sqw(w1);
kk = kk.set_fun(@swo.horace_sqw, {[J1 J2 J3 J4 J5 J6 0.1] cpars{:} cpars_brille{:}});
tic
wbrille = kk.simulate();
tbrille = toc;
fprintf('Time to run SpinW with Brille = %0.2f s\n', tbrille)
fprintf('Speed up factor = %0.4f\n', tsim/tbrille)

err = sum(sum(abs(wsim.data.s - wbrille.data.s))) / numel(wsim.data.s) / mean(wsim.data.s(:));
fprintf('Relative per bin error in calculation = %0.2f %%\n', err*100)
% 0.3169 % frac=1e-6
% 0.5135 % frac=1e-5
%err = sum(abs(wsim.data.pix.signal - wbrille.data.pix.signal)) / wsim.data.num_pixels / mean(wsim.data.pix.signal)
% 0.8397 % frac=1e-6
% 1.4911 % frac=1e-5

if (err > 1)
    disp('FAILURE: relative error too large');
    quit(1)
end
disp('SUCCESS');
