$legibleModFileNames=$false
#if true the regular expression of the mod file names is more simple but sometimes needs manual fine tuning.



#from
#https://github.com/jitbit/MurmurHash.net/blob/master/MurmurHash.cs
$Source = @” 
using System;
namespace murmur
{ 					
public class murmurhash
{
	public static uint Hash(string data)
	{
        byte[] dataByte=System.Text.Encoding.UTF8.GetBytes(data);
		return Hash(dataByte);
	}

	public static uint Hash(byte[] data)
	{
		//return Hash(data, 0xc58f1a7a);
        int length = data.Length;
		return Hash(Normalize(data), 1, length);
	}

	const uint m = 0x5bd1e995;
	const int r = 24;
	public static uint Hash(byte[] data, uint seed, int length)
	{
		
		if (length == 0)
			return 0;
		uint h = seed ^ (uint)length;
		int currentIndex = 0;
		while (length >= 4)
		{
			uint k = (uint)(data[currentIndex++] | data[currentIndex++] << 8 | data[currentIndex++] << 16 | data[currentIndex++] << 24);
			k *= m;
			k ^= k >> r;
			k *= m;

			h *= m;
			h ^= k;
			length -= 4;
		}
		switch (length)
		{
			case 3:
				h ^= (UInt16)(data[currentIndex++] | data[currentIndex++] << 8);
				h ^= (uint)(data[currentIndex] << 16);
				h *= m;
				break;
			case 2:
				h ^= (UInt16)(data[currentIndex++] | data[currentIndex] << 8);
				h *= m;
				break;
			case 1:
				h ^= data[currentIndex];
				h *= m;
				break;
			default:
				break;
		}

		h ^= h >> 13;
		h *= m;
		h ^= h >> 15;

		return h;	
    }

	public static byte[]  SubArray (byte[]  data, int index, int length)
    {
        byte[] result = new byte[length];
        Array.Copy(data, index, result, 0, length);
        return result;
    }

    public static byte[] Normalize(byte[] array){

        int bufferSize = array.Length;

        int contador=0;
		byte c;
		
       for (int a = 0; a < bufferSize; a++){
			
            c=array[a];        
				
            if (!(c==9||c==10||c==13||c==32)) //No es espacio
            {         
                array[contador]=array[a];
				contador++;
            }
         }
				
        return SubArray (array,0,contador);

    }


    public static uint HashNormalize(byte[] array){

        int bufferSize = array.Length;

        int contador=0;
		byte c;
		
       for (int a = 0; a < bufferSize; a++){
			
            c=array[a];        
				
            if (!(c==9||c==10||c==13||c==32)) //No es espacio
            {         
                array[contador]=array[a];
				contador++;
            }
         }
				
        return Hash (array,1,contador);

    }

}
}
“@

#Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
Add-Type  -TypeDefinition $Source -Language CSharp 



$Destination=[string](Get-Location)
$idFile=$Destination+"\ids.txt"
$modsFolder=$Destination+"\.."




$modfingerprints=@{}
$mods=Get-ChildItem $modsFolder -Filter *.jar  
$modsPost="["
Foreach ($f in $mods){

    [byte[]]$fileBytes = [io.File]::ReadAllBytes($f.FullName)
    $fingerprint=[murmur.murmurhash]::HashNormalize($fileBytes)
    $modfingerprints.add($fingerprint.ToString(),$f.Name.ToString())
    $modsPost=$modsPost+$fingerprint+","
}
$modsPost=$modsPost.Substring(0,$modsPost.Length-1)+"]"



#para obtener el mod 
#post a https://addons-ecs.forgesvc.net/api/v2/fingerprint y los hash asi [n1 , n2, n3]
$response=Invoke-WebRequest -UseBasicParsing https://addons-ecs.forgesvc.net/api/v2/fingerprint -ContentType "application/json" -Method POST -Body ($modsPost)|ConvertFrom-Json
$matches=$response|select -expand  exactMatches| Select-Object -Property id,file


#$Pedidos =$respuesta|select -ExpandProperty installedFingerprints
$unmatches =$response|select -ExpandProperty unmatchedFingerprints 


$versions=@{}
foreach ($row in $matches){
    $version= $row.file.gameVersion.Get(0)
    $valor=$versions[$version]
    if ($valor -gt 0){
        $versions.Remove($version)
        $valor++
        $versions.add($version,$valor)
    }else{
        $versions.Add($version,1)
    }          
}
$firstVersion=$versions.GetEnumerator() |Sort-Object { $_.Value } -Descending | Select-Object -first 1 name





"#version;"+$firstVersion.Name | Out-File $idFile 
"#Format Id;FileNameRegularexpression;Type;Version" | Out-File $idFile  -Append
"#Example Beta Type and 1.12 version"| Out-File $idFile -Append
"#228702;ProjectRed-(.*)-base;2;1.12"| Out-File $idFile -Append
"#"| Out-File $idFile -Append

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

$matches=$matches.GetEnumerator() |Sort-Object { $_.file.fileName } 

foreach ($row in $matches){

    $fileName=$row.file.fileName
    if ($fileName.Length -gt 4 -and $fileName.substring($fileName.Length-4, 4) -eq ".jar"){

        $fileNamereg=filenameWithoutNumbers($fileName.substring(0,$fileName.Length-4))
        #Write-Host("id:"+$row.id ,"displayName:"+ $row.file.displayName,  "fileName:"+ $row.file.fileName, "releaseType:"+   $row.file.releaseType,  "fileStatus:"+  $row.file.fileStatus, "gameVersion:"+   $row.file.gameVersion)
        $string=$row.id.ToString()+";" 
        $string=$string+$fileNamereg +";"

        $releaseType=$row.file.releaseType
        if( $releaseType -ne  1)  {$string= $string + $releaseType } 
        $gameVersion=$row.file.gameVersion.GetEnumerator() |Sort-Object { $_.Value } -Descending 
        if( $row.file.gameVersion -notcontains  $firstVersion.Name)  {
            $string= $string+";"+($gameVersion| Select-Object -first 1)
        }

        $string | Out-File $idFile -Append
    }
}

foreach ($fingeprint in $unmatches){
    
    "#"+$modfingerprints[$fingeprint.ToString()]+" not found" | Out-File $idFile -Append
    Write-Host  $modfingerprints[$fingeprint.ToString()] " not found"
}

                                     
class Config {
    [string]$author
    [string]$modLoader
    [string]$version
    [string]$name
    [string[]]$foldersOverrides
    [string[]]$filesOverrides
}

class File {
    [int]$fileID
    [int]$projectID
    [bool]$required
}

class ModLoader {
    [string]$id
    [bool]$primary
}

class Minecraft {
    [ModLoader[]]$modLoaders
    [string]$version
}


class Manifest {
    [string]$author
    [File[]]$files
    [string]$manifestType
    [int]$manifestVersion
    [Minecraft]$minecraft
    [string]$name
    [string]$overrides
    [string]$version
}


$configFile=$Destination+"\Config.json"
[Config]$config=Get-Content $configFile | Out-String | ConvertFrom-Json

if ($config.name -gt ""){


    $files = @()
    $modLoaders = @()


    foreach ($row in $matches){

        $file = [File]::new()
        $file.fileID=$row.file.id
        $file.projectID=$row.id
        $file.required=$true

        $files+=$file
    }


    $manifest = [Manifest]::new()

    $manifest.author=$config.author 
    $manifest.files=$files
    $manifest.manifestType="minecraftModpack"
    $manifest.manifestVersion=1

    $modLoader = [ModLoader]::new()
    $modLoader.id = $config.modLoader 
    $modLoader.primary=$true
    $modLoaders+=$modLoader

    $minecraft= [Minecraft]::new()
    $minecraft.modLoaders=$modLoaders
    $minecraft.version=$config.version  

    $manifest.minecraft=$minecraft
    $manifest.name=$config.name 
    $manifest.overrides="overrides"
    $manifest.version="1.0.0"

    $manifestFile=$Destination+"\manifest.json"
    
    $manifest|ConvertTo-Json -Depth 20 | Out-File  -Encoding ASCII $manifestFile


}else{
        Write-Host "No Config.json file or bad format."
}
