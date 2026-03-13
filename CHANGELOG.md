# Changelog
Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [1.0.0] - 13 mars 2026

### Added
- Création du système **Prompt-AI** avec 4 rôles experts (`Analyste`, `Architecte`, `Gardien`, `Maestro`).
- Prompt `Architecte de Documentation & Changelog.md` pour le suivi SemVer.
- Prompt `Le Gardien du README.md` pour la cohérence doc/code.
- Prompt `Le Maestro de Flotte GitHub.md` pour l'orchestration multi-dépôts.
- Infrastructure d'automatisation GitHub Actions avec workflow réutilisable.
- Moteur de synchronisation `sync_engine.py` compatible **Gemini 2.0 Flash**.
- Création du `README.md` structuré et de `version.json`.

### Changed
- Refonte visuelle de tous les prompts vers un style Markdown Premium.
- Migration du moteur de synchronisation vers le SDK **google-genai**.
- Implémentation d'un mécanisme d'auto-retry pour gérer les quotas de l'API gratuite.

### Fixed
- Initialisation et configuration complète du dépôt Git/GitHub.
- Correction des erreurs de routage API (404) et d'authentification (401).
