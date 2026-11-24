#!/usr/bin/env bash
# orm-pack — AO + Roughness + Metalness -> ORM (R,G,B)
# Dépendance : ImageMagick. Garde le nom, le format, la résolution et la qualité.
set -uo pipefail

SUFFIX="ORM"; RECURSIVE=1; FORCE=0; DRY=0; QUAL=""; OUTFMT=""; GLOSS=1
ROOTS=(); CREATED=0; SKIPPED=0; FAILED=0

usage() {
cat <<'TXT'
orm-pack — crée les textures ORM (R=AO, G=Roughness, B=Metalness)
Usage : orm-pack [options] [dossier ...]     (défaut : dossier courant, récursif)
  -n, --dry-run    montre ce qui serait fait, n'écrit rien
  -f, --force      régénère / écrase les ORM existantes
      --here       seulement le dossier courant (pas les sous-dossiers)
      --png        forcer la sortie PNG      --jpg  forcer la sortie JPEG
  -q, --quality N  qualité JPEG (défaut : qualité estimée de la source)
  -s, --suffix TXT token de sortie (défaut : ORM)
      --no-gloss   ne pas utiliser Glossiness inversé si Roughness absent
  -h, --help
TXT
}

while (( $# )); do
  case "$1" in
    -n|--dry-run) DRY=1;; -f|--force) FORCE=1;;
    --here|--no-recursive) RECURSIVE=0;;
    --png) OUTFMT="png";; --jpg|--jpeg) OUTFMT="jpg";;
    -q|--quality) QUAL="${2:-}"; shift;;
    -s|--suffix) SUFFIX="${2:-ORM}"; shift;;
    --no-gloss) GLOSS=0;; -h|--help) usage; exit 0;;
    -*) echo "Option inconnue : $1" >&2; exit 1;;
    *) ROOTS+=("$1");;
  esac; shift
done

if command -v magick >/dev/null 2>&1; then IM=(magick); IDENT=(magick identify)
elif command -v convert >/dev/null 2>&1; then IM=(convert); IDENT=(identify)
else echo "ImageMagick requis : sudo apt install imagemagick" >&2; exit 1; fi

process_dir() {
  local dir="$1" f base stem ext spaced tok lt c sep key outname newtok
  local i n idx prev found=0 header=0
  local -a pieces cats args
  local -A SRC=() NAME=() KEYS=()

  # --- 1. classement de chaque image du dossier -------------------------------
  while IFS= read -r -d '' f; do
    base="${f##*/}"; ext="${base##*.}"; stem="${base%.*}"
    [[ "${stem,,}" =~ (^|[_ .-])(preview|thumb|thumbnail|icon|sample|render)[0-9]*([_ .-]|$) ]] && continue
    # découpe en tokens en conservant le séparateur collé à chaque token
    spaced="$(printf '%s' "$stem" | sed 's/[_ .-]/& /g')"
    read -r -a pieces <<< "$spaced"; n=${#pieces[@]}; cats=()
    for ((i=0;i<n;i++)); do
      tok="${pieces[i]%[_ .-]}"; lt="${tok,,}"
      case "$lt" in
        ao|occ|occlusion|ambient|ambientocclusion|ambientocc|aomap) c=ao;;
        rough|roughness|rgh)                                      c=rough;;
        metal|metallic|metalness|metallness|metalic|met)          c=metal;;
        gloss|glossiness|smooth|smoothness)                       c=gloss;;
        col|color|colour|basecolor|basecolour|diff|diffuse|albedo|alb|d) c=color;;
        nor|nrm|nrm16|norm|normal|normalgl|normaldx|normalopengl|normaldirectx|n) c=normal;;
        disp|displacement|height|hgt|bump)                        c=height;;
        spec|specular|specularlevel|reflection|refl)              c=spec;;
        orm|arm|rma|ormh|packed)                                  c=packed;;
        *) c=;;
      esac
      cats[i]="$c"
    done
    idx=-1; for ((i=0;i<n;i++)); do [[ -n "${cats[i]}" ]] && idx=$i; done
    (( idx < 0 )) && continue
    # suffixe de workflow "..._4K_METALNESS" : on l'ignore si un autre type existe
    if (( idx == n-1 )) && [[ "${cats[idx]}" == metal || "${cats[idx]}" == spec ]]; then
      prev=-1; for ((i=0;i<n-1;i++)); do [[ -n "${cats[i]}" ]] && prev=$i; done
      (( prev >= 0 )) && idx=$prev
    fi
    c="${cats[idx]}"; tok="${pieces[idx]%[_ .-]}"
    if [[ "$tok" == "${tok,,}" ]]; then newtok="${SUFFIX,,}"; else newtok="${SUFFIX^^}"; fi
    key=""; outname=""
    for ((i=0;i<n;i++)); do
      tok="${pieces[i]%[_ .-]}"; sep="${pieces[i]#"$tok"}"
      if (( i == idx )); then key+="@$sep"; outname+="$newtok$sep"
      else key+="${pieces[i]}"; outname+="${pieces[i]}"; fi
    done
    KEYS["$key"]=1
    if [[ -z "${SRC["$key|$c"]:-}" ]]; then
      SRC["$key|$c"]="$f"; NAME["$key|$c"]="$outname.$ext"
    fi
    found=1
  done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \
      -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.webp' \
      -o -iname '*.tga' -o -iname '*.bmp' \) -print0 | sort -z)

  (( found )) || return 0

  # --- 2. fabrication d'une ORM par matériau ----------------------------------
  local ao ro me gl rokey inv refname outext outstem out src fmt w h q d W H D Q
  for key in "${!KEYS[@]}"; do
    ao="${SRC["$key|ao"]:-}"; ro="${SRC["$key|rough"]:-}"
    me="${SRC["$key|metal"]:-}"; gl="${SRC["$key|gloss"]:-}"
    rokey="rough"; inv=0
    if [[ -z "$ro" && -n "$gl" ]] && (( GLOSS )); then ro="$gl"; rokey="gloss"; inv=1; fi
    (( header )) || { printf '\n📁 %s\n' "$dir"; header=1; }
    if [[ -z "$ro" ]]; then echo "   ⏭  ignoré : pas de roughness"; SKIPPED=$((SKIPPED+1)); continue; fi
    if [[ -n "${SRC["$key|packed"]:-}" ]] && (( ! FORCE )); then
      printf '   ⏭  %s déjà présent\n' "${SRC["$key|packed"]##*/}"; SKIPPED=$((SKIPPED+1)); continue; fi
    if [[ -n "$ao" ]]; then refname="${NAME["$key|ao"]}"; else refname="${NAME["$key|$rokey"]}"; fi
    outstem="${refname%.*}"; outext="${refname##*.}"
    [[ -n "$OUTFMT" ]] && outext="$OUTFMT"
    out="$dir/$outstem.$outext"
    if [[ -e "$out" ]] && (( ! FORCE )); then
      printf '   ⏭  %s déjà présent\n' "${out##*/}"; SKIPPED=$((SKIPPED+1)); continue; fi

    W=0; H=0; D=8; Q=0
    for src in "$ao" "$ro" "$me"; do
      [[ -n "$src" ]] || continue
      IFS='|' read -r fmt w h q d < <("${IDENT[@]}" -ping -format '%m|%w|%h|%Q|%[depth]' "$src")
      [[ "$w" =~ ^[0-9]+$ ]] || continue
      (( w > W )) && W=$w; (( h > H )) && H=$h
      [[ "$d" =~ ^[0-9]+$ ]] && (( d > D )) && D=$d
      if [[ "${fmt^^}" == JPEG && "$q" =~ ^[0-9]+$ ]]; then (( q > Q )) && Q=$q; fi
    done
    (( W && H )) || { echo "   ✖ lecture impossible" >&2; FAILED=$((FAILED+1)); continue; }
    (( Q > 0 )) || Q=95
    [[ -n "$QUAL" ]] && Q="$QUAL"

    args=( -limit memory 1GiB -limit map 2GiB )
    if [[ -n "$ao" ]]; then args+=( \( "${ao}[0]" -channel R -separate +channel -resize "${W}x${H}!" \) )
    else args+=( \( -size "${W}x${H}" xc:white \) ); fi
    if (( inv )); then args+=( \( "${ro}[0]" -channel R -separate +channel -negate -resize "${W}x${H}!" \) )
    else args+=( \( "${ro}[0]" -channel R -separate +channel -resize "${W}x${H}!" \) ); fi
    if [[ -n "$me" ]]; then args+=( \( "${me}[0]" -channel R -separate +channel -resize "${W}x${H}!" \) )
    else args+=( \( -size "${W}x${H}" xc:black \) ); fi
    args+=( -combine -colorspace sRGB -type TrueColor -alpha off -strip )
    case "${outext,,}" in
      jpg|jpeg) args+=( -depth 8 -quality "$Q" -sampling-factor 4:4:4 );;
      png)      args+=( -depth "$D" -define PNG:compression-level=9 );;
      tif|tiff) args+=( -depth "$D" -compress none );;
      webp)     args+=( -define webp:lossless=true -quality 100 );;
      *)        args+=( -depth 8 );;
    esac
    args+=( "$out" )

    if (( DRY )); then printf '   [dry] %s %s\n' "${IM[*]}" "${args[*]}"
    elif "${IM[@]}" "${args[@]}"; then
      printf '   ✔ %-55s %sx%s %s q%s  R=%s G=%s B=%s\n' "${out##*/}" "$W" "$H" \
        "${outext^^}" "$Q" "$([[ -n $ao ]] && echo AO || echo blanc)" \
        "$([[ $inv == 1 ]] && echo 1-Gloss || echo Rough)" \
        "$([[ -n $me ]] && echo Metal || echo noir)"
      CREATED=$((CREATED+1))
    else echo "   ✖ échec : $out" >&2; FAILED=$((FAILED+1)); fi
  done
}

(( ${#ROOTS[@]} )) || ROOTS=(".")
for root in "${ROOTS[@]}"; do
  [[ -d "$root" ]] || { echo "Pas un dossier : $root" >&2; continue; }
  if (( RECURSIVE )); then
    while IFS= read -r -d '' d; do process_dir "$d"; done < <(find "$root" -type d -print0 | sort -z)
  else process_dir "$root"; fi
done
printf '\n── %d ORM créée(s), %d ignorée(s), %d erreur(s)\n' "$CREATED" "$SKIPPED" "$FAILED"
