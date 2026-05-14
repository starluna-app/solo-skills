# 🚀 solo-skills

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![npm version](https://img.shields.io/badge/npm-v1.0.0-green.svg)

> **Out-of-the-box AI Skills and Agents tailored for Solopreneurs and Indie Hackers.**

[中文文档 (Chinese Documentation)](README.zh-CN.md)

`solo-skills` provides a suite of AI automation skills designed for independent creators. Whether it's competitor research, cross-platform copywriting, or Youtube channel planning, you can invoke them directly in your terminal or seamlessly integrate them into your favorite AI IDEs (Cursor, Windsurf) and AI CLI assistants (Claude Code, Gemini CLI).

## ✨ Core Features
* **⚡️ Zero Config**: No tedious setup; invoke instantly via `npx`.
* **🌍 Internationalization (i18n)**: English by default. Most skills have localized versions (e.g., `zh-CN`). AI agents will automatically pick the language based on your context.
* **🛠️ Solopreneur Focus**: Solves high-frequency pain points for solo founders (marketing, development, growth).
* **📖 Open Source**: Apache 2.0 license.

---

## 💻 Verified Tool Support

These skills are tested and verified to work seamlessly with the following AI agents:

- **Gemini CLI**
- **Claude Code**
- **Cursor**
- **Windsurf**
- **Aider**

*Note: If a tool is not listed here, it has not been officially tested. Please open an issue if you successfully integrate it elsewhere!*

---

## 📦 Installation & Uninstallation

### 1. Claude Code & Gemini CLI (Recommended)
You can directly add these skills to your local agent configuration.

**Install / Update:**
```bash
# For Gemini CLI
npx skills add starluna-app/solo-skills/skills/youtube-channel-planner

# For Claude Code (installing inside your project directory)
# Or manually copy the SKILL.md file to your .claude/skills/ directory.
```

**Uninstall:**
To remove a skill, simply delete its corresponding folder from your `~/.gemini/skills/` or `.claude/skills/` directory.

### 2. Standalone CLI Usage (Via npx)
You don't need to install anything globally. Just run it!
```bash
npx solo-skills
```


## 🧰 Available Skills Library

| Skill | Description | Use Case |
| :--- | :--- | :--- |
| `youtube-channel-planner` | AI-driven YouTube channel planning, leveraging NotebookLM to build high-density automated content pipelines. | Creator Economy & Monetization |
| `social-writer` | Converts core product updates into multi-platform copy (Reddit, X, IndieHackers, etc.). | Marketing & Community Growth |
| `market-research` | Given a niche, automatically retrieves and summarizes the latest competitor dynamics. | Early Idea Validation |
| `seo-optimizer` | Analyzes Markdown/HTML to extract long-tail keywords and optimize page structure. | SEO & Traffic |

---

## 💖 Sponsorship

If `solo-skills` has helped you save time, validate an idea faster, or generate revenue for your solo business, please consider sponsoring this project! Your support helps us maintain existing skills and research new automation workflows.

*   [Sponsor on GitHub 🌟](https://github.com/sponsors/starluna-app)

## 📄 License & Attribution

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

---
**Crafted by [StarLuna LLC](https://starluna.app)**
*Building next-generation tools and platforms for educational innovation and independent creators.*