#!/usr/bin/env bash
# local-sound-pipeline 主流水线
set -euo pipefail
ASSET_LIB="${ASSET_LIB:-$HOME/Movies/dsh-sound-assets}"

usage() {
  cat <<'EOF'
用法:
  pipeline.sh render <sfx-id> <out.wav> [--apex SEC] [--dur SEC]   Earshot 渲染单条音效
  pipeline.sh kit [calm|crisp|minimal|launch] <out-dir>          按预设批量渲染整套音效（免模型）
  pipeline.sh mix <bgm> <voice> <out> [sfx.wav ...]                ffmpeg 混音（BGM压低+旁白+音效）
  pipeline.sh timeline <film.mp4>                                  声画同步分析
  pipeline.sh doctor                                               环境自检
EOF
}

case "${1:-}" in
  render)
    id="$2"; out="$3"; shift 3
    earshot sfx render "$id" -o "$out" "$@"
    ;;
  kit)
    preset="${2:-calm}"; outdir="${3:-/tmp/earshot-kit}"
    mkdir -p "$outdir"
    kitfile="$outdir/kit.json"
    earshot kit init --preset "$preset" -o "$kitfile"
    earshot kit render "$kitfile" --out "$outdir"
    earshot kit check "$kitfile" --out "$outdir"
    earshot kit audition "$kitfile" -o "$outdir/audition.wav"
    ;;
  mix)
    bgm="$2"; voice="$3"; out="$4"; shift 4
    sfx=("$@")
    filt="[0:a]volume=0.45[bg];[1:a]volume=1.0[vo]"
    i=2
    for s in "${sfx[@]:-}"; do
      [[ -z "$s" ]] && continue
      filt="$filt;[$i:a]volume=0.8[sfx$i]"
      i=$((i+1))
    done
    map="[bg][vo]"
    j=2
    for s in "${sfx[@]:-}"; do
      [[ -z "$s" ]] && continue
      map="$map[sfx$j]"
      j=$((j+1))
    done
    nsfx=$((j-2))
    filt="$filt;$map amix=inputs=$((2+nsfx)):duration=longest[out]"
    inputs=(-i "$bgm" -i "$voice")
    for s in "${sfx[@]:-}"; do [[ -n "$s" ]] && inputs+=(-i "$s"); done
    ffmpeg "${inputs[@]}" -filter_complex "$filt" -map "[out]" -c:a aac "$out"
    ;;
  timeline)
    earshot timeline "$2" --video "$2"
    ;;
  doctor)
    command -v earshot >/dev/null || { echo "❌ earshot 未装，先跑 setup.sh"; exit 1; }
    command -v ffmpeg >/dev/null || { echo "❌ ffmpeg 未装"; exit 1; }
    echo "✅ earshot + ffmpeg 就绪"
    earshot doctor
    ffmpeg -version | head -1
    ;;
  *)
    usage; exit 1;;
esac

