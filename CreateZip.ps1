#### 7 zip variable I got it from the below link  
 
#### http://mats.gardstad.se/matscodemix/2009/02/05/calling-7-zip-from-powershell/  
# Alias for 7-zip 
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe" 
 
############################################ 
#### Variables  

class Config {
    [string]$author
    [string]$modLoader
    [string]$version
    [string]$name
    [string[]]$foldersOverrides
    [string[]]$filesOverrides
}



$Destination=[string](Get-Location)
Set-Location -Path $Destination+"\..\.."   #we assume the script is running in a subfolder of mods
$configFile=$Destination+"\Config.json"
[Config]$config=Get-Content $configFile | Out-String | ConvertFrom-Json



$zipfile = $config.name+".zip"
foreach ($f in $config.foldersOverrides){
    sz a -tzip "$Destination\$zipfile"  ($f)
    sz  rn "$Destination\$zipfile"  ($f) "overrides\$f"
}

foreach ($f in $config.filesOverrides){
    sz a -tzip "$Destination\$zipfile"  ($f)
    sz  rn "$Destination\$zipfile"  ($f) "overrides\$f"
}

Set-Location -Path $Destination
sz a -tzip "$Destination\$zipfile"  "manifest.json"
