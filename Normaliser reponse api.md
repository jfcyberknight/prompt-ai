# Format normalisé des réponses API

**Objectif :** Quelle que soit la route (`/users`, `/orders`, `/health`, etc.), chaque réponse de l’API doit respecter **le même format JSON** et les **bonnes pratiques** ci-dessous. Il n’existe pas une route dédiée à la normalisation : toutes les routes renvoient déjà une réponse normalisée.

---

## Envelope commun (toutes les routes)

Chaque réponse HTTP (succès ou erreur) doit être un objet JSON avec les clés suivantes :

```json
{
  "id": "string — identifiant de la requête (corrélation, log)",
  "statut": "string — 'actif' | 'inactif' | 'erreur'",
  "donnees": "object | array | null — payload métier (spécifique à la route)",
  "message": "string — résumé court ou message d'erreur"
}
```

**Règles :**
- **id** : optionnel mais recommandé (ex. `requestId`, UUID). Utile pour le debug et la traçabilité.
- **statut** : `"actif"` = succès, `"inactif"` = ressource désactivée ou sans contenu, `"erreur"` = échec (validation, erreur métier, erreur serveur).
- **donnees** : contenu utile de la réponse. Structure **libre selon la route** (objet, tableau, ou `null` en cas d’erreur).
- **message** : toujours présent. Résumé lisible (ex. « Utilisateur créé », « Ressource introuvable »).

---

## Consignes strictes (toutes les routes)

1. **Répondre uniquement en JSON** : pas de texte avant/après, pas de markdown. `Content-Type: application/json; charset=utf-8`.
2. **Toujours les 4 clés** : `id`, `statut`, `donnees`, `message`. Valeur inconnue ou sans objet → `null` (sauf `message` qui reste une chaîne, éventuellement vide).
3. **Types stricts** : nombres en number, dates en string (idéalement ISO 8601), pas de chaîne pour un nombre.
4. **Alignement HTTP / statut** : en cas d’erreur (4xx, 5xx), mettre `"statut": "erreur"` et un `message` explicite.

---

## Best practices

### Réponse (sortie)
- **JSON valide** : pas de BOM, UTF-8, échappement correct des chaînes (`\"`, `\n`).
- **Clés présentes** : l’envelope est toujours complet ; seules les clés internes à `donnees` peuvent varier selon la route.
- **Cohérence** : mêmes conventions de nommage (camelCase ou snake_case) dans tout le projet pour `donnees`.

### Gestion des erreurs
- **Erreur fonctionnelle ou technique** : `"statut": "erreur"`, `"donnees": null` (ou objet avec détail d’erreur si utile), `"message"` lisible pour le client.
- **Pas de fuite** : pas de stack trace ni de message technique brut dans `message` en production.
- **HTTP cohérent** : 2xx → en général `"statut": "actif"` ; 4xx/5xx → `"statut": "erreur"`.

### Robustesse
- **Déterminisme** : pour une même requête valide, la structure de la réponse reste identique.
- **Pas de données sensibles** dans `message` (pas de mots de passe, tokens, etc.).
- **Message court** : une phrase ou deux ; pas de copie d’un long contenu.

### Côté consommateur (client)
- Valider les réponses avec un schéma (JSON Schema) incluant l’envelope commun.
- Toujours gérer le cas `"statut": "erreur"` (afficher ou logger `message`, ne pas supposer que `donnees` est présent).
- Vérifier le code HTTP en plus du champ `statut` pour les erreurs réseau ou serveur.

---

## Exemples par cas d’usage

### Succès — ressource unique (ex. `GET /users/123`)
```json
{
  "id": "req-a1b2c3d4",
  "statut": "actif",
  "donnees": {
    "nom": "Jean Dupont",
    "score": 85,
    "date_iso": "2026-03-13"
  },
  "message": "Utilisateur récupéré"
}
```

### Succès — liste (ex. `GET /users`)
```json
{
  "id": "req-e5f6g7h8",
  "statut": "actif",
  "donnees": [
    { "id": "USR-001", "nom": "Jean Dupont" },
    { "id": "USR-002", "nom": "Marie Martin" }
  ],
  "message": "2 utilisateur(s) trouvé(s)"
}
```

### Erreur (ex. 404 ou 500)
```json
{
  "id": "req-i9j0k1l2",
  "statut": "erreur",
  "donnees": null,
  "message": "Ressource introuvable"
}
```

### Ressource désactivée ou vide (ex. 200 mais sans contenu)
```json
{
  "id": "req-m3n4o5p6",
  "statut": "inactif",
  "donnees": null,
  "message": "Aucun résultat"
}
```
