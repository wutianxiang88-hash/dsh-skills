#!/usr/bin/env bash
# local-sound-pipeline 安装器：GitHub 克隆 earshot、建 venv、装 CPU 版 torch、建素材库、上 PATH
set -euo pipefail
ASSET_LIB="${ASSET_LIB:-$HOME/Movies/dsh-sound-assets}"
ROOT="${ROOT:-$HOME/.local/share/dsh-sound-pipeline}"
SRC="$ROOT/earshot"
# 1. 找 >=3.10 的 Python（系统 3.7 太旧；README 要求 3.10+）
PY=""
for cand in python3.13 python3.12 python3.11 python3.10; do
  p="$(command -v "$cand" 2>/dev/null || true)"
  if [[ -n "$p" ]] && "$p" -c 'import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)' 2>/dev/null; then
    PY="$p"; break
  fi
done
if [[ -z "$PY" ]]; then echo "❌ 未找到 >=3.10 的 Python（本机系统 python3=3.7）。请安装：brew install python@3.12"; exit 1; fi
echo "✅ Python: $PY ($("$PY" --version 2>&1))"
# 2. 克隆 earshot（PyPI 的 earshot 是无关 VAD 库，必须从 GitHub 装）
mkdir -p "$ROOT"
if [[ ! -d "$SRC/.git" ]]; then echo "ℹ️ git clone https://github.com/Leonxlnx/earshot"; git clone --depth 1 https://github.com/Leonxlnx/earshot "$SRC"; else echo "ℹ️ 已克隆，跳过"; fi
# 3. 建独立 venv（uv/PEP668 管理的 Python 不允许 pip install --user）
if [[ ! -x "$SRC/.venv/bin/python" ]]; then "$PY" -m venv "$SRC/.venv"; fi
# 4. CPU 版 torch（避免拉 CUDA 大包）
"$SRC/.venv/bin/python" -m pip install torch --index-url https://download.pytorch.org/whl/cpu
# 5. earshot 本体
"$SRC/.venv/bin/python" -m pip install --no-build-isolation --timeout 120 --retries 6 -i https://mirrors.aliyun.com/pypi/simple -e "$SRC[mcp,llm,dev]"
# 6. 上 PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$SRC/.venv/bin/earshot" "$HOME/.local/bin/earshot"
PROFILE="$HOME/.zshrc"
touch "$PROFILE"
if ! grep -q 'dsh-sound-pipeline/earshot/.venv' "$PROFILE" 2>/dev/null; then
  echo '' >> "$PROFILE"
  echo '# dsh local-sound-pipeline (earshot)' >> "$PROFILE"
  echo 'export PATH="$HOME/.local/share/dsh-sound-pipeline/earshot/.venv/bin:$PATH"' >> "$PROFILE"
fi
export PATH="$SRC/.venv/bin:$HOME/.local/bin:$PATH"
# 7. 验证
echo "--- earshot doctor --load ---"; "$SRC/.venv/bin/python" -m earshot doctor --load || true
echo "--- earshot sfx list (前5) ---"; "$SRC/.venv/bin/python" -m earshot sfx list | head -5 || true
# 8. 建素材库
mkdir -p "$ASSET_LIB"/{bgm,ambience,sfx,voice}
if [[ ! -f "$ASSET_LIB/manifest.json" ]]; then echo '{}' > "$ASSET_LIB/manifest.json"; fi
echo "✅ 素材库: $ASSET_LIB"
echo "✅ 完成。重启 shell 或 source ~/.zshrc 后全局可用。"
echo "ℹ️ 首次使用模型会下载 ~1.1GB 到 .cache/hf，之后离线。"
