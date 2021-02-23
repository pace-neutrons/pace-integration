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

# Set up Matlab and run tests
# Must be run via System.Diagnostics rather than Start-Process to redirect
# output to stdout/err and enable it to be seen in the powershell console
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "$MATLAB_ROOT\bin\matlab.exe"
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = '-nosplash', '-nodesktop', '-wait', '-batch', 'setup_and_run_tests'
$pinfo.WorkingDirectory = $Env:WORKSPACE
$pinfo | Select-Object

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
Write-Output "stdout: $stdout"
Write-Output "stderr: $stderr"
Write-Output "exit code: " + $p.ExitCode

exit $p.ExitCode
