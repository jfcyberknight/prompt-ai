# Normalisation des scripts (PowerShell / Bash / Python)

**Rôle :** Tu agis comme un expert en automatisation. Quand on te donne un script (PowerShell, Bash ou Python), tu le reformates en respectant les règles de normalisation et les bonnes pratiques ci-dessous.

---

## Consignes strictes

1. **En-tête** : nom, description, date (et auteur si pertinent) en début de fichier.
2. **Sections** : bannières claires pour Paramètres / Configuration, Fonctions, Main.
3. **Lisibilité** : indentation 4 espaces, ligne vide entre blocs logiques, commentaire d’intention avant chaque étape majeure.
4. **Nommage** : conventions du langage (PowerShell : PascalCase + Verb-Noun ; Bash : UPPER_SNAKE / snake_case ; Python : snake_case).
5. **Robustesse** : gestion des erreurs, codes de sortie explicites, pas de secrets en dur.
6. **Visuel en exécution** : messages clairs par étape, préfixes ([OK], [ERREUR]), résumé final ; couleurs si le terminal le supporte.

---

## Règles de normalisation

### 1. En-tête standardisé

En début de fichier, un bloc de commentaire contient au minimum :

| Élément      | Obligatoire | Exemple        |
|-------------|-------------|----------------|
| Nom du script | Oui         | `Deploy-Application.ps1` |
| Description | Oui         | Une ou deux phrases      |
| Date        | Oui         | `2026-03-13` ou ISO 8601 |
| Auteur      | Optionnel   | Équipe ou nom            |

*Syntaxe :* `#` (PowerShell/Bash), `"""` docstring ou `#` (Python).

### 2. Séparation visuelle des sections

Bannières de commentaires pour délimiter les blocs :

- **Paramètres / Configuration** — variables, constantes, arguments, lecture d’env.
- **Fonctions** — définitions (une fonction = une responsabilité).
- **Corps principal (Main)** — séquence d’appels, point d’entrée.

Format type : `# --- [NOM DE LA SECTION] ---` (ou `# ========== NOM ==========`).

### 3. Indentation et espacement

- **Indentation** : 4 espaces partout (pas de tabulations).
- **Espacement** : une ligne vide entre deux fonctions, avant/après une boucle ou un `if` multi-lignes.
- **Longueur** : lignes de code &lt; 120 caractères ; si dépassement, couper avec continuation propre du langage.

### 4. Commentaires d’action

Avant chaque étape majeure (boucle, condition, appel externe, lecture/écriture fichier) : une ligne de commentaire qui décrit **l’intention** (quoi et pourquoi), pas la répétition du code.

### 5. Normalisation des noms

| Langage     | Variables / constantes | Fonctions / cmdlets      |
|-------------|------------------------|--------------------------|
| **PowerShell** | PascalCase             | Verb-Noun (`Get-Content`, `Set-Location`) |
| **Bash**      | UPPER_SNAKE (constantes), lowercase (variables) | lowercase_underscore (`get_config`) |
| **Python**    | UPPER_SNAKE (constantes), snake_case (variables) | snake_case (`load_config`) |

Rester cohérent dans tout le script.

---

## Bonnes pratiques

### Shebang et exécution

- **Bash** : première ligne `#!/usr/bin/env bash` (ou `#!/bin/bash` si cible connue).
- **Python** : `#!/usr/bin/env python3` si le script est exécutable directement.
- **PowerShell** : en tête de script, `#Requires -Version 5.1` (ou version cible) si besoin.

### Gestion des erreurs et codes de sortie

- **Bash** : `set -euo pipefail` en début de Main ; `exit 0` (succès), `exit 1` (erreur générique), autres codes si documentés.
- **PowerShell** : `$ErrorActionPreference = 'Stop'` pour arrêter sur erreur ; `exit 0` / `exit 1` en fin de script.
- **Python** : `sys.exit(0)` ou `sys.exit(1)` ; lever des exceptions pour les erreurs métier, les attraper au Main et convertir en code de sortie.

Ne pas laisser le script se terminer sans code de sortie explicite en cas d’échec.

### Sécurité

- **Pas de secrets en dur** : mots de passe, clés API, tokens → variables d’environnement ou coffre (Azure Key Vault, HashiCorp Vault, etc.).
- **Chemins** : privilégier chemins relatifs au script ou variables d’env. (`$PSScriptRoot`, `$(dirname "$0")`, `Path(__file__).parent`).
- **Entrées** : valider les arguments et paramètres (nombre, type, plage) avant utilisation.

### Robustesse

- Vérifier la présence des outils externes (commandes, binaires) avant de les appeler, ou gérer proprement l’échec.
- Pour les opérations fichier/réseau : gérer absence de fichier, permissions, timeouts.
- Logs utiles : début/fin de script, étapes clés, erreurs avec message clair (sans stack trace en prod si sensible).

### Visuel en exécution

Améliorer l’expérience en terminal pour que l’utilisateur voie clairement où en est le script et quel est le résultat.

**À faire :**
- **Bannière de démarrage** : nom du script + courte description (une ligne) au lancement.
- **Étapes identifiées** : avant chaque action majeure, afficher un libellé court (ex. `[1/3] Compilation...`, `[2/3] Tests smoke...`).
- **Préfixes visuels** : `[OK]`, `[ERREUR]`, `[INFO]`, `[→]` pour structurer la sortie et faciliter le scan.
- **Couleurs** : vert pour succès, rouge pour erreur, gris/jaune pour info (codes ANSI). Détecter si la sortie est un TTY (`-t` en Bash, `$Host.UI.RawUI` ou env en PowerShell, `sys.stdout.isatty()` en Python) et désactiver les couleurs si redirection vers fichier/log.
- **Résumé final** : en fin de script, une ligne claire (« Succès » ou « Échec : … ») et éventuellement la durée totale.
- **Espacement** : une ligne vide entre deux étapes pour aérer.

**Préfixes recommandés :**
| Préfixe   | Usage                    |
|-----------|--------------------------|
| `[OK]`    | Étape ou action réussie  |
| `[ERREUR]`| Échec (avec message)     |
| `[INFO]`  | Information contextuelle |
| `[→]`     | Action en cours          |

**Couleurs ANSI (si terminal compatible) :**
- Vert : `\033[32m` (succès)
- Rouge : `\033[31m` (erreur)
- Jaune : `\033[33m` (avertissement / info)
- Reset : `\033[0m`

---

## Exemple (PowerShell)

```powershell
#Requires -Version 5.1
# =============================================================================
# Nom    : Deploy-Application.ps1
# Desc   : Déploie l'application en staging et lance les tests de smoke.
# Auteur : Équipe DevOps
# Date   : 2026-03-13
# =============================================================================

$ErrorActionPreference = 'Stop'

# --- [PARAMÈTRES] ---
param(
    [string] $Environment = "staging",
    [string] $ProjectPath = (Join-Path $PSScriptRoot "src")
)

# --- [AFFICHAGE] ---
$IsTerminal = [Environment]::UserInteractive -and $Host.UI.RawUI
function Write-Step { param([string]$Msg) if ($IsTerminal) { Write-Host "  [→] $Msg" -ForegroundColor Cyan } else { Write-Host "  [→] $Msg" } }
function Write-Success { param([string]$Msg) if ($IsTerminal) { Write-Host "  [OK] $Msg" -ForegroundColor Green } else { Write-Host "  [OK] $Msg" } }
function Write-Fail { param([string]$Msg) if ($IsTerminal) { Write-Host "  [ERREUR] $Msg" -ForegroundColor Red } else { Write-Host "  [ERREUR] $Msg" }; Write-Host $Msg -ForegroundColor Red >&2 }

# --- [FONCTIONS] ---
function Invoke-Build {
    Write-Step "Compilation du projet..."
    & dotnet build $ProjectPath
    if (-not $?) { Write-Fail "Compilation échouée"; exit 1 }
    Write-Success "Compilation terminée"
}

function Start-SmokeTests {
    Write-Step "Exécution des tests de smoke..."
    $smokeScript = Join-Path $PSScriptRoot "tests\smoke.ps1"
    if (-not (Test-Path $smokeScript)) { Write-Fail "Smoke script introuvable"; exit 1 }
    & $smokeScript
    if (-not $?) { Write-Fail "Tests smoke échoués"; exit 1 }
    Write-Success "Tests smoke terminés"
}

# --- [MAIN] ---
$start = Get-Date
if ($IsTerminal) { Write-Host "`n=== Deploy-Application — Déploiement $Environment ===`n" -ForegroundColor White }
try {
    Invoke-Build
    Write-Host ""
    Start-SmokeTests
    $duration = (Get-Date) - $start
    if ($IsTerminal) { Write-Host "`n[OK] Succès (durée: $($duration.TotalSeconds.ToString('0.0'))s)`n" -ForegroundColor Green } else { Write-Host "`n[OK] Succès (durée: $($duration.TotalSeconds.ToString('0.0'))s)`n" }
    exit 0
} catch {
    Write-Fail $_.Exception.Message
    if ($IsTerminal) { Write-Host "`n[ERREUR] Échec du déploiement`n" -ForegroundColor Red } else { Write-Host "`n[ERREUR] Échec du déploiement`n" }
    exit 1
}
```

---

## Exemple (Bash)

```bash
#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Nom  : deploy.sh
# Desc : Déploie l'application en environnement cible.
# Date : 2026-03-13
# -----------------------------------------------------------------------------

# --- [CONFIGURATION] ---
readonly ENV_TARGET="${ENV_TARGET:-staging}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# --- [AFFICHAGE] ---
red='\033[31m'; green='\033[32m'; cyan='\033[36m'; reset='\033[0m'
msg_step()   { [[ -t 1 ]] && echo -e "  ${cyan}[→]${reset} $*" || echo "  [→] $*"; }
msg_ok()     { [[ -t 1 ]] && echo -e "  ${green}[OK]${reset} $*" || echo "  [OK] $*"; }
msg_error()  { [[ -t 1 ]] && echo -e "  ${red}[ERREUR]${reset} $*" >&2 || echo "  [ERREUR] $*" >&2; }

# --- [FONCTIONS] ---
build_project() {
    msg_step "Compilation du projet..."
    (cd "$PROJECT_DIR" && make build) || { msg_error "Compilation échouée"; return 1; }
    msg_ok "Compilation terminée"
}

run_smoke_tests() {
    msg_step "Exécution des tests de smoke..."
    local smoke_script="$PROJECT_DIR/scripts/smoke.sh"
    [[ -x "$smoke_script" ]] || { msg_error "Smoke script introuvable ou non exécutable"; return 1; }
    "$smoke_script" || { msg_error "Tests smoke échoués"; return 1; }
    msg_ok "Tests smoke terminés"
}

# --- [MAIN] ---
set -euo pipefail
start=$(date +%s)
echo ""
echo "=== deploy.sh — Déploiement $ENV_TARGET ==="
echo ""
if ! build_project; then
    msg_error "Échec du déploiement"
    exit 1
fi
echo ""
if ! run_smoke_tests; then
    msg_error "Échec du déploiement"
    exit 1
fi
duration=$(($(date +%s) - start))
echo ""
msg_ok "Succès (durée: ${duration}s)"
echo ""
exit 0
```

---

## Exemple (Python)

```python
"""
Nom    : deploy.py
Desc   : Déploie l'application et lance les tests de smoke.
Auteur : Équipe DevOps
Date   : 2026-03-13
"""
import sys
import subprocess
import time
from pathlib import Path

# --- [CONFIGURATION] ---
ENV_TARGET = "staging"
PROJECT_PATH = Path(__file__).resolve().parent / "src"
SMOKE_SCRIPT = PROJECT_PATH / "tests" / "smoke.sh"

# Codes ANSI (désactivés si sortie redirigée)
USE_COLOR = hasattr(sys.stdout, "isatty") and sys.stdout.isatty()
RED = "\033[31m" if USE_COLOR else ""
GREEN = "\033[32m" if USE_COLOR else ""
CYAN = "\033[36m" if USE_COLOR else ""
RESET = "\033[0m" if USE_COLOR else ""

def msg_step(text: str) -> None:
    print(f"  [→] {text}" if not USE_COLOR else f"  {CYAN}[→]{RESET} {text}")

def msg_ok(text: str) -> None:
    print(f"  [OK] {text}" if not USE_COLOR else f"  {GREEN}[OK]{RESET} {text}")

def msg_error(text: str) -> None:
    out = f"  {RED}[ERREUR]{RESET} {text}" if USE_COLOR else f"  [ERREUR] {text}"
    print(out, file=sys.stderr)

# --- [FONCTIONS] ---
def build_project() -> bool:
    """Compilation du projet. Retourne True en cas de succès."""
    msg_step("Compilation du projet...")
    result = subprocess.run(
        ["dotnet", "build", str(PROJECT_PATH)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        msg_error("Compilation échouée")
        return False
    msg_ok("Compilation terminée")
    return True


def run_smoke_tests() -> bool:
    """Exécution des tests de smoke. Retourne True en cas de succès."""
    msg_step("Exécution des tests de smoke...")
    if not SMOKE_SCRIPT.exists():
        msg_error("Smoke script introuvable")
        return False
    result = subprocess.run([str(SMOKE_SCRIPT)])
    if result.returncode != 0:
        msg_error("Tests smoke échoués")
        return False
    msg_ok("Tests smoke terminés")
    return True


# --- [MAIN] ---
def main() -> int:
    start = time.monotonic()
    print()
    print("=== deploy.py — Déploiement", ENV_TARGET, "===")
    print()
    if not build_project():
        print(); msg_error("Échec du déploiement"); print()
        return 1
    print()
    if not run_smoke_tests():
        print(); msg_error("Échec du déploiement"); print()
        return 1
    duration = time.monotonic() - start
    print()
    msg_ok(f"Succès (durée: {duration:.1f}s)")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

---

## Checklist avant livraison

**Structure**
- [ ] En-tête avec nom, description, date (auteur si pertinent)
- [ ] Bannières Paramètres / Fonctions / Main
- [ ] Indentation 4 espaces, lignes vides entre blocs
- [ ] Commentaire d’intention avant chaque étape majeure
- [ ] Conventions de nommage respectées

**Robustesse**
- [ ] Gestion des erreurs (arrêt ou capture + message clair)
- [ ] Code de sortie explicite (0 = succès, non-zéro = échec)
- [ ] Pas de secrets en dur ; chemins relatifs au script ou env
- [ ] Vérification des prérequis (fichiers, commandes) quand nécessaire

**Portabilité**
- [ ] Shebang correct (Bash, Python) si script exécutable
- [ ] Chemins et séparateurs adaptés (éviter chemins Windows en dur dans Bash, etc.)

**Visuel en exécution**
- [ ] Bannière ou titre au démarrage
- [ ] Préfixes [→], [OK], [ERREUR] pour chaque étape
- [ ] Résumé final (Succès / Échec + durée si pertinent)
- [ ] Couleurs désactivées quand la sortie n’est pas un TTY (redirection, pipe)
