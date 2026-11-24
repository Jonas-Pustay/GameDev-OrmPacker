<div align="center">

# 📦 GameDev-OrmPacker
**La commande `orm-pack` : une commande dans un dossier de textures PBR, et l'ORM est prête.**

[![CI](https://github.com/TON_PSEUDO/GameDev-OrmPacker/actions/workflows/ci.yml/badge.svg)](https://github.com/TON_PSEUDO/GameDev-OrmPacker/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Bash](https://img.shields.io/badge/bash-5%2B-4EAA25?logo=gnubash&logoColor=white)
![ImageMagick](https://img.shields.io/badge/ImageMagick-6%20%7C%207-005C99)
![Platform](https://img.shields.io/badge/Linux-Mint%20·%20Ubuntu%20·%20Debian-FCC624?logo=linux&logoColor=black)

</div>

---

## TL;DR

```bash
cd ~/Textures/Metal032_4K-JPG
orm-pack
#    ✔ Metal032_4K-JPG_ORM.jpg   4096x4096 JPEG q92  R=AO G=Rough B=Metal
```

Ou sur une bibliothèque entière, d'un seul coup :

```bash
cd ~/Textures            # 59 dossiers de packs téléchargés
orm-pack --dry-run       # simulation
orm-pack                 # tout est packé, dossier par dossier
```

## Pourquoi ?

Vous téléchargez des packs PBR (ambientCG, Poliigon, TextureCan, …). Certains contiennent
une ORM, la plupart non. Les noms changent d'un fournisseur à l'autre, les canaux manquants
aussi, et les convertir à la main dans GIMP/Krita prend des plombes — sans parler du JPEG
qui, par défaut, **détruit les canaux R et B** avec son sous-échantillonnage chroma.

`orm-pack` fait le travail en une commande, sans rien écraser, sans rien dégrader.

## Fonctionnalités

- 🧠 **Détection automatique** des cartes par tokens : `ao`, `AO`, `AmbientOcclusion`,
  `rough`, `roughness`, `ROUGHNESS`, `metal`, `metallic`, `metalness`, `Metalness`…
  Séparateurs `_`, `-`, `.`, espace. Casse du nom d'origine reproduite (`_orm_` vs `_ORM`).
- 🕳️ **Cartes manquantes gérées** : pas d'AO → canal R blanc ; pas de metalness → canal B noir.
- 🎯 **Pièges évités** : `metal_0081_color_4k.jpg` n'est pas pris pour du metallic,
  le suffixe de workflow `..._COL_4K_METALNESS.jpg` n'est pas pris pour la carte metalness,
  les `Preview.png` / `*_Preview1.png` / `*_preview.jpg` sont ignorés.
- 🗂️ **Multi-matériaux et multi-résolutions** dans un même dossier : une ORM par groupe.
- 🌳 **Récursif** : les sous-dossiers `4K/`, `8K/` sont traités tout seuls.
- 💎 **Zéro perte** : format, résolution, profondeur (8/16 bits) et qualité JPEG d'origine
  conservés. JPEG forcé en **4:4:4** (indispensable pour une ORM).
- 🔁 **Idempotent** : relancer ne réécrit rien (`--force` pour régénérer).
- 🪶 **Une seule dépendance** : ImageMagick. Pas de Python, pas de venv, pas de Docker.

## Installation

### Dépendances

```bash
sudo apt install imagemagick        # Debian / Ubuntu / Mint
# sudo dnf install ImageMagick      # Fedora
# sudo pacman -S imagemagick        # Arch
```

### Méthode rapide

```bash
git clone https://github.com/TON_PSEUDO/GameDev-OrmPacker.git
cd orm-pack
./install.sh                        # → ~/.local/bin/orm-pack
```

### Méthode manuelle

```bash
mkdir -p ~/.local/bin
install -m 755 orm-pack.sh ~/.local/bin/orm-pack
```

`~/.local/bin` est déjà dans le `PATH` sur Linux Mint / Ubuntu. Sinon :

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

Vérification : `orm-pack --help`

## Utilisation

```bash
orm-pack [options] [dossier ...]
```

Sans argument : dossier courant **+ tous ses sous-dossiers**.

| Option | Effet |
|---|---|
| `-n`, `--dry-run` | Affiche les commandes ImageMagick, n'écrit rien |
| `-f`, `--force` | Régénère / écrase les ORM existantes |
| `--here` | Traite uniquement le dossier courant, pas les sous-dossiers |
| `--png` | Force la sortie PNG (recommandé pour les data maps) |
| `--jpg` | Force la sortie JPEG |
| `-q N`, `--quality N` | Qualité JPEG (défaut : qualité estimée de la source) |
| `-s TXT`, `--suffix TXT` | Token de sortie (défaut `ORM`, ex. `--suffix ARM`) |
| `--no-gloss` | N'utilise pas `Glossiness` inversé quand `Roughness` manque |
| `-h`, `--help` | Aide |

### Exemples

```bash
orm-pack                                   # bibliothèque entière, récursif
orm-pack --here                            # juste ce dossier
orm-pack --dry-run ~/Textures              # vérifier avant de lancer
orm-pack --force --png ~/Textures/Metal032 # régénérer en PNG sans perte
orm-pack -q 100 --suffix ARM               # JPEG q100, nom *_ARM.*
```

## Avant / après

```
Metal032_4K-JPG/
├── Metal032_4K-JPG_AmbientOcclusion.jpg
├── Metal032_4K-JPG_Color.jpg
├── Metal032_4K-JPG_Metalness.jpg
├── Metal032_4K-JPG_NormalGL.jpg
├── Metal032_4K-JPG_Roughness.jpg
└── Metal032_4K-JPG_ORM.jpg          ← créé
```

Cas réels gérés :

| Dossier | ORM produite | Canaux |
|---|---|---|
| `asphalt_04_ao_8k.jpg` + `_rough_8k.jpg` | `asphalt_04_orm_8k.jpg` | AO · Rough · **noir** |
| `Concrete023_..._Roughness.jpg` seul | `Concrete023_8K-JPG_ORM.jpg` | **blanc** · Rough · **noir** |
| `Material-121-A_{AmbientOcclusion,Roughness,Metallic}.jpg` | `Material-121-A_ORM.jpg` | AO · Rough · Metal |
| `Metal..._ROUGHNESS_4K_METALNESS.jpg` | `Metal..._ORM_4K_METALNESS.jpg` | **blanc** · Rough · Metal |
| `Poliigon_X/4K/*` | `Poliigon_X/4K/Poliigon_X_ORM.jpg` | AO · Rough · Metal |

## Conventions reconnues

| Type | Tokens acceptés (insensible à la casse) |
|---|---|
| **Occlusion → R** | `ao`, `occ`, `occlusion`, `ambient`, `ambientocclusion`, `ambientocc`, `aomap` |
| **Roughness → G** | `rough`, `roughness`, `rgh` |
| **Metalness → B** | `metal`, `metallic`, `metalness`, `metallness`, `metalic`, `met` |
| Repli roughness | `gloss`, `glossiness`, `smooth`, `smoothness` (inversé : `1 - gloss`) |
| Ignorés | color/basecolor/diffuse/albedo, normal/nrm/nor, height/disp/bump, specular, mask, preview |
| Déjà packé (skip) | `orm`, `arm`, `rma`, `ormh`, `packed` |

Un nom non reconnu ? Ouvre une [issue](../../issues) avec la sortie de `ls -1`, c'est
trois lignes à ajouter dans le `case` du script.

## Comment ça marche

Pour chaque dossier, le script découpe les noms en tokens (`_ - . espace`), classe les
images, puis regroupe celles qui partagent le même préfixe/suffixe. Il en déduit le nom de
sortie en remplaçant **uniquement le token de type** — le reste du nom est intact.

Puis, pour un groupe :

```bash
magick \
  \( ao.jpg    -channel R -separate +channel \) \
  \( rough.jpg -channel R -separate +channel \) \
  \( metal.jpg -channel R -separate +channel \) \
  -combine -colorspace sRGB -type TrueColor -alpha off \
  -quality 92 -sampling-factor 4:4:4 out_ORM.jpg
```

- `-channel R -separate` : extraction **brute** du canal, aucune conversion gamma.
- `-combine` : R ← image 1, G ← image 2, B ← image 3.
- `-type TrueColor` : empêche IM d'écrire un JPEG « niveaux de gris » quand les canaux se ressemblent.
- `-sampling-factor 4:4:4` : **le point critique**. En JPEG 4:2:0, R et B sont de la
  chrominance sous-échantillonnée → AO et metallic baveux. Ici, chaque canal reste plein pot.
- Qualité : `identify %Q` ré-estime la qualité source depuis les tables de quantification ;
  la plus élevée des trois sources est réutilisée.
- Tailles hétérogènes : tout est aligné sur la plus grande résolution.
- 8K : `-limit memory 1GiB -limit map 2GiB` évite l'OOM (bascule sur disque plutôt que de mourir).

## Import dans les moteurs

L'ORM est une **data map**, pas une couleur :

| Moteur | Réglage |
|---|---|
| **Godot 4** | Import → désactiver sRGB / mode Non-Color, puis `StandardMaterial3D` → ORM |
| **Unreal** | Texture → Compression `Masks`, sRGB **off**, Sampler Type `Masks` / `Linear Color` |
| **Unity (URP/HDRP)** | Texture Type `Default`, **sRGB (Color Texture) off** |
| **glTF / three.js / Bevy** | Convention native : R=Occlusion, G=Roughness, B=Metallic |

> ⚠️ **Unity HDRP** utilise une *Mask Map* différente (R=Metallic, G=AO, B=Detail, A=Smoothness).
> `orm-pack` produit du ORM standard glTF/Unreal/Godot, pas du HDRP.

## Tests

```bash
make test          # ou : bash tests/smoke.sh
make lint          # shellcheck + bash -n
```

Les tests fabriquent des textures synthétiques aux valeurs connues et vérifient au pixel
près les canaux produits, les noms de sortie, le 4:4:4 et l'idempotence.

## Limitations

- Ne télécharge rien, ne renomme pas vos sources, ne touche pas aux `.mtlx` / `.tres` / `.blend`.
- Pas de gestion des normal maps DirectX → OpenGL (autre problème, autre outil).
- Pas d'AO baked depuis un height map : si l'AO manque, le canal est blanc, point.
- Bash 4.3+ (tables associatives). Testé sur Mint 21/22, Ubuntu 22.04/24.04, ImageMagick 6 et 7.

## Roadmap

- [ ] `--order` pour choisir l'ordre des canaux (Mask Map HDRP, ARM, RMA…)
- [ ] `--jobs N` pour paralléliser les dossiers
- [ ] Option `--resize 4096` pour downsampler à la volée
- [ ] Backend `libvips` (beaucoup plus rapide et sobre en RAM sur du 8K)
- [ ] Action Nemo / Nautilus « Créer les ORM ici » (voir `extras/`)

## Contribuer

Les PR sont bienvenues — surtout pour ajouter des conventions de nommage.
Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

[MIT](LICENSE) — faites-en ce que vous voulez. Les textures que vous packez restent les vôtres
(respectez la licence du fournisseur, CC0 pour ambientCG par exemple).
