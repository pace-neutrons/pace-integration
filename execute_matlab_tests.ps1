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
Try {
  $MATLAB_REG = Get-ItemProperty `
    Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Mathworks\MATLAB\$($MATLAB_VERSION_MAP[$Env:MATLAB_VERSION]) `
    -ErrorAction Stop
} Catch [System.Management.Automation.ItemNotFoundException] {
  Write-Error ("Couldn't find Matlab in the Windows registry, ensure this Matlab version is " +
               "definitely installed and the correct Powershell architecture is being used. A 32-bit " +
	       "Powershell may not be able to search a 64-bit registry and vice versa`n$($_.Exception)")
}
$MATLAB_ROOT = ($MATLAB_REG).MATLABROOT

# Set up Matlab and run tests
$MATLAB_PROCESS = Start-Process `
  -FilePath "$MATLAB_ROOT\bin\matlab.exe" `
  -Wait `
  -PassThru `
  -ArgumentList '-nosplash', '-nodesktop', '-wait', '-batch', 'setup_and_run_tests'

exit $MATLAB_PROCESS.ExitCode
