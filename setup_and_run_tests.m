% Set up Python
py_ex_path = getenv('PYTHON_EX_PATH');
try
  % Pyenv only introduced in 2019b
  pyenv('Version', py_ex_path);
catch ME
  if (strcmp(ME.identifier,'MATLAB:UndefinedFunction'))
    % Pyversion is deprecated but use if pyenv not available
    pyversion(py_ex_path);
  else
    rethrow(ME);
  end
end

% Load Horace
addpath(['Horace' filesep 'Herbert']);
herbert_init;
addpath(['Horace' filesep 'Horace']);
horace_init;

% Install Horace-Euphonic-Interface
matlab.addons.toolbox.installedToolboxes
matlab.addons.toolbox.installToolbox(['mltbx' filesep 'horace_euphonic_interface.mltbx']);
matlab.addons.toolbox.installedToolboxes

% Run test script
run('run_euphonic_integration.m');
