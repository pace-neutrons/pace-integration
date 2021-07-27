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
cd('Horace')
horace_install
cd('..')
horace_on

% Install Horace-Euphonic-Interface
toolboxes = matlab.addons.toolbox.installedToolboxes;
for i = 1:length(toolboxes)
    if strcmp(toolboxes(i).Name, 'horace_euphonic_interface')
        matlab.addons.toolbox.uninstallToolbox(toolboxes(i));
        break;
    end
end
matlab.addons.toolbox.installToolbox(['mltbx' filesep 'horace_euphonic_interface.mltbx']);
matlab.addons.toolbox.installedToolboxes

% Run tests
res = runtests('EuphonicDisp2SqwTest.m');
passed = [res.Passed];
if ~all(passed)
    quit(1);
end
