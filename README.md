# 🚀 Prompt-AI System

> Une collection de prompts spécialisés et de protocoles pour transformer l'IA en un collaborateur technique de haute précision.

---

## 📋 Présentation

Ce dépôt centralise des instructions (prompts) structurées pour guider les interactions avec les modèles de langage (LLM) dans un contexte de développement et d'analyse technique. Chaque prompt agit comme une "personnalité" ou un "rôle" spécifique avec des règles strictes.

---

## 🧩 Structure des Prompts

| Prompt | Rôle | Description |
| :--- | :--- | :--- |
| **🔍 Analyste de Confiance** | Expert Factuel | Priorise l'exactitude, utilise la navigation web et fournit un index de certitude. |
| **🏗️ Architecte Documentation** | Release Manager | Automatise la gestion du `CHANGELOG.md` et le versionnage SemVer. |
| **🛡️ Gardien du README** | Technical Writer | Assure la synchronisation parfaite entre le code source et sa documentation. |
| **🚢 Maestro de Flotte** | Orchestrateur | Déploie et synchronise les standards sur l'ensemble de vos dépôts GitHub. |

---

## 📂 Structure du Projet

```text
prompt-ai/
├── CHANGELOG.md                         # Historique des versions et modifications
├── README.md                            # Documentation principale (ce fichier)
├── Architecte de Documentation...md      # Prompt pour la gestion des logs et versions
├── L'Analyste de Confiance.md           # Prompt pour l'analyse factuelle haute précision
├── Le Gardien du README.md              # Prompt pour la maintenance de la documentation
└── Le Maestro de Flotte GitHub.md       # Orchestrateur multi-dépôts
```

---

## 🚀 Utilisation

1. **Choisissez un rôle** selon votre besoin actuel.
2. **Copiez le contenu** du fichier `.md` correspondant dans votre interaction avec l'IA.
3. **Appliquez les règles** dictées par le prompt pour garantir la qualité des livrables.

---

---

## 🤖 Automatisation (GitHub Actions)

Vous pouvez automatiser la synchronisation de la documentation sur n'importe quel dépôt en utilisant notre **Workflow Réutilisable**.

### Configuration
1. Dans votre dépôt cible, créez un fichier `.github/workflows/docs-sync.yml`.
2. Ajoutez le contenu suivant :

```yaml
name: Sync Documentation
on:
  push:
    branches: [main]

jobs:
  call-sync:
    uses: jfcyberknight/prompt-ai/.github/workflows/reusable-documentation-sync.yml@main
    secrets:
      LLM_API_KEY: ${{ secrets.LLM_API_KEY }}
      GH_PAT: ${{ secrets.GH_PAT }}
```

### Secrets requis
- `LLM_API_KEY` : Votre clé API (OpenAI, Gemini, etc.).
- `GH_PAT` : Un *Personal Access Token* avec les droits `repo` et `workflow`.

---

## 🛠️ Maintenance & Qualité

Le projet suit les standards suivants :
- **Keep a Changelog** pour le suivi des modifications.
- **Semantic Versioning (SemVer)** pour le marquage des étapes.
- **Premium Markdown** pour une lisibilité maximale.

---

> [!NOTE]
> Ce système est conçu pour être auto-documenté. Toute modification du code source déclenche une mise à jour du `README.md` via le rôle "Gardien".
