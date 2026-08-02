# FlowCast Community Release Checklist

[Runbook opérateur détaillé](docs/release/community-beta-release.md)

Version: `________________`
FlowCast commit: `________________`
FlowCast-Community commit: `________________`
Date: `________________`

## FlowCast
- [ ] Main à jour
- [ ] Beta CI verte
- [ ] Cinq images publiées
- [ ] Cinq images accessibles anonymement

## FlowCast-Community dry-run
- [ ] Validate vert
- [ ] Community prerelease avec `publish=false` vert
- [ ] Archive vérifiée
- [ ] Checksums valides
- [ ] `images.lock` complet

## Publication
- [ ] Community prerelease avec `publish=true` verte
- [ ] Tag correct
- [ ] Cinq assets présents
- [ ] Release marquée prerelease

## Fresh install
- [ ] Installation vierge réussie
- [ ] Six services dans l’état attendu
- [ ] API control accessible
- [ ] Icecast accessible
- [ ] Test fonctionnel minimal réussi
- [ ] `test-runtime-stream.sh` reçoit le minimum d'octets sans restart engine
- [ ] Qualification standard affiche `docker_control=DISABLED`
- [ ] Qualification opt-in sur machine vierge affiche `docker_control=PASS`

## Verdict
- [ ] GO
- [ ] NO-GO

Notes:
