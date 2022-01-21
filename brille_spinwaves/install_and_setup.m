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

% Get and install the brillem toolbox
toolboxes = matlab.addons.toolbox.installedToolboxes;
for i = 1:length(toolboxes)
    if strcmp(toolboxes(i).Name, 'brillem')
        matlab.addons.toolbox.uninstallToolbox(toolboxes(i));
        break;
    end
end
% Going back to using Python because matlab is shoddy:
% https://www.mathworks.com/matlabcentral/answers/443968-unix-curl-with-https-fails-with-error-77-workarounds
%import matlab.net.http.*
%request = RequestMessage(RequestMethod.GET);
%response = request.send('http://api.github.com/repos/brille/brillem/releases');
%opts = weboptions('HeaderFields', {'Accept', 'application/octet-stream'}, ...
%                  'CertificateFilename', '');
%websave('brillem.mltbx', response.Body.Data(1).assets.url, opts); % Newest release is first
matlab.addons.toolbox.installToolbox('brillem.mltbx');
matlab.addons.toolbox.installedToolboxes
