# ollama-launcher

[![Author](https://img.shields.io/badge/Author-Shibu-blue)](https://github.com/sb-codz)
[![GitHub](https://img.shields.io/badge/GitHub-sb--codz-181717?logo=github)](https://github.com/sb-codz)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.3%2B-green)](https://www.gnu.org/software/bash/)

> [!WARNING]
> **Unofficial Project — Use at Your Own Risk** 
> * *Not fully Tested*
> 
> This tool is **not affiliated with Ollama, Anthropic, OpenAI, Microsoft, or any other company**.  
> By using this software, you agree to:  
> • Comply with all third-party Terms of Service and API policies  
> • Assume full responsibility for costs, data usage, and legal compliance  
> • Hold the author(s) harmless for any damages or losses  
> 
> 📄 Read the full [DISCLAIMER](DISCLAIMER.md) and [LICENSE](LICENSE) before use.

A powerful, categorized terminal launcher for Ollama models and AI coding applications. Built for developers who want a unified, menu-driven interface to launch local and cloud-hosted LLMs with their preferred coding tools.

## ✨ Features

- 🗂️ **Categorized Model Selection**: Browse 50+ models grouped by family (Qwen, GLM, Gemma, etc.)
- 🔐 **Mandatory Cloud Auth**: Enforces `ollama signin` before first cloud model usage
- 🔄 **Cloud & Local Support**: Seamless routing for `:cloud` models via Ollama API
- 🧰 **Multi-App Integration**: Launch with `ollama`, `claude`, `codex`, `opencode`, `droid`, or `vscode`
- ⌨️ **Intuitive TUI Menu**: Arrow-key navigation with visual category headers
- 💾 **Persistent Config**: Remembers your last model/app selection
- 🛡️ **Safe Execution**: `set -euo pipefail`, proper signal trapping, and cleanup
- 📱 **Android Ready**: Tested in XedEditor environments

## ☁️ Cloud Model Requirements & First-Time Setup

Models with the `:cloud` suffix are routed through Ollama's remote inference API. **An Ollama account is mandatory.**

1. **Create an account**: Visit [https://ollama.com/signup](https://ollama.com/signup)
2. **Authenticate via CLI**: Run `ollama signin` in your terminal
3. **Complete verification**: Follow the browser/terminal prompts to link your device
4. **Confirm token**: The launcher auto-detects `~/.ollama/apikey` or `OLLAMA_API_KEY`

> 🔒 **Security**: This script does not transmit, store, or log your Ollama credentials. Authentication is handled exclusively by the official Ollama CLI.

## ⚡ Quick Start

### Prerequisites
- Bash ≥ 4.3
- `curl`, `git`
- Ollama installed
- For cloud models: `ollama signin` + valid account

### Installation
```bash
git clone https://github.com/sb-codz/ollama-launcher
cd ollama-launcher
chmod +x ollama_launcher.sh
```

### Run
```bash
./ollama_launcher.sh
```

## ⚖️ Legal

- This is an **unofficial community project**.
- All trademarks and product names are property of their respective owners.
- Users are responsible for compliance with Ollama, model provider, and application terms of service.
- No warranty is provided; use at your own risk.
- See [`DISCLAIMER.md`](DISCLAIMER.md) and [`LICENSE`](LICENSE) for full details.

> **Made with ❤️ by Shibu ([@sb-codz](https://github.com/sb-codz))**  
> *Empowering developers to harness AI, one terminal at a time.*