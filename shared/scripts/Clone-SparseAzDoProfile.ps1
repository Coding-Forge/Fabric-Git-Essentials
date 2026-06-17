param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,

    [string]$Destination,

    [string]$Branch = 'main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or not available on PATH.'
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $repoName = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl.TrimEnd('/'))
    if ([string]::IsNullOrWhiteSpace($repoName)) {
        throw 'Could not infer destination folder name from RepoUrl. Pass -Destination explicitly.'
    }

    $Destination = $repoName
}

if (Test-Path -LiteralPath $Destination) {
    throw "Destination path already exists: $Destination"
}

Write-Host "Cloning $RepoUrl into $Destination (branch: $Branch)..."
git clone --filter=blob:none --no-checkout --branch $Branch $RepoUrl $Destination

Push-Location $Destination
try {
    # Azure DevOps profile: azdo pipeline definitions + shared assets + docs.
    git sparse-checkout init --cone
    git sparse-checkout set azdo shared docs
    git checkout $Branch

    Write-Host ''
    Write-Host 'Sparse checkout configured for Azure DevOps profile.'
    Write-Host 'Included folders: azdo, shared, docs'
    Write-Host "Working directory: $(Get-Location)"
}
finally {
    Pop-Location
}
