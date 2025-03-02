$folderPath = "D:\temp\ps2"  # Change this to your actual folder path

# Get all .chd files in the folder
Get-ChildItem -Path $folderPath -Filter "*.chd" | ForEach-Object {
    # Extract the game name by removing everything before the first dot
    $newName = $_.Name -replace "^[^.]+\.\d+\.", ""
    
    # Rename the file
    Rename-Item -Path $_.FullName -NewName $newName -Force
    Write-Output "Renamed: $($_.Name) -> $newName"
}