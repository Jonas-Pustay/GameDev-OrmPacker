#!/usr/bin/env bash
# Tests de fumée : textures synthétiques → vérification des canaux, noms, 4:4:4.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
SCRIPT="$PWD/orm-pack.sh"
if command -v magick >/dev/null 2>&1; then IM=(magick); else IM=(convert); fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

gray() { "${IM[@]}" -size 64x64 xc:"rgb($2,$2,$2)" -depth 8 "$1"; }
px()   { "${IM[@]}" "$1" -format '%[fx:int(255*u.r+0.5)] %[fx:int(255*u.g+0.5)] %[fx:int(255*u.b+0.5)]' info: 2>/dev/null; }
check() {
  if [[ "$2" == "$3" ]]; then printf '  ✔ %s\n' "$1"; PASS=$((PASS+1))
  else printf '  ✖ %s\n     attendu [%s]\n     obtenu  [%s]\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}

echo "1. Nommage lowercase + 3 cartes"
d="$TMP/c1"; mkdir -p "$d"
gray "$d/test_ao_2k.png" 128; gray "$d/test_rough_2k.png" 64; gray "$d/test_metal_2k.png" 200
bash "$SCRIPT" "$d" >/dev/null
check "canaux + nom" "128 64 200" "$(px "$d/test_orm_2k.png")"

echo "2. AO et metalness absents"
d="$TMP/c2"; mkdir -p "$d"
gray "$d/Mat_8K-JPG_Roughness.png" 90
bash "$SCRIPT" "$d" >/dev/null
check "R=blanc B=noir" "255 90 0" "$(px "$d/Mat_8K-JPG_ORM.png")"

echo "3. Suffixe de workflow _4K_METALNESS + Preview"
d="$TMP/c3"; mkdir -p "$d"
gray "$d/Mat_COL_4K_METALNESS.png" 10
gray "$d/Mat_METALNESS_4K_METALNESS.png" 200
gray "$d/Mat_ROUGHNESS_4K_METALNESS.png" 70
gray "$d/Mat_Preview1.png" 250
bash "$SCRIPT" "$d" >/dev/null
check "tag workflow ignoré" "255 70 200" "$(px "$d/Mat_ORM_4K_METALNESS.png")"

echo "4. Préfixe 'metal_' ne doit pas être pris pour metallic"
d="$TMP/c4"; mkdir -p "$d"
gray "$d/metal_0081_color_4k.png" 240
gray "$d/metal_0081_ao_4k.png" 100
gray "$d/metal_0081_roughness_4k.png" 50
gray "$d/metal_0081_metallic_4k.png" 255
gray "$d/metal_0081_preview.png" 5
bash "$SCRIPT" "$d" >/dev/null
check "détection par token" "100 50 255" "$(px "$d/metal_0081_orm_4k.png")"

echo "5. JPEG : création + 4:4:4"
d="$TMP/c5"; mkdir -p "$d"
"${IM[@]}" -size 64x64 xc:'rgb(128,128,128)' -quality 92 "$d/t_ao_1k.jpg"
"${IM[@]}" -size 64x64 xc:'rgb(64,64,64)'    -quality 92 "$d/t_rough_1k.jpg"
bash "$SCRIPT" "$d" >/dev/null
check "fichier créé" "oui" "$([[ -f "$d/t_orm_1k.jpg" ]] && echo oui)"
check "pas de chroma subsampling" "1x1,1x1,1x1" \
  "$("${IM[@]}" identify -format '%[jpeg:sampling-factor]' "$d/t_orm_1k.jpg" 2>/dev/null)"

echo "6. Idempotence"
check "relance = skip" "oui" "$(bash "$SCRIPT" "$TMP/c1" | grep -q 'déjà présent' && echo oui)"

echo "7. Repli Glossiness inversé"
d="$TMP/c7"; mkdir -p "$d"
gray "$d/M_Glossiness.png" 200
bash "$SCRIPT" "$d" >/dev/null
check "roughness = 255-gloss" "255 55 0" "$(px "$d/M_ORM.png")"

printf '\n── %d réussis, %d échoués\n' "$PASS" "$FAIL"
exit $(( FAIL > 0 ))
