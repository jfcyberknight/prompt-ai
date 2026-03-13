# Changelog
Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [Unreleased]
### Added
- Ajout du prompt `Architecte de Documentation & Changelog.md` pour automatiser la gestion du journal des modifications.
- Ajout du prompt `Le Gardien du README.md` pour assurer la cohérence entre le code et la documentation.
- Création du `README.md` initial structurant la présentation du projet.
- Ajout du prompt `Le Maestro de Flotte GitHub.md` pour l'orchestration multi-dépôts.
- Mise en place du workflow GitHub réutilisable `.github/workflows/reusable-documentation-sync.yml` et du script `sync_engine.py` pour l'automatisation globale.

### Changed
- Refonte visuelle de `L'Analyste de Confiance.md` (Premium Markdown).
- Refonte visuelle de `Architecte de Documentation & Changelog.md`.
- Ajout de la **Règle n°5 : Synchronisation de Version (SemVer)** dans le prompt Architecte de Documentation.
- Migration du moteur de synchronisation (`sync_engine.py`) vers le nouveau **SDK Google GenAI (`google-genai`)**.
- Passage au modèle **Gemini 2.0 Flash** (le plus récent) et gestion améliorée des erreurs de quota.
- Ajout d'un mécanisme d'auto-retry (65s) pour gérer les limites de la version gratuite.

### Fixed
- Initialisation propre du dépôt Git et premier push vers GitHub.
