. $PSScriptRoot/powershell_helpers.ps1 <# Imports:
  Write-And-Invoke, Get-From-Registry, Get-Conda-Env-Dir
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

# Get path to Conda environment Python, and set as environment variable to
# be accessed by the Matlab test script
$CONDA_ENV_DIR = Get-Conda-Env-Dir
Write-Output "$CONDA_ENV_DIR"
$PYTHON_EX_PATH = "$CONDA_ENV_DIR\python"
Write-And-Invoke "Set-Item -Path Env:PYTHON_EX_PATH -Value $PYTHON_EX_PATH"

# Get Matlab root directory from registry, and path to MATLAB exe
$MATLAB_REG = Get-From-Registry "HKEY_LOCAL_MACHINE\SOFTWARE\Mathworks\MATLAB\$($MATLAB_VERSION_MAP[$Env:MATLAB_VERSION])"
$MATLAB_ROOT = ($MATLAB_REG).MATLABROOT

. $MATLAB_ROOT\bin\matlab.exe -nosplash -nodesktop -wait -batch "setup_and_run_tests"
