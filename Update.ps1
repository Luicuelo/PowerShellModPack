
#Luis Cuesta.2019..
#if you dont want new files to be download set download to $false
clear

$download=$true 
$api='https://addons-ecs.forgesvc.net/api/v2/addon/'
#$api='https://curse.nikky.moe/api/addon/'


$ids=get-content .\ids.txt
$version=$ids[0].Split(";")[1]


# PowerShell v2
$executionPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$modPath = $executionPath.Substring(0, $executionPath.LastIndexOf('\'))
$localFiles = Get-ChildItem -Path $modPath -Name '*.jar' -File

$path = $modPath+"\New"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

$clientWeb = New-Object System.Net.WebClient

#https://twitchappapi.docs.apiary.io/#/reference/0/get-multiple-addons/get-multiple-addons/
#get all the addons 

$modIdArray=@()
foreach ($linea in $ids){
    $fields=$linea.Split(";")
    $modId=$fields[0].ToString()

    if ($modId.Substring(0,1) -ne "#"){
        $modIdArray+=$modId
    }
}

[string]$modIdArrayString="["+($modIdArray -join ",") +"]"

#$modIdArrayString="[72210]"
$response=Invoke-WebRequest -UseBasicParsing $api -ContentType "application/json" -Method POST -Body ($modIdArrayString)|ConvertFrom-Json
$addons=@()
$addons=$response|Select-Object *


foreach ($linea in $ids){
    $fields=$linea.Split(";")
    $modId=$fields[0].ToString()
    $modName=$fields[1]
    $modFileType=$fields[2]
    $modVersion=''
    $modVersion=$fields[3]

    if ([string]::IsNullOrEmpty($modFileType)){
        $modFileType='1'
     } #si no se fuerza un tipo ponemos 1

	$progressPreference = 'silentlyContinue' 
	
    if($modId.Substring(0,1) -ne "#"){


                $last =$null
                $last = $addons |Where-Object {$_.id -eq $modId}

                $tversion=$version
                if($modVersion -gt '') {
                    $tversion=$modVersion
                }

                $list=$null
                $idList=$null 

                if($last -ne $null){
                    $list= $last|select -expand  gameVersionLatestFiles |Select gameVersion,projectFileID,projectFileName,fileType,modLoader | where {($_.gameVersion -eq $tversion)  -and ($_.fileType -ne 'ALPHA')}
                }
                

                if  ($list.fileType -contains $modFileType) {
                        $list=$list  | where {($_.fileType -eq $modFileType)} 
                }else{

                        if  ($list.fileType -contains '2') {
                            $list=$list  | where {($_.fileType -eq '2')} 
                        }

                }

                
                if  ($list.modLoader -contains '1') {
                        $list=$list  | where {($_.fileType -eq '1')} 
                }

                


                $idList=$null
                $idList=$list.projectFileID
                
                $newfilename=$list.projectFileName
				Write-Host  $modName ":" $list.fileType ":" $modId ":" $tversion ":" $newfilename
                if ($idList  -eq $null) {Write-Host "File not found" -ForegroundColor red }
                if($idList -ne $null){
                            $idList=$idList[0] #cogemos solo uno si hay varios.                                                
                            if($modName.Substring(0,1) -eq "["){
                                $modName="\"+$modName}
							$expresion='^'+$modName                            
                            
                            $localFile =($localFiles -match  $expresion)
                            $fileExists = ($localFiles -contains  $newfilename)
               
                                                             
                            #ijf only there are a localfile -match devuelve false , not empty, 
                            $empty=([string]::IsNullOrEmpty($localFile) -or (-Not $localFile ))
                            #if (-not $fileExists -or $empty ){								
							if (-not $fileExists){

                                    #Solo recuperamos datos del archivo si es necesario porque no coincide
                                    $requestfile= $api+$modId+'/file/'+$idList
                                    $file=""
                                    $file= Invoke-WebRequest $requestfile|ConvertFrom-Json |select fileName,downloadURL                                    
                                    Write-Host  "--------------"  $newfilename "<->" $localFile 
                                    if($file.fileName -eq ""){Write-Host  "Fallo recuperando archivo"}
                                    else {



                                            #Write-Host $file.downloadURL     
                                            if ($download){
                                                $rutaNuevo=$modPath+"\"+"New\"+$newfilename                                    
                                                $yaExiste=(Test-Path $rutaNuevo -PathType Leaf)
                                                if(-not  $yaExiste ){
                                                    if (-not($empty)){                                            
                                                        $localFilePath=  $modPath+"\"+$localFile 
                                                        $newName="__"+$localFile     
                                                        Rename-Item -Path $localFilePath -NewName $newName
                                                    }
                                                    $clientWeb.DownloadFile($file.downloadURL, $modPath+"\"+"New\"+$newfilename)
                                                }
                                            }
                                    }  
                                }         
                    
                }else {
							Write-Host $modName " Not Found"
                }
    }

}
