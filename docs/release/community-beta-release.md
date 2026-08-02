# Release beta FlowCast Community — runbook opérateur

Durée opérateur cible : **10 à 15 minutes**, hors compilation et téléchargement. Exécuter les étapes dans l'ordre et consigner les résultats dans le [rapport de release](templates/community-release-report.md).

Définir une seule fois la version (exemple ci-dessous ; remplacer la valeur pour chaque nouvelle RC) :

```bash
export FLOWCAST_RELEASE=0.1.0-rc.3
[[ "$FLOWCAST_RELEASE" =~ ^0\.1\.0-rc\.[0-9]+$ ]] \
  && echo "Version valide: $FLOWCAST_RELEASE" \
  || echo "Version RC invalide"
```

Une validation invalide est un **NO-GO** : corriger la variable avant toute action.

## 1. Préparer la version

### Étape 1 — Valider le dépôt privé `FlowCast`

- **Action / dépôt :** dans `FlowCast`, vérifier qu'il n'existe aucune PR critique ouverte, puis exécuter :

  ```bash
  git switch main
  git pull --ff-only
  git status --short
  git rev-parse HEAD
  ```

- **Workflow :** `Beta CI summary` (CI Beta), sur le dernier commit de `main` ; aucun paramètre.
- **Résultat attendu :** arbre propre, SHA consigné, CI verte et version absente des tags/Releases.
- [ ] Le commit à publier est sur main
- [ ] FlowCast CI / Beta CI summary est vert
- [ ] La version n'existe pas encore dans les Releases ou les tags
- **Gate :** **GO** si les quatre contrôles sont satisfaits ; **NO-GO** en cas de changement local, PR critique, CI rouge ou version existante.

### Étape 2 — Valider le dépôt public `FlowCast-Community`

- **Action / dépôt :** dans `FlowCast-Community`, mettre `main` à jour avec les mêmes commandes Git, noter `git rev-parse HEAD`, puis contrôler `VERSION`, la documentation et l'absence de modification non fusionnée nécessaire.
- **Workflow :** `Validate`, sur le dernier commit de `main` ; aucun paramètre.
- **Résultat attendu :** workflow vert et contenu public cohérent avec le runtime choisi.
- [ ] Le Compose public correspond au runtime FlowCast courant
- [ ] Le oneliner documenté utilise la version à publier
- [ ] L’archive n’est pas encore publiée
- **Gate :** **GO** si `main`, `Validate`, `VERSION` et les trois cases sont cohérents ; sinon **NO-GO**.

## 2. Publier les images FlowCast

### Étape 3 — Lancer la publication privée

- **Action / dépôt :** dans `FlowCast`, lancer manuellement **FlowCast release candidate** (`.github/workflows/release-containers.yml`) depuis le commit validé.
- **Paramètres :** `version: $FLOWCAST_RELEASE`, `publish: true`, `publish_arm64: false`.
- **Résultat attendu :** le workflow publie, pour **linux/amd64** (première ligne de support), les cinq références :

  ```text
  ghcr.io/chourmovs/flowcast-control:$FLOWCAST_RELEASE
  ghcr.io/chourmovs/flowcast-engine:$FLOWCAST_RELEASE
  ghcr.io/chourmovs/flowcast-analyzer:$FLOWCAST_RELEASE
  ghcr.io/chourmovs/flowcast-bliss:$FLOWCAST_RELEASE
  ghcr.io/chourmovs/flowcast-icecast:$FLOWCAST_RELEASE
  ```

  Ne jamais activer ARM64 sans test réel sur une machine ARM64.
- **Gate :** **GO** si le workflow est vert et les cinq tags existent ; sinon **NO-GO**.

### Étape 4 — Vérifier GHCR sans authentification

- **Action / dépôt :** depuis `FlowCast-Community`, exécuter le helper en lecture seule :

  ```bash
  scripts/release/check-public-images.sh "$FLOWCAST_RELEASE"
  ```

  Équivalent manuel :

  ```bash
  docker logout ghcr.io >/dev/null 2>&1 || true

  for image in \
    flowcast-control \
    flowcast-engine \
    flowcast-analyzer \
    flowcast-bliss \
    flowcast-icecast
  do
    echo "Checking ghcr.io/chourmovs/$image:$FLOWCAST_RELEASE"
    docker buildx imagetools inspect \
      "ghcr.io/chourmovs/$image:$FLOWCAST_RELEASE" \
      >/dev/null
  done
  ```

- **Workflow / paramètres :** aucun ; version `$FLOWCAST_RELEASE` passée au helper.
- **Résultat attendu :** aucune authentification demandée, aucune image absente et un manifest `linux/amd64` pour chacune.
- **Gate :** **GO** si les cinq images sont accessibles anonymement avec `linux/amd64`. **NO-GO** si une image manque, reste privée ou ne contient pas la plateforme ; ne pas poursuivre.

## 3. Construire et publier FlowCast-Community

### Étape 5 — Exécuter obligatoirement le dry-run

- **Action / dépôt :** dans `FlowCast-Community`, lancer **Community prerelease** (`.github/workflows/release.yml`).
- **Paramètres :** `version: $FLOWCAST_RELEASE`, **`publish: false`**.
- **Résultat attendu :** audit public et contrat runtime, rendu des deux Compose, tests unitaires, shellcheck, accès anonyme aux cinq images, puis génération de `images.lock`, archive, manifest, checksums et SBOM sont tous verts.
- **Gate :** **GO** si le dry-run est vert ; **NO-GO** si packaging, audit, tests ou GHCR échouent. La publication est interdite sans ce GO.

### Étape 6 — Examiner les artefacts du dry-run

- **Action / dépôt :** télécharger l'artefact du run et, dans son répertoire, exécuter :

  ```bash
  sha256sum -c checksums.sha256
  tar -tzf "flowcast-community-v$FLOWCAST_RELEASE.tar.gz" | sort
  ```

- **Workflow / paramètres :** artefact produit par le dry-run **Community prerelease**, `publish: false`.
- **Résultat attendu :** `flowcast-community-v$FLOWCAST_RELEASE.tar.gz`, `checksums.sha256`, `images.lock`, `release-manifest.json` et `sbom.spdx.json`. L'archive contient au minimum `compose.yml`, `compose.docker-control.yml`, `.env.example`, `install.sh`, `README.md`, `VERSION`, `images.lock`, `release-manifest.json`, `scripts/` et `docs/`. Elle ne contient ni `.env`, ni `.git`, ni sources privées Rust, secrets, tokens ou fichiers temporaires.
- **Gate :** **GO** si checksums, liste et contenu sont cohérents ; toute absence ou donnée interdite est un **NO-GO**.

### Étape 7 — Qualifier sans publier

La qualification fonctionnelle doit utiliser les artefacts du dry-run (par
exemple depuis un serveur HTTP privé temporaire passé à l'installateur avec
`--release-base-url`). Elle doit couvrir les deux installations vierges, le
mode standard puis le mode `--docker-control`, ainsi que `doctor.sh`, le smoke
test streaming et une observation d'au moins dix minutes. Consigner chaque
résultat dans le rapport de release. **Ne pas utiliser `publish: true` pour
rendre les artefacts installables pendant la qualification.**

Tout `Login failed`, moteur healthy sans mount Icecast, bouton runtime
inopérant, Docker Control demandé mais indisponible, boucle de redémarrage du
moteur, flux sans données, divergence de version, perte de données ou secret
dans les logs impose un **NO-GO**.

### Étape 8 — Publier la prerelease

- **Action / dépôt :** seulement après les deux GO précédents, relancer **Community prerelease** (`.github/workflows/release.yml`).
- **Paramètres :** `version: $FLOWCAST_RELEASE`, **`publish: true`**.
- **Résultat attendu :** GitHub Release publique taguée `v$FLOWCAST_RELEASE`, marquée prerelease, annoncée `linux/amd64` et non production-grade, sans tag `latest`, avec les cinq assets obligatoires listés à l'étape 6.
- **Gate :** **GO** si le workflow est vert et la version est exacte ; sinon **NO-GO**.

### Étape 9 — Vérifier la publication publique

- **Action / dépôt :** interroger `FlowCast-Community` avec GitHub CLI :

  ```bash
  gh release view "v$FLOWCAST_RELEASE" \
    --repo chourmovs/FlowCast-Community

  gh release view "v$FLOWCAST_RELEASE" \
    --repo chourmovs/FlowCast-Community \
    --json assets \
    --jq '.assets[].name'
  ```

- **Workflow / paramètres :** vérification du résultat de **Community prerelease**, `publish: true`.
- **Résultat attendu :** prerelease publiquement visible avec les cinq assets obligatoires.
- **Gate :** **GO** si prerelease et assets sont publics ; asset absent ou mauvaise version = **NO-GO**.

## 4. Tester le oneliner

### Étape 10 — Préparer une machine vierge

- **Action / dépôt :** sur une machine Linux AMD64 sans installation FlowCast existante, vérifier Docker Engine, Compose v2, `curl`, `openssl`, `sha256sum`, `tar`, 10 Go libres et les ports 8080/8010 disponibles :

  ```bash
  docker version
  docker compose version
  openssl version
  df -h /
  ```

- **Workflow / paramètres :** aucun.
- **Résultat attendu :** tous les prérequis et ports sont disponibles.
- **Gate :** **GO** si la machine est réellement vierge et conforme ; sinon **NO-GO**.

### Étape 11 — Installer la prerelease

- **Action / dépôt :** installer depuis le tag public de `FlowCast-Community` :

  ```bash
  curl -fsSL \
    "https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v$FLOWCAST_RELEASE/install.sh" \
    | sudo bash -s -- --version "$FLOWCAST_RELEASE"
  ```

  Omettre `sudo` si l'utilisateur est root ou possède déjà les droits sur le répertoire d'installation.
- **Workflow / paramètres :** aucun ; installateur avec `--version "$FLOWCAST_RELEASE"`.
- **Résultat attendu :** installation dans `/opt/flowcast` sans erreur.
- **Gate :** sortie non nulle ou installation incomplète = **NO-GO** ; sinon **GO**.

### Étape 12 — Contrôler les services et le test fonctionnel minimal

- **Action / dépôt :** sur la machine vierge :

  ```bash
  cd /opt/flowcast
  docker compose \
    --env-file .env \
    -f compose.yml \
    ps
  curl -fsS http://127.0.0.1:8080/api/health
  curl -fsS http://127.0.0.1:8010/status-json.xsl
  ```

- **Workflow / paramètres :** aucun.
- **Résultat attendu :** `storage-init = Exited (0)` ; `icecast`, `bliss`, `control`, `engine` et `audio-daemon = Healthy`.
- [ ] L’interface web est accessible
- [ ] Le premier compte administrateur peut être créé
- [ ] Un fichier audio peut être ajouté ou détecté
- [ ] La station peut être démarrée
- [ ] Le moteur reste healthy
- [ ] L’analyzer reste healthy
- [ ] Bliss reste healthy
- [ ] Le flux Icecast est accessible
- [ ] Un `docker compose restart` conserve la configuration
- **Gate final :** **GO** si installation vierge, interface et flux fonctionnent. Service unhealthy ou flux indisponible = **NO-GO**. Ceci est un smoke test, pas une qualification audio complète.

## 5. Clôturer la release

### Étape 13 — Consigner et annoncer le verdict

- **Action / dépôts :** compléter `RELEASE_CHECKLIST.md`, copier et remplir le [rapport](templates/community-release-report.md), avec versions, SHA, liens des trois runs, digests, machine et anomalies.
- **Workflow / paramètres :** confirmer les résultats de **FlowCast release candidate** (`publish: true`, `publish_arm64: false`) et des deux runs **Community prerelease** (`publish: false`, puis `publish: true`).
- **Résultat attendu :** preuves réutilisables et verdict unique. En cas de NO-GO après publication, arrêter l'annonce et documenter immédiatement l'incident ; ne pas substituer un tag existant.
- **Gate de clôture :** cocher **GO** uniquement si tous les gates précédents sont GO. Toute case bloquante donne **NO-GO**.
