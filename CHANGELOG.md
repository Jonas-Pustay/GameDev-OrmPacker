
### `CHANGELOG.md`

```markdown
# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) · versionnage [SemVer](https://semver.org/lang/fr/).

## [Non publié]

## [1.0.0] - 2026-11-24
### Ajouté
- Packing AO / Roughness / Metalness → ORM (R, G, B) via ImageMagick 6 ou 7.
- Détection des cartes par tokens, insensible à la casse, séparateurs `_ - . espace`.
- Gestion des cartes manquantes : AO absent → R blanc, metalness absent → B noir.
- Ignorance des suffixes de workflow (`..._4K_METALNESS`) et des fichiers Preview.
- Regroupement multi-matériaux / multi-résolutions, traitement récursif des sous-dossiers.
- Préservation du nom, du format, de la résolution, de la profondeur et de la qualité JPEG.
- JPEG forcé en 4:4:4 pour ne pas détruire les canaux R et B.
- Repli `Glossiness` inversé quand `Roughness` est absent.
- Options `--dry-run`, `--force`, `--here`, `--png`, `--jpg`, `--quality`, `--suffix`, `--no-gloss`.
- Idempotence : les ORM existantes ne sont pas réécrites sans `--force`.
- `install.sh`, `Makefile`, tests de fumée et CI GitHub Actions.
