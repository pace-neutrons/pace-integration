. $PSScriptRoot/../PACE-jenkins-shared-library/powershell_scripts/powershell_helpers.ps1 <# Imports:
  Write-And-Invoke
#>

<#
  .SYNOPSIS
    Extracts a zip archive
  .PARAMETER zipname
    The file to unzip, may include globs
  .PARAMETER newname
    What to name the unzipped item
  .EXAMPLE
    extract_horace_artifact.ps1 "build/Horace-*.zip" "Horace"
#>

# Index "-1" here to deal with case where we may have more than one artifact.
# We always want the last in the list, that will be the latest as they're
# sorted alphabetically
$zip_name_filter = $args[0]
$out_name = $args[1]

try {
  $zip_file = (Get-Item "$zip_name_filter")[-1]
} catch [System.Management.Automation.RuntimeException] {
  Write-Output "Could not find archive matching pattern '$zip_name_filter'"
  exit 1;
}

# Extract the archive to user's temp directory
# We extract to the temp directory instead of the current directory as the path
# lengths can exceed the maximum allowed (255 characters) and the
# "Expand-Archive" command does not offer a renaming utility
Write-Output "Extracting '$zip_file'..."
$extract_cmd = "Expand-Archive -Force -LiteralPath " + $zip_file.FullName
$extract_cmd += " -DestinationPath $env:TEMP"
Write-And-Invoke "$extract_cmd"

# Make sure there's no item already in the working directory with the
# output name. PowerShell will not overwrite directories - even with
# the "-Force" flag
if (Test-Path $out_name) {
  Write-Output "Removing existing  $out_name directory..."
  Write-And-Invoke "Remove-Item -Force -Recurse -Path $out_name"
}

# Move the expanded archive to the current directory and rename
$extraction_path = [IO.Path]::Combine($env:TEMP, $zip_file.BaseName)
Write-And-Invoke "Move-Item -Force -Path $extraction_path -Destination ."
Write-And-Invoke "Rename-Item -Force -Path $($zip_file.BaseName) -NewName $out_name"
try {
  Write-And-Invoke "Remove-Item -Force -Recurse -Path $extraction_path -ErrorAction Stop"
} catch {
  Write-Output "Could not remove directory '$extraction_path'"
}
