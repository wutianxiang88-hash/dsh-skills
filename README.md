# DSH Skills

A curated collection of reusable [DeepSeek Harness](https://github.com/) agent skills (`SKILL.md` packages). Each directory under `skills/` is a self-contained skill that can be dropped into a DSH skills folder.

## Skills (8)

| Skill | What it does |
|-------|-------------|
| `engineering-workflow` | 工程化工作流总纲：五阶段硬门（需求→计划→TDD→验证→交付） |
| `workflow-requirements` | 需求澄清：把创造性与实现工作先问清楚再动手 |
| `workflow-planning` | 计划审批：把规格/需求写成可执行的计划 |
| `workflow-subagents` | 子 Agent 并行执行：按任务派发与汇总 |
| `workflow-tdd` | TDD 实现：测试先行地实现功能或修复缺陷 |
| `workflow-verification` | 验证收尾：宣称完成/修复/通过前先跑证据 |
| `modsearch` | 插件化网页搜索、X(Twitter) 搜索与页面读取（多引擎、可配置、中英文参考文档） |
| `local-sound-pipeline` | 本地优先声音流水线：Earshot 本地合成 + ffmpeg 混音 + 云端兜底 |

## Install

Copy any `skills/<name>/` directory into your DSH skills directory. Skills with YAML frontmatter (`name`, `description`) are auto-discovered and triggered by the Use-when description; see each `SKILL.md` for when it activates.

## License / provenance

Each skill keeps its own files. Workflow skills are Chinese-language engineering-workflow presets; `modsearch` ships bilingual reference docs; `local-sound-pipeline` is a standalone sound-design playbook. No secrets, personal paths, or credentials are included — any keys shown in docs are placeholders.
