# Set paths
$IsoDir = "D:\temp\Xbox"
$OutputDir = "E:\Emulation\roms\xbox"
$BaseTempDir = "C:\temp\xiso_conversion"
$ExtractXiso = "C:\Tools\extract-xiso\extract-xiso.exe"

# Begin Logging
Start-Transcript -Path "C:\Tools\extract-xiso\logfile.txt" -Append


# Function to forcefully delete a folder and ensure it's gone
function Remove-Folder-Forcefully {
    param (
        [string]$FolderPath
    )
    if (Test-Path $FolderPath) {
        Write-Host "Deleting folder: $FolderPath"
        Remove-Item -Recurse -Force -LiteralPath $FolderPath -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2  # Give OS time to release file locks
        while (Test-Path $FolderPath) {
            Write-Host "Waiting for folder to be deleted..."
            Start-Sleep -Seconds 1
        }
    }
}

# Ensure necessary directories exist
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
Remove-Folder-Forcefully -FolderPath $BaseTempDir
New-Item -ItemType Directory -Path $BaseTempDir -Force | Out-Null

# Get all ISO files in the directory
$IsoFiles = Get-ChildItem -Path $IsoDir -Filter "*.iso"

if ($IsoFiles.Count -eq 0) {
    Write-Host "No ISO files found in $IsoDir. Exiting."
    exit
}

foreach ($IsoFile in $IsoFiles) {
    $OriginalIsoPath = $IsoFile.FullName
    $OriginalBaseName = $IsoFile.BaseName

    # Replace spaces with underscores in the ISO filename
    $NewBaseName = $OriginalBaseName -replace ' ', '_'
    $NewIsoName = "$NewBaseName.iso"
    $NewIsoPath = Join-Path $IsoDir $NewIsoName

    # If the new filename is different, rename the file
    if ($OriginalIsoPath -ne $NewIsoPath) {
        Write-Host "Renaming '$OriginalIsoPath' to '$NewIsoPath'"
        Rename-Item -Path $OriginalIsoPath -NewName $NewIsoName
    }

    # Update the IsoFile variable to point to the new file
    $IsoFile = Get-Item -Path $NewIsoPath

    $IsoPath = $IsoFile.FullName
    $BaseName = $IsoFile.BaseName
    $TempDir = Join-Path $BaseTempDir $BaseName
    $OutputXiso = Join-Path $OutputDir "$BaseName.xiso"

    # Ensure previous temp folder is removed completely
    Remove-Folder-Forcefully -FolderPath $TempDir
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    # Extract ISO to TempDir using the -d option
    Write-Host "Extracting: $IsoPath ..."
    & $ExtractXiso -x -d "$TempDir" "$IsoPath"

    # Wait for extraction to complete
    Start-Sleep -Seconds 2

    # Verify if extraction was successful
    if (!(Test-Path "$TempDir\default.xbe")) {
        Write-Host "Extraction failed for: $IsoPath"
        continue
    }

    # Create XISO from extracted files
    Write-Host "Creating XISO: $OutputXiso ..."
    & $ExtractXiso -c "$TempDir" "$OutputXiso"

    # Check if XISO was created successfully
    if (Test-Path $OutputXiso) {
        Write-Host "Successfully created XISO: $OutputXiso"
    } else {
        Write-Host "Failed to create XISO for: $IsoPath"
    }

    # Cleanup extracted files
    Remove-Folder-Forcefully -FolderPath $TempDir

    Write-Host "Conversion completed for: $IsoPath"
}

# Cleanup base temp directory
Remove-Folder-Forcefully -FolderPath $BaseTempDir

Write-Host "All conversions completed."

# End Logging
Stop-Transcript
