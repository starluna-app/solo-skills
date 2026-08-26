# 🚀 solo-skills

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![npm version](https://img.shields.io/badge/npm-v1.0.0-green.svg)

> **Out-of-the-box AI Skills and Agents tailored for Solopreneurs, Indie Hackers, and Mobile Developers.**

`solo-skills` provides a battle-tested suite of AI automation skills designed for independent creators and agile engineering teams. Whether it's competitor research, cross-platform copywriting, iOS release pipelines, image asset preparation, or brand identity design, you can invoke them directly in your terminal or seamlessly integrate them into your favorite AI IDEs (Cursor, Windsurf) and AI CLI assistants (Antigravity, Gemini CLI, Claude Code).

## ✨ Core Features
* **⚡️ Zero Config**: No tedious setup; invoke instantly via `npx` or point your AI agent directly to `skills/`.
* **🌍 English First**: Optimized for English language context and global developer standards.
* **🛠️ Solopreneur & Mobile Focus**: Solves high-frequency pain points for solo founders (marketing, development, App Store release, growth).
* **🔒 Security & Safety First**: Zero hardcoded secrets, prompt-first confirmation gates, and non-destructive defaults.
* **📖 Open Source**: Apache 2.0 license.

---

## 💻 Verified Tool Support

These skills are tested and verified to work seamlessly with:

- **Google Antigravity & Gemini CLI**
- **Claude Code**
- **Cursor**
- **Windsurf**
- **Aider**

---

## 📦 Installation & Usage

### 1. Claude Code & Gemini CLI / Antigravity
Point your agent directly to the `skills/` directory or add specific skills:

```bash
# Add a specific skill to Gemini / Antigravity
npx skills add starluna-app/solo-skills/skills/sl-ios-app-store-release

# Or clone the repository and point your agent settings to the /skills folder.
```

### 2. Standalone CLI Usage (Via npx)
Run the CLI to inspect available skills:
```bash
npx solo-skills
```

---

## 🧰 Available Skills Library

| Skill | Description | Use Case |
| :--- | :--- | :--- |
| `brand-voice-architect` | Interactive QA to define core company values, mission, archetype, and AI tone/voice system instructions (`BRAND_GUIDELINES.md`). | Brand Identity & AI Copy Tuning |
| `copywriting-genius` | Transforms dry technical features into high-converting marketing copy applying proven frameworks (AIDA, PAS). | Landing Pages & Cold Outreach |
| `founder-social-scout` | Leverages CLI tools across X/Twitter, Reddit, and Hacker News to monitor brand mentions, discover pain points, and analyze competitors. | Social Listening & Market Research |
| `growth-hack-ideator` | Uncovers non-traditional, high-leverage distribution channels and zero-budget guerrilla marketing tactics. | Cold Start & Customer Acquisition |
| `karpathy-guidelines` | Operational rules and extensions based on Andrej Karpathy's coding principles to prevent LLM over-engineering and encourage surgical edits. | Code Quality & Refactoring |
| `auto-pr-merger` | Systematically checks out open PRs, rebases on `main`, runs lint/tests, and merges passing pull requests. | Automated Git Maintenance |
| `image-to-pdf` | Losslessly converts single or multiple images into a multi-page PDF with natural file sorting and zero rasterization degradation. | Document & Asset Generation |
| `ios-asset-prep` | Image pipeline for iOS: PNG → HEIC batch compression, and AI alpha-channel cutout using `rembg` + `BiRefNet` for translucent icons. | iOS Bundle & Asset Catalog Prep |
| `ios-cache` | Production caching strategies for SwiftUI: duplicate request prevention, offline fallbacks, user partition, and post-mutation sync. | iOS Architecture & Performance |
| `app-store-screenshot-polisher` | Converts raw iPhone screenshots into App Store 6.9" marketing assets with tasteful typography and calm backgrounds. | ASO & App Store Marketing |
| `official-resource-image-pipeline` | Prompt-first workflow for creating, approving, versioning, and deploying official printable and visual app resources. | Content & Resource Generation |
| `sl-ios-app-store-release` | End-to-end 7-phase iOS App Store release workflow: gated pre-flight checks, `asc` CLI automation, archive, export, and review submission. | iOS App Store Shipping |
| `sl-ios-release-flow` | Safety-gated build shipping: blocker reviews, backend deployment verification, and TestFlight upload. | Continuous iOS Delivery |
| `local-drive-clean` | Safely identifies and purges developer disk bloat (XCTestDevices, DerivedData, old Simulator runtimes, package caches). | macOS Disk Space Recovery |
| `market-research` | Researches target industries, analyzes competitors, and outputs structured market gap reports. | Idea Validation & Strategy |
| `social-writer` | Converts changelogs and product updates into tailored copy for Reddit, X/Twitter, and Indie Hackers. | Community Marketing |
| `youtube-channel-planner` | End-to-end planning for automated, high-density educational and product YouTube channels. | Video & Content Marketing |

---

## 💖 Sponsorship & Attribution

If `solo-skills` helps you ship faster, validate ideas, or automate tedious workflows, please consider starring and supporting the project!

* [Sponsor on GitHub 🌟](https://github.com/sponsors/starluna-app)

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

---
**Crafted with ❤️ by [StarLuna LLC](https://starluna.app)**