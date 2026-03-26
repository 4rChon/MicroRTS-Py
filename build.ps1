# Build script for microrts on Windows
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\gym_microrts\microrts"

try {
    # Clean up
    if (Test-Path "build") { Remove-Item -Recurse -Force "build" }
    if (Test-Path "microrts.jar") { Remove-Item -Force "microrts.jar" }

    # Create build directory
    New-Item -ItemType Directory -Path "build" | Out-Null

    # Find all Java source files using relative paths
    $javaFiles = Get-ChildItem -Path "src" -Recurse -Filter "*.java" | ForEach-Object { 
        $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
        $relativePath -replace '\\', '/'
    }
    $javaFiles | Set-Content -Path "sources.txt" -Encoding ASCII
    
    # Get all library JARs for classpath (relative paths)
    $libs = Get-ChildItem -Path "lib" -Filter "*.jar" | ForEach-Object { "lib/$($_.Name)" }
    $classpath = $libs -join ";"

    Write-Host "Compiling Java sources..."
    $ErrorActionPreference = "Continue"
    & javac -d "build" -cp "$classpath" -sourcepath "src" "@sources.txt" 2>&1 | ForEach-Object { "$_" } | Write-Host
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed" }
    Remove-Item "sources.txt"

    # Copy library contents into build
    Write-Host "Copying dependencies..."
    Copy-Item -Path "lib\*" -Destination "build" -Recurse

    # hack to remove the weka dependency in build time
    # we don't use weka anyway yet it's a 10 MB package
    Remove-Item -Force "build\weka.jar" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "build\bots" -ErrorAction SilentlyContinue

    Write-Host "Extracting dependencies..."
    Push-Location "build"
    foreach ($lib in (Get-ChildItem -Filter "*.jar")) {
        Write-Host "  Adding $($lib.Name)..."
        & jar xf $lib.FullName 2>$null
    }
    Pop-Location

    # Create the final JAR
    Write-Host "Creating microrts.jar..."
    Push-Location "build"
    & jar cvf microrts.jar * | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "JAR creation failed" }
    Move-Item -Force "microrts.jar" "..\bin\microrts.jar"
    Copy-Item "..\bin\microrts.jar" "..\microrts.jar"
    Pop-Location

    # Clean up build directory
    Remove-Item -Recurse -Force "build"

    Write-Host "Build successful! Created microrts.jar"
}
finally {
    Pop-Location
}
