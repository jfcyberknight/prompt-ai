#Requires -Version 5.1
# =============================================================================
# Nom    : Commit-Push.ps1
# Desc   : Effectue un git add, commit et push avec message et retour visuel.
# Date   : 2026-03-13
# =============================================================================
param(
    [Parameter(Mandatory = $false)]
    [string] $Message,
    [Parameter(Mandatory = $false)]
    [string[]] $Files
)
$ErrorActionPreference = 'Stop'
if (-not $Files) { $Files = @() }

# --- [AFFICHAGE] ---
$IsTerminal = [Environment]::UserInteractive -and $Host.UI.RawUI
function Write-Step { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [->] ' + $Msg) -ForegroundColor Cyan } else { Write-Host ('  [->] ' + $Msg) } }
function Write-Success { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [OK] ' + $Msg) -ForegroundColor Green } else { Write-Host ('  [OK] ' + $Msg) } }
function Write-Fail { param([string]$Msg) if ($IsTerminal) { Write-Host ('  [ERREUR] ' + $Msg) -ForegroundColor Red } else { Write-Host ('  [ERREUR] ' + $Msg) } }

# --- [FONCTIONS] ---
function Test-IsGitRepo {
    # Vérifie que le répertoire courant est un dépôt Git
    $gitDir = Join-Path (Get-Location) ".git"
    return (Test-Path $gitDir) -and (Test-Path (Join-Path $gitDir "HEAD"))
}

function Get-GitStatusShort {
    # Retourne la sortie de git status --short pour détecter des changements
    try {
        $status = git status --short 2>&1
        return $status
    } catch {
        return $null
    }
}

function Invoke-GitAdd {
    # Ajoute les fichiers au staging (tous ou liste fournie)
    if ($Files.Count -eq 0) {
        git add -A
    } else {
        foreach ($f in $Files) {
            if (Test-Path $f) {
                git add $f
            } else {
                Write-Fail "Fichier introuvable : $f"
                return $false
            }
        }
    }
    return $?
}

function Invoke-GitCommit {
    param([string] $CommitMessage)
    # Effectue le commit avec le message fourni
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        Write-Fail "Message de commit vide. Utilisez -Message \"Votre message\"."
        return $false
    }
    & git commit -m $CommitMessage
    return $?
}

function Invoke-GitPush {
    # Pousse la branche courante vers origin
    git push
    return $?
}

# --- [MAIN] ---
$start = Get-Date
if ($IsTerminal) { Write-Host "`n=== Commit-Push - Git commit et push ===`n" -ForegroundColor White }

try {
    # Vérification dépôt Git
    Write-Step "Vérification du dépôt Git..."
    if (-not (Test-IsGitRepo)) {
        Write-Fail "Le répertoire courant n'est pas un dépôt Git."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
        exit 1
    }
    Write-Success "Dépôt Git détecté"

    # Vérification s'il y a des changements
    $statusOutput = Get-GitStatusShort
    if ([string]::IsNullOrWhiteSpace($statusOutput)) {
        Write-Fail "Aucun changement à committer (working tree clean)."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
        exit 1
    }

    # Demande du message si non fourni
    $CommitMessage = $Message
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        $CommitMessage = Read-Host "Message de commit"
        if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            Write-Fail "Message de commit vide."
            if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
            exit 1
        }
    }

    Write-Host ""

    # Staging
    Write-Step "Ajout des fichiers (git add)..."
    if (-not (Invoke-GitAdd)) {
        Write-Fail "Échec du staging."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
        exit 1
    }
    Write-Success "Fichiers ajoutés"

    # Commit
    Write-Step "Création du commit..."
    if (-not (Invoke-GitCommit -CommitMessage $CommitMessage)) {
        Write-Fail "Échec du commit (peut-être rien à committer après add)."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
        exit 1
    }
    Write-Success "Commit créé"

    Write-Host ""

    # Push
    Write-Step "Envoi vers le remote (git push)..."
    if (-not (Invoke-GitPush)) {
        Write-Fail "Échec du push (vérifiez la branche et les droits)."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
        exit 1
    }
    Write-Success "Push terminé"

    $duration = (Get-Date) - $start
    if ($IsTerminal) { Write-Host "`n[OK] Succès (durée: $($duration.TotalSeconds.ToString('0.0'))s)`n" -ForegroundColor Green } else { Write-Host "`n[OK] Succès (durée: $($duration.TotalSeconds.ToString('0.0'))s)`n" }
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    if ($IsTerminal) { Write-Host "`n[ERREUR] Échec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec`n" }
    exit 1
}
