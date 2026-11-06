---
name: local-sound-pipeline
description: 本地优先的声音流水线：Earshot 本地合成为主、ffmpeg 混音、云端源一次性下载兜底，为 AI 视频/动画做零外网零 API 费的音效与 BGM 后期。
---

# 本地优先声音流水线（local-sound-pipeline）

为 AI 视频 / HyperFrames 项目做声音设计时使用。核心：**Earshot 本地合成为主，ffmpeg 混音，云端源降级为一次性下载兜底**，绕开本机 Pixabay 反爬(403)、Mixkit 极慢(~20s/请求) 的网络硬伤。

## 何时使用
- 给视频/动画加音效、BGM、环境音、转场音
- 需要声画同步、按时间轴批量渲染音效
- 想零外网、零 API 费完成声音后期

## 核心原则
1. **Earshot 为主力音效引擎**：纯本地 CPU、不联网、自带 252 种代码合成音效（文章所称 201 已过时）。
2. **ffmpeg 为混音主力**：本机已装 ffmpeg 9.0.2。
3. **云端源一次性下载进本地素材库**，后续离线复用。
4. **不需要 Claude Code**：Earshot 提供 CLI / Python API / MCP server，DSH 可直接驱动。

## 前置检查
```bash
command -v earshot || echo earshot-未装
ffmpeg -version | head -1
python3 --version   # 系统 3.7 偏旧，Earshot 需要 3.10+
```
- earshot 未装：跑 `setup.sh`（克隆 GitHub 仓库、建 venv、装 CPU 版 torch、symlink 到 ~/.local/bin）。
- 验证：`earshot doctor --load`；`earshot sfx list`（应列出 252 种）。

## 安装要点（易错）
- **PyPI 上的 `earshot` 是另一个无关的语音活动检测(VAD)库**，不是本引擎。必须从 GitHub 装。
- **Python ≥ 3.10**（README 要求），系统 python3=3.7 不可用。
- **CPU 版 torch**：`pip install torch --index-url https://download.pytorch.org/whl/cpu`。
- **首次用模型下载 ~1.1GB**（CLAP + AudioSet tagger）到 `.cache/hf`（可用 `EARSHOT_HOME` 改路径），之后离线。
- 离线模式：`EARSHOT_OFFLINE=1`。

## 主引擎 Earshot 常用命令
```bash
earshot sfx list                      # 列出全部音效
earshot sfx render whoosh -o x.wav --apex 1.2 --dur 0.8
earshot kit init --preset calm -o kit.json && earshot kit render kit.json --out out/ && earshot kit check kit.json --out out/
earshot timeline film.mp4   # 声画同步分析（需模型）
earshot describe enter.ogg           # 听一个声音
earshot critique film.mp4            # 对标专业 launch film 打分
earshot doctor --load                # 检查安装/模型/CPU 设置
```
- 单次 CLI 加载模型约 20-40s；多次调用改用 MCP server 或 Python API。
- sfx / kit / measure 不加载模型，速度快；describe / match / rank / timeline 需模型。

## 混音 ffmpeg 常用
```bash
ffmpeg -i bgm.mp3 -i sfx.wav -filter_complex "[0:a]volume=0.5[bg];[1:a]afade=t=in:st=0:d=0.2[sfx];[bg][sfx]amix=inputs=2:duration=longest[out]" -map "[out]" out.mp3
ffmpeg -i in.mp4 -i audio.mp3 -c:v copy -c:a aac -shortest out.mp4
```

## 本地素材库结构
```
~/Movies/dsh-sound-assets/
  bgm/        # CC0 背景音乐（一次性从可达源下载）
  ambience/   # 环境音（雨声/风声/街道）
  sfx/        # 转场/点击/撞击（优先 Earshot 生成）
  voice/      # 人声/旁白
  manifest.json   # 每个文件的来源、许可证、用途
```
- 许可证必须记录（CC0 / CC-BY / 商用授权）。
- Earshot 生成的音效无需许可证（代码合成）。

## 云端兜底（本机可达性实测）
| 源 | 用途 | 本机可达性 | 建议 |
|---|---|---|---|
| Earshot | 代码合成音效 | 本地 | 主力 |
| Freesound | 环境音/音效 | 200 | 一次性下载 |
| Sound Effect Lab | 日语检索音效 | 200 | 一次性下载 |
| ElevenLabs | 文字生成音效 | 200 | 唯一保留的生成类源 |
| GitHub | Earshot 仓库 | 200 | — |
| Pixabay Music | BGM | 403 反爬 | 浏览器/代理下载或换源 |
| Mixkit | 转场音效 | ~20s/请求 | 尽量用 Earshot 替代 |

## DSH 集成
- DSH 以子进程调用 earshot CLI，或接 earshot MCP server。
- 不需要安装 Claude Code。
- 与 media-use、hyperframes 串联成离线流水线。

## 标准工作流
1. earshot doctor --load 确认安装。
2. 选音效：earshot sfx list，或 earshot rank 查询候选文件。
3. 渲染：earshot kit render 按时间轴出音效，或 sfx render 单条。
4. 混音：ffmpeg 把 BGM + 音效 + 旁白合成。
5. 声画同步：earshot timeline film.mp4 校验。
6. 素材入库：下载的云端文件存入素材库并登记许可证。

## 注意
- Earshot 0.4.0 音效库为 252 种（旧资料写 201 已过时）。
- 系统 python3 为 3.7，Earshot 需要 ≥3.10；setup.sh 会找 3.10+ 的 Python。
- **PyPI 的 earshot 是无关 VAD 库，勿装**；从 GitHub 克隆。
- Pixabay/Mixkit 本机网络受限，不要作为运行时依赖。
