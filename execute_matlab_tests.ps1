MATLAB_VERSION_MAP = @{
  '2018a' = '9.4';
  '2018b' = '9.5';
  '2019a' = '9.6';
  '2019b' = '9.7';
  '2020a' = '9.8';
  '2020b' = '9.9';
}

# Hardcode Python path for now, as we can't currently load Conda in Powershell
#Write-And-Invoke 'conda activate py36_pace_integration'
#Set-Item -Path Env:PYTHON_EX_PATH -Value ('where python')
Set-Item -Path Env:PYTHON_EX_PATH -Value ('C:\Programming\miniconda3\envs\py36_pace_integration\python')

$MATLAB_ROOT = (Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Mathworks\MATLAB\$($MATLAB_VERSION_MAP[$Env:MATLAB_VERSION])).MATLABROOT
$MATLAB_PROCESS = Start-Process -FilePath "$MATLAB_ROOT\bin\matlab.exe" -Wait -PassThru -ArgumentList '-nosplash', '-nodesktop', '-wait', '-batch', 'setup_and_run_tests'

exit $MATLAB_PROCESS.ExitCode
