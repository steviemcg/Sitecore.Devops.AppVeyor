$ZipCommand = Join-Path -Path (Split-Path -parent $MyInvocation.MyCommand.Definition) -ChildPath "7z.exe"
if (!(Test-Path $ZipCommand)) {
        throw "7z.exe was not found at $ZipCommand."
}
set-alias zip $ZipCommand
 
function Unzip-File {
        param (
                [string] $ZipFile = $(throw "ZipFile must be specified."),
                [string] $OutputDir = $(throw "OutputDir must be specified.")
        )
         
        if (!(Test-Path($ZipFile))) {
                throw "Zip filename does not exist: $ZipFile"
                return
        }
         
        zip x -y "-o$OutputDir" $ZipFile
         
        if (!$?) {
                throw "7-zip returned an error unzipping the file."
        }
}

function ZipFile($source, $dest, $excludeFolders, $excludeFiles) {
	Write-Host "Zipping Folder:$source to $dest"	
    [Array]$arguments =  @()
    $arguments += "a", "-tzip"
    foreach($folderToExclude in @($excludeFolders)){  
    	$arguments += "-xr!$folderToExclude"
    }
    foreach($fileToExclude in @($excludeFiles)){  
    	$arguments += "-x!$fileToExclude"
    }
    $arguments += "$dest", "$source", "-r", "-y", "-mx3"
    & zip $arguments
	Write-Host "Finished Zipping"
}