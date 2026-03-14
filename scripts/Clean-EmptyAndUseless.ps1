#Requires -Version 5.1
# =============================================================================
# Nom    : Clean-EmptyAndUseless.ps1
# Desc   : Detecte et supprime dossiers vides, fichiers vides et inutiles.
# Date   : 2026-03-13
# =============================================================================
param(
    [Parameter(Mandatory = $false)]
    [string] $TargetPath,
    [Parameter(Mandatory = $false)]
    [switch] $Remove,
    [Parameter(Mandatory = $false)]
    [switch] $IncludeUseless
)
$ErrorActionPreference = 'Stop'
if (-not $TargetPath) { $TargetPath = (Get-Location).Path }

# Dossiers à ne jamais supprimer (ex. .git, node_modules si souhaité)
$ExcludeDirs = @(".git", ".vs", ".idea", "node_modules")

# Patterns de fichiers considérés inutiles (avec -IncludeUseless)
$UselessPatterns = @("*.tmp", "*.temp", "*.bak", "*~", ".DS_Store", "Thumbs.db", "desktop.ini")

# --- [AFFICHAGE] ---
$IsTerminal = [Environment]::UserInteractive -and $Host.UI.RawUI
function Write-Step { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [->] ' + $Msg) -ForegroundColor Cyan } else { Write-Host ('  [->] ' + $Msg) } }
function Write-Success { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [OK] ' + $Msg) -ForegroundColor Green } else { Write-Host ('  [OK] ' + $Msg) } }
function Write-Fail { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [ERREUR] ' + $Msg) -ForegroundColor Red } else { Write-Host ('  [ERREUR] ' + $Msg) } }
function Write-Info { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [INFO] ' + $Msg) -ForegroundColor Yellow } else { Write-Host ('  [INFO] ' + $Msg) } }

# --- [FONCTIONS] ---
function Get-ResolvedPath {
    # Retourne le chemin absolu resolu
    $p = $TargetPath
    if (-not [System.IO.Path]::IsPathRooted($p)) {
        $p = Join-Path (Get-Location) $p
    }
    $resolved = [System.IO.Path]::GetFullPath($p)
    if (-not (Test-Path $resolved)) {
        return $null
    }
    return $resolved
}

function Get-EmptyDirectories {
    param([string] $RootPath)
    # Liste les dossiers vides récursivement (enfants d'abord pour suppression propre)
    $empty = [System.Collections.ArrayList]::new()
    $dirs = Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $name = $dir.Name
        if ($ExcludeDirs -contains $name) { continue }
        $dirPath = $dir.FullName
        $content = Get-ChildItem -Path $dirPath -Force -ErrorAction SilentlyContinue
        if (-not $content -or $content.Count -eq 0) {
            [void] $empty.Add($dirPath)
        }
    }
    # Trier par longueur de chemin décroissante (plus profonds en premier)
    return ($empty | Sort-Object { $_.Length } -Descending)
}

function Get-EmptyFiles {
    param([string] $RootPath)
    # Liste les fichiers de taille 0
    $files = Get-ChildItem -Path $RootPath -File -Recurse -ErrorAction SilentlyContinue
    $empty = @($files | Where-Object { $_.Length -eq 0 })
    if ($empty.Count -eq 0) { return @() }
    return @($empty | ForEach-Object { $_.FullName })
}

function Get-UselessFiles {
    param([string] $RootPath)
    # Liste les fichiers correspondant aux patterns inutiles
    $found = [System.Collections.ArrayList]::new()
    foreach ($pat in $UselessPatterns) {
        $items = Get-ChildItem -Path $RootPath -Filter $pat -File -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $parentName = (Split-Path $item.DirectoryName -Leaf)
            if ($ExcludeDirs -contains $parentName) { continue }
            [void] $found.Add($item.FullName)
        }
    }
    return $found
}

# --- [MAIN] ---
$start = Get-Date
$root = Get-ResolvedPath
if (-not $root) {
    if ($IsTerminal) { Write-Host "`n[ERREUR] Chemin invalide : $TargetPath`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Chemin invalide : $TargetPath`n" }
    exit 1
}

if ($IsTerminal) { Write-Host "`n=== Clean-EmptyAndUseless - Menage dossiers/fichiers vides et inutiles ===`n" -ForegroundColor White }
if (-not $Remove) { Write-Info 'Mode liste uniquement (aucune suppression). Utilisez -Remove pour supprimer.' }
Write-Host ""

# Dossiers vides
Write-Step 'Recherche des dossiers vides...'
$emptyDirs = @(Get-EmptyDirectories -RootPath $root)
if ($emptyDirs.Count -eq 0) {
    Write-Success 'Aucun dossier vide trouve'
} else {
    Write-Info ($emptyDirs.Count.ToString() + ' dossier(s) vide(s) trouve(s)')
    foreach ($d in $emptyDirs) {
        $rel = $d.Replace($root, "").TrimStart("\", "/")
        if ($Remove) {
            Remove-Item -Path $d -Force -Recurse -ErrorAction SilentlyContinue
            if ($IsTerminal) { Write-Host ('    Supprime : ' + $rel) -ForegroundColor Gray } else { Write-Host ('    Supprime : ' + $rel) }
        } else {
            if ($IsTerminal) { Write-Host ('    ' + $rel) -ForegroundColor Gray } else { Write-Host ('    ' + $rel) }
        }
    }
    if ($Remove) { Write-Success 'Dossiers vides supprimes' }
}

Write-Host ""

# Fichiers vides
Write-Step 'Recherche des fichiers vides (0 octet)...'
$emptyFiles = @(Get-EmptyFiles -RootPath $root)
if ($emptyFiles.Count -eq 0) {
    Write-Success 'Aucun fichier vide trouve'
} else {
    Write-Info ($emptyFiles.Count.ToString() + ' fichier(s) vide(s) trouve(s)')
    foreach ($f in $emptyFiles) {
        $rel = $f.Replace($root, "").TrimStart("\", "/")
        if ($Remove) {
            Remove-Item -Path $f -Force -ErrorAction SilentlyContinue
            if ($IsTerminal) { Write-Host ('    Supprime : ' + $rel) -ForegroundColor Gray } else { Write-Host ('    Supprime : ' + $rel) }
        } else {
            if ($IsTerminal) { Write-Host ('    ' + $rel) -ForegroundColor Gray } else { Write-Host ('    ' + $rel) }
        }
    }
    if ($Remove) { Write-Success 'Fichiers vides supprimes' }
}

# Fichiers inutiles (optionnel)
if ($IncludeUseless) {
    Write-Host ""
    Write-Step 'Recherche des fichiers inutiles (.tmp, .bak, .DS_Store, etc.)...'
    $uselessFiles = @(Get-UselessFiles -RootPath $root)
    if ($uselessFiles.Count -eq 0) {
        Write-Success 'Aucun fichier inutile trouve'
    } else {
        Write-Info ($uselessFiles.Count.ToString() + ' fichier(s) inutile(s) trouve(s)')
        foreach ($f in $uselessFiles) {
            $rel = $f.Replace($root, "").TrimStart("\", "/")
            if ($Remove) {
                Remove-Item -Path $f -Force -ErrorAction SilentlyContinue
                if ($IsTerminal) { Write-Host ('    Supprime : ' + $rel) -ForegroundColor Gray } else { Write-Host ('    Supprime : ' + $rel) }
            } else {
                if ($IsTerminal) { Write-Host ('    ' + $rel) -ForegroundColor Gray } else { Write-Host ('    ' + $rel) }
            }
        }
        if ($Remove) { Write-Success 'Fichiers inutiles supprimes' }
    }
}

$duration = (Get-Date) - $start
Write-Host ""
$durStr = $duration.TotalSeconds.ToString('0.0')
if ($IsTerminal) { Write-Host ('[OK] Termine (duree: ' + $durStr + 's)' + "`n") -ForegroundColor Green } else { Write-Host ('[OK] Termine (duree: ' + $durStr + 's)' + "`n") }
exit 0
