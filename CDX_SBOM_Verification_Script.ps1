<#
.Synopsis
   CDX_SBOM_Verification_Script.ps1 - 2.1 - 03.2024 - Author: V3ct0r
.DESCRIPTION
   In the current folder uses cyclonedx-win-x64.exe to validate .cdx.json BOM files format
.EXAMPLE
   Run the Script in the same folder as cyclonedx-win-x64.exe see https://github.com/CycloneDX/cyclonedx-cli/releases
#>

## Get to the current script folder and naviogate to it
$Scriptlocation = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $Scriptlocation
if (Test-Path -Path .\cyclonedx-win-x64.exe -PathType Leaf) {
   Write-Host ("cyclonedx-win-x64.exe found!")  -ForegroundColor DarkGreen -BackgroundColor Green

   $projectName = Read-Host "Enter the name and version of the Project [Will append to the resulting zip file]"

   ##Clean the folder from previous log files
   Get-ChildItem *.log | ForEach-Object { Remove-Item -Path $_.FullName }

   ## Start Logging with current timestamp
   $Stamp = (Get-Date).toString("yyyyMMdd_HHmmss")
   $logfile = "$Scriptlocation\SBOM_Validation_Script_Log_$Stamp.log"
   Start-Transcript -Path $logfile -NoClobber -Force -IncludeInvocationHeader

   ## Get current file listing of pwd
   Get-ChildItem

   ## Get Version of cyclonedx-win-x64.exe
   Write-Host ("`nCyclonedx-win-x64.exe version:") 
   .\cyclonedx-win-x64.exe --version | out-default

   # File list to be Zipped
   $ZipfileList = @()

   Get-ChildItem -Path .\ -Filter *.cdx.json -Recurse -File -Name | ForEach-Object {
      $ZipfileList += "$Scriptlocation\$_"
      write-host ("`n")
      [System.IO.Path]::GetFileNameWithoutExtension($_)
      Get-FileHash -Algorithm SHA512 $_
      .\cyclonedx-win-x64.exe validate --input-file .\$_ --input-format json --input-version v1_4 | out-default
   }

   $ZipfileList += $logfile
   $ZipfileList += "$Scriptlocation\CDX_SBOM_Verification_Script.ps1 "

   $ZipfileName = "CDX_SBOM_$projectName-$Stamp"

   Write-Host ("Results in $ZipfileName :")
   $ZipfileList

   Stop-Transcript

   $destinationZipPath = "$Scriptlocation\$ZipfileName.zip"
   # Compress the individual files into a ZIP file
   Compress-Archive -Path $ZipfileList -DestinationPath $destinationZipPath

   #Delete trasncript
   Remove-Item -Path $logfile

}
else {
   Write-Host ("cyclonedx-win-x64.exe NOT found!")  -ForegroundColor DarkRed -BackgroundColor Red
}

