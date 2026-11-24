# Contribuer

Merci ! Le cas d'usage le plus fréquent est **ajouter une convention de nommage** :
c'est literallement trois lignes.

## Mise en place

```bash
git clone https://github.com/TON_PSEUDO/GameDev-OrmPacker.git
cd orm-pack
sudo apt install imagemagick shellcheck
make test
```

## Ajouter des noms de cartes

Tout se joue dans le bloc `case "$lt" in` de `orm-pack.sh` :

```bash
rough|roughness|rgh)   c=rough;;
```

Règles à respecter :

1. **Tokens entiers uniquement**, jamais de sous-chaîne : sinon `MetalGalvanizedSteelWorn001`
   serait détecté comme une carte metallic.
2. Pas de token d'une seule lettre pour `metal` / `ao` : `Material-121-A_...` contient un `A`
   qui n'est qu'une variante.
3. Le token le plus **à droite** gagne (les préfixes comme `metal_0081_` sont à gauche).
4. Un token `metal`/`spec` en **dernière position** est un tag de workflow : il est ignoré
   s'il existe un autre type reconnu avant lui.
5. Ajoute un cas dans `tests/smoke.sh` avec les noms de fichiers réels.

## Style

- Bash, pas de dépendance autre qu'ImageMagick et les coreutils.
- `shellcheck -S warning` doit passer, `bash -n` aussi.
- Messages utilisateur en français, commentaires de code en français.
- Pas de `set -e` : le script compte ses erreurs et continue sur les autres dossiers.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/fr/) : `feat:`, `fix:`, `docs:`,
`test:`, `refactor:`, `chore:`.
