#Requires -Version 5.1
# =============================================================================
# Nom    : Commit-Push.ps1
# Desc   : Effectue un git add, commit et push avec message et retour visuel.
# Date   : 2026-03-13
# =============================================================================

# --- [PARAMETRES] ---
param(
    [Parameter(Mandatory = $false)]
    [string] $Message,
    [Parameter(Mandatory = $false)]
    [string[]] $Files
)

# --- [CONFIGURATION] ---
$ErrorActionPreference = 'Stop'
if (-not $Files) { $Files = @() }
$DefaultCommitMessage = 'chore: update'

# --- [AFFICHAGE] ---
$IsTerminal = [Environment]::UserInteractive -and $Host.UI.RawUI
function Write-Step {
    param([string] $Msg)
    if ($IsTerminal) { Write-Host ('  [->] ' + $Msg) -ForegroundColor Cyan } else { Write-Host ('  [->] ' + $Msg) }
}
function Write-Success {
    param([string] $Msg)
    if ($IsTerminal) { Write-Host ('  [OK] ' + $Msg) -ForegroundColor Green } else { Write-Host ('  [OK] ' + $Msg) }
}
function Write-Fail {
    param([string] $Msg)
    if ($IsTerminal) { Write-Host ('  [ERREUR] ' + $Msg) -ForegroundColor Red } else { Write-Host ('  [ERREUR] ' + $Msg) }
}
function Write-Info {
    param([string] $Msg)
    if ($IsTerminal) { Write-Host ('  [INFO] ' + $Msg) -ForegroundColor Yellow } else { Write-Host ('  [INFO] ' + $Msg) }
}

# --- [FONCTIONS] ---
function Test-IsGitRepo {
    # Verifie que le repertoire courant est un depot Git
    $gitDir = Join-Path (Get-Location) ".git"
    return (Test-Path $gitDir) -and (Test-Path (Join-Path $gitDir "HEAD"))
}

function Get-GitStatusShort {
    # Retourne la sortie de git status --short pour detecter des changements
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
                Write-Fail ('Fichier introuvable : ' + $f)
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
        Write-Fail 'Message de commit vide. Utilisez -Message "Votre message".'
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
    # Verification que le repertoire est un depot Git
    Write-Step 'Verification du depot Git...'
    if (-not (Test-IsGitRepo)) {
        Write-Fail "Le repertoire courant n'est pas un depot Git."
        if ($IsTerminal) { Write-Host "`n[ERREUR] Echec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Echec`n" }
        exit 1
    }
    Write-Success 'Depot Git detecte'

    # Verification s'il y a des changements
    $statusOutput = Get-GitStatusShort
    if ([string]::IsNullOrWhiteSpace($statusOutput)) {
        Write-Info 'Aucun changement a committer (working tree clean).'
        if ($IsTerminal) { Write-Host "`n[INFO] Rien a faire.`n" -ForegroundColor Yellow } else { Write-Host "`n[INFO] Rien a faire.`n" }
        exit 0
    }

    # Message : parametre, sinon defaut
    $CommitMessage = $Message
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        $CommitMessage = $DefaultCommitMessage
        Write-Info ('Message de commit : ' + $CommitMessage)
    }

    Write-Host ""

    # Staging
    Write-Step 'Ajout des fichiers (git add)...'
    if (-not (Invoke-GitAdd)) {
        Write-Fail 'Echec du staging.'
        if ($IsTerminal) { Write-Host "`n[ERREUR] Echec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Echec`n" }
        exit 1
    }
    Write-Success 'Fichiers ajoutes'

    # Commit
    Write-Step 'Creation du commit...'
    if (-not (Invoke-GitCommit -CommitMessage $CommitMessage)) {
        Write-Fail 'Echec du commit (peut-etre rien a committer apres add).'
        if ($IsTerminal) { Write-Host "`n[ERREUR] Echec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Echec`n" }
        exit 1
    }
    Write-Success 'Commit cree'

    Write-Host ""

    # Push
    Write-Step 'Envoi vers le remote (git push)...'
    if (-not (Invoke-GitPush)) {
        Write-Fail 'Echec du push (verifiez la branche et les droits).'
        if ($IsTerminal) { Write-Host "`n[ERREUR] Echec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Echec`n" }
        exit 1
    }
    Write-Success 'Push termine'

    $duration = (Get-Date) - $start
    $durStr = $duration.TotalSeconds.ToString('0.0')
    if ($IsTerminal) { Write-Host ("`n[OK] Succes (duree: " + $durStr + "s)`n") -ForegroundColor Green } else { Write-Host ("`n[OK] Succes (duree: " + $durStr + "s)`n") }
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    if ($IsTerminal) { Write-Host "`n[ERREUR] Echec`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Echec`n" }
    exit 1
}
