
#Luis Cuesta.2019..
#if you dont want new files to be download set download to $false

$download=$true 
$api='https://addons-ecs.forgesvc.net/api/v2/addon/'


$ids=get-content .\ids.txt
$version=$ids[0].Split(";")[1]


# PowerShell v2
$executionPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$executionPath = $executionPath.Substring(0,$executionPath.length-10)
$localFiles = Get-ChildItem -Path $executionPath -Name '*.jar' -File

$path = $executionPath+"\New"
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

$response=Invoke-WebRequest -UseBasicParsing https://addons-ecs.forgesvc.net/api/v2/addon -ContentType "application/json" -Method POST -Body ($modIdArrayString)|ConvertFrom-Json
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
                    $list= $last|select -expand  gameVersionLatestFiles |Select gameVersion,projectFileID,projectFileName,fileType | where {($_.gameVersion -eq $tversion)  -and ($_.fileType -ne 'ALPHA')}
                }
                

                if  ($list.fileType -contains $modFileType) {
                        $list=$list  | where {($_.fileType -eq $modFileType)} 
                }else{

                        if  ($list.fileType -contains '2') {
                            $list=$list  | where {($_.fileType -eq '2')} 
                        }

                }


                $idList=$null
                $idList=$list.projectFileID
				Write-Host  $modName ":" $list.fileType ":" $modId ":" $tversion
                if ($idList  -eq $null) {Write-Host "File not found"}
                if($idList -ne $null){
                    foreach ($id in $idList){
            
                            $requestfile= $api+$modId+'/file/'+$id
                            $file= Invoke-WebRequest $requestfile|ConvertFrom-Json |select fileName,downloadURL
                            if($modName.Substring(0,1) -eq "["){
                                $modName="\"+$modName}
							$expresion='^'+$modName
                            $localFile =($localFiles -match  $expresion)
                            #$newFile=$file.fileName 
                            $pos=$file.downloadURL.LastIndexOf('/')+1
                            $newFile=$file.downloadURL.substring($pos,$file.downloadURL.Length-$pos)
                            if($newFile.substring($newFile.Length-4,4) -ne '.jar'){$newFile=$newFile+'.jar'}
             
                            #si solo hay un localfile -match devuelve false en vez de vacio, 
                            $empty=([string]::IsNullOrEmpty($localFile) -or (-Not $localFile ))
                            if (($localFile -ne $newFile) -or $empty ){
                                Write-Host  "--------------"  $newFile "<->" $localFile 
                                #Write-Host $file.downloadURL     
                                if ($download){                
                                    if (-not($empty)){
                                        $localFilePath=  $executionPath+"\"+$localFile 
                                        $newName="__"+$localFile     
                                        Rename-Item -Path $localFilePath -NewName $newName
                                    }
                                    $clientWeb.DownloadFile($file.downloadURL, $executionPath+"\"+"New\"+$newFile)
                                }
                            }           
                    }
                }else {
							Write-Host $modName " Not Found"
                }
    }

}
