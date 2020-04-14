#Convert a curseforge manifest json to ids txt format 
$legibleModFileNames=$true
$executionPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$localFiles = Get-ChildItem -Path $executionPath -Name '*.json' -File
$path = $executionPath+"\Ids"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}


function filenameWithoutNumbers{
     param( $filename)
     $expression="[\d.\[\]\(\)-]+"     
     $salida=""
     $firstMinus=$true
     for ($a=0;$a -lt $filename.Length;$a++){
        
        $char=$filename.substring($a, 1)
        if ($char -match $expression){
            if ($char -eq "-" -and $firstMinus){
                $salida=$salida+$char
                $firstMinus=$false
            }else{                
                if( $a+1 -lt $filename.Length){
                    $char=$filename.substring($a+1, 1)
                    while ($a+1 -lt $filename.Length -and $char -match $expression) {
                        $a++  
                        if ($a+1 -lt $filename.Length ) {$char=$filename.substring($a+1, 1)}
                    }
                }   
                if($legibleModFileNames){                
                    if($a+1 -lt $filename.Length)
                        {$salida=$salida+"("+$expression+")"} #if legible is on try to not concatenate the expression at the end 
                }else
                        {$salida=$salida+"("+$expression+")"
                        if ($a+1 -ge $filename.Length){$salida+=".jar"}
                    
                }
            }

            
        }else{$salida=$salida+$char}

     }
     return $salida
    
}


$api='https://addons-ecs.forgesvc.net/api/v2/addon/'
$clientWeb = New-Object System.Net.WebClient
foreach ($localfile in $localFiles){
    $contenido=(get-content $localfile.PSPath)| ConvertFrom-Json
    $tipo=$contenido.manifestType
    if($tipo -eq 'minecraftModpack'){

        
        $version=$contenido.minecraft.version
        $DestFilePath=$path+"\"+$localfile+".txt"

        "#version;"+$version| Out-File $DestFilePath 
        "#Format Id;FileNameRegularexpression;Type;Version" | Out-File $DestFilePath  -Append
        "#"| Out-File $DestFilePath -Append

        $ficheros=$contenido.files
        $modIdArray=@()
        foreach ($f in $ficheros){
           $modId=$f.projectID
           $modIdArray+=$modId
           $fileId=$f.fileID

           $requestfile= $api+$modId+'/file/'+$fileId
           #https://addons-ecs.forgesvc.net/api/v2/addon/{addonID}/file/{fileID}
           $fileInfo=""
           $fileInfo= Invoke-WebRequest $requestfile|ConvertFrom-Json |select fileName,downloadURL
           $cadenaNombre=filenameWithoutNumbers($fileInfo.fileName.substring(0,$fileInfo.fileName.Length-4))
           Write-Host  $modId ":" $fileInfo.fileName
           $modId.ToString()+";"+$cadenaNombre| Out-File $DestFilePath -Append

        }
        <#
        [string]$modIdArrayString="["+($modIdArray -join ",") +"]"
        $response=Invoke-WebRequest -UseBasicParsing $api -ContentType "application/json" -Method POST -Body ($modIdArrayString)|ConvertFrom-Json
        $addons=@()
        $addons=$response|Select-Object *
        #>

    }

}