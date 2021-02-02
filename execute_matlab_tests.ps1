. $PSScriptRoot/powershell_helpers.ps1 <# Imports:
  Write-And-Invoke
#>

$ErrorActionPreference = 'Stop'

$MATLAB_VERSION_MAP = @{
  '2018a' = '9.4';
  '2018b' = '9.5';
  '2019a' = '9.6';
  '2019b' = '9.7';
  '2020a' = '9.8';
  '2020b' = '9.9';
}

# Set Python for Matlab to use
Write-And-Invoke 'conda activate py36_pace_integration'
Set-Item -Path Env:PYTHON_EX_PATH -Value (Get-Command python).Source

# Get Matlab root directory from registry
$MATLAB_ROOT = (Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MathWorks\MATLAB\$($MATLAB_VERSION_MAP[$Env:MATLAB_VERSION])).MATLABROOT

# Set up Matlab and run tests
$MATLAB_PROCESS = Start-Process -FilePath "$MATLAB_ROOT\bin\matlab.exe" -Wait -PassThru -ArgumentList '-nosplash', '-nodesktop', '-wait', '-batch', 'setup_and_run_tests'

exit $MATLAB_PROCESS.ExitCode
