. $PSScriptRoot/../PACE-jenkins-shared-library/powershell_scripts/powershell_helpers.ps1 <# Imports:
  Get-From-Registry
#>

<#
  .SYNOPSIS
    Runs a Matlab script to run integration tests
  .DESCRIPTION
    Gets the Matlab command from registry and runs it
  .NOTES
    Required environment variables:
      MATLAB_VERSION - Matlab version to use e.g. 2019b
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

# Get Matlab root directory from registry, and path to MATLAB exe
$MATLAB_REG = Get-From-Registry "HKEY_LOCAL_MACHINE\SOFTWARE\Mathworks\MATLAB\$($MATLAB_VERSION_MAP[$Env:MATLAB_VERSION])"
$MATLAB_ROOT = ($MATLAB_REG).MATLABROOT

. $MATLAB_ROOT/bin/matlab.exe -nosplash -nodesktop -batch "run('iron_spinwaves/run_spinw_horace_test.m')"
