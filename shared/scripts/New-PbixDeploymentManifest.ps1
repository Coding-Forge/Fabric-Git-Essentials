[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PbipPath,

    [string]$PbixFile,

    [string]$ManifestPath,

    [string]$ArtifactName,

    [string]$GeneratedBy = 'Power BI Desktop',

    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-PbixFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [string]$ExplicitFile
    )

    if (![string]::IsNullOrWhiteSpace($ExplicitFile)) {
        $resolvedFile = (Resolve-Path -Path $ExplicitFile).Path
        if ([System.IO.Path]::GetExtension($resolvedFile) -ne '.pbix') {
            throw "Expected a .pbix file, got: $resolvedFile"
        }

        return $resolvedFile
    }

    $pbixFiles = @(Get-ChildItem -Path $RootPath -Filter '*.pbix' -File)
    if ($pbixFiles.Count -eq 0) {
        throw "No .pbix file found under $RootPath."
    }

    if ($pbixFiles.Count -gt 1) {
        $fileList = ($pbixFiles | ForEach-Object { $_.FullName }) -join ', '
        throw "Multiple .pbix files found under $RootPath. Provide -PbixFile explicitly. Matches: $fileList"
    }

    return $pbixFiles[0].FullName
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $root = (Resolve-Path -Path $RootPath).Path.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $rootUri = [System.Uri]::new($root)
    $fileUri = [System.Uri]::new((Resolve-Path -Path $FilePath).Path)
    return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString()).Replace('/', '\')
}

function Get-PbipSourceFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$ManifestFile
    )

    $manifestFullName = if (Test-Path -Path $ManifestFile) {
        (Resolve-Path -Path $ManifestFile).Path
    }
    else {
        [System.IO.Path]::GetFullPath($ManifestFile)
    }

    return Get-ChildItem -Path $RootPath -File -Recurse | Where-Object {
        $_.Extension -ne '.pbix' -and
        $_.FullName -ne $manifestFullName -and
        ($_.FullName -split '[\\/]' -notcontains '.pbi')
    } | Sort-Object FullName
}

function Get-PbipSourceHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$ManifestFile
    )

    $sourceFiles = @(Get-PbipSourceFiles -RootPath $RootPath -ManifestFile $ManifestFile)
    if ($sourceFiles.Count -eq 0) {
        throw "No PBIP source files found under $RootPath."
    }

    $entries = foreach ($file in $sourceFiles) {
        $relativePath = Get-RelativePath -RootPath $RootPath -FilePath $file.FullName
        $fileHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        "$relativePath`t$fileHash"
    }

    $payload = [System.Text.Encoding]::UTF8.GetBytes(($entries -join "`n"))
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha256.ComputeHash($payload)).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Test-Manifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$ManifestFile
    )

    if (!(Test-Path -Path $ManifestFile -PathType Leaf)) {
        throw "PBIX deployment manifest not found: $ManifestFile"
    }

    $manifest = Get-Content -Path $ManifestFile -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($manifest.pbixFile)) {
        throw "Manifest is missing required property: pbixFile"
    }

    if ([string]::IsNullOrWhiteSpace($manifest.pbixSha256)) {
        throw "Manifest is missing required property: pbixSha256"
    }

    if ([string]::IsNullOrWhiteSpace($manifest.pbipSourceSha256)) {
        throw "Manifest is missing required property: pbipSourceSha256"
    }

    if ([string]::IsNullOrWhiteSpace($manifest.generatedUtc)) {
        throw "Manifest is missing required property: generatedUtc"
    }

    [datetime]::Parse($manifest.generatedUtc).ToUniversalTime() | Out-Null

    $manifestDirectory = Split-Path -Parent (Resolve-Path -Path $ManifestFile).Path
    $manifestPbixPath = Join-Path $manifestDirectory $manifest.pbixFile
    if (!(Test-Path -Path $manifestPbixPath -PathType Leaf)) {
        throw "PBIX file named by manifest was not found: $manifestPbixPath"
    }

    $actualPbixHash = (Get-FileHash -Path $manifestPbixPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualPbixHash -ne $manifest.pbixSha256.ToUpperInvariant()) {
        throw "PBIX SHA256 mismatch. Manifest: $($manifest.pbixSha256); actual: $actualPbixHash"
    }

    $actualSourceHash = Get-PbipSourceHash -RootPath $RootPath -ManifestFile $ManifestFile
    if ($actualSourceHash -ne $manifest.pbipSourceSha256.ToUpperInvariant()) {
        throw "PBIP source SHA256 mismatch. Manifest: $($manifest.pbipSourceSha256); actual: $actualSourceHash"
    }

    Write-Host "PBIX deployment manifest is valid: $ManifestFile"
}

$resolvedPbipPath = (Resolve-Path -Path $PbipPath).Path
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $resolvedPbipPath 'deployment-manifest.json'
}

$manifestFullPath = if (Test-Path -Path $ManifestPath) {
    (Resolve-Path -Path $ManifestPath).Path
}
else {
    [System.IO.Path]::GetFullPath($ManifestPath)
}

if ($ValidateOnly) {
    Test-Manifest -RootPath $resolvedPbipPath -ManifestFile $manifestFullPath
    return
}

$resolvedPbixFile = Resolve-PbixFile -RootPath $resolvedPbipPath -ExplicitFile $PbixFile
if ([string]::IsNullOrWhiteSpace($ArtifactName)) {
    $ArtifactName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPbixFile)
}

$manifestDirectory = Split-Path -Parent $manifestFullPath
if (!(Test-Path -Path $manifestDirectory)) {
    New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
}

$manifest = [ordered]@{
    artifactName = $ArtifactName
    pbixFile = Get-RelativePath -RootPath $manifestDirectory -FilePath $resolvedPbixFile
    pbixSha256 = (Get-FileHash -Path $resolvedPbixFile -Algorithm SHA256).Hash.ToUpperInvariant()
    pbipSourceSha256 = Get-PbipSourceHash -RootPath $resolvedPbipPath -ManifestFile $manifestFullPath
    generatedUtc = [datetime]::UtcNow.ToString('o')
    generatedBy = $GeneratedBy
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFullPath -Encoding UTF8
Write-Host "Wrote PBIX deployment manifest: $manifestFullPath"
