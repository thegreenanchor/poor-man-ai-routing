# Installing Codex CLI and Gemini CLI

Both are required for the routing system to work. Both are Node-based.

## Prerequisites

- Node.js 20 or newer
- npm 10 or newer

Check:
```bash
node --version
npm --version
```

If missing, install Node.js from https://nodejs.org or via your package manager.

---

## Codex CLI

### Install

```bash
npm install -g @openai/codex
```

Verify:
```bash
codex --version
```

### Authenticate

```bash
codex auth
```

Follow prompts. You'll need an OpenAI API key with access to the Codex models, OR ChatGPT Plus/Pro/Team for the bundled access.

Once authed, the CLI stores credentials in `~/.codex/`. The `cdx` and `cx` wrappers then work without further setup.

### Configuration

Optional `~/.codex/config.toml`:

```toml
[default]
model = "gpt-5"
sandbox = "workspace-write"
ask_for_approval = "never"
```

The wrapper passes flags explicitly, so config is optional.

### Test

```bash
codex exec --sandbox workspace-write --ask-for-approval never "Print hello"
```

After installing this routing system, verify the Codex wrappers:

```bash
ai-mode status
cx --help
cdx "GOAL: Print hello. RETURN: STATUS only."
```

---

## Gemini CLI

### Install

```bash
npm install -g @google/gemini-cli
```

Verify:
```bash
gemini --version
```

### Authenticate

Two options:

**Option A: Personal Google account**
```bash
gemini auth
```

Opens browser for OAuth. Credentials stored in `~/.gemini/`.

**Option B: API key**
```bash
export GEMINI_API_KEY="your-key-here"
# Add to ~/.bashrc or ~/.zshrc to persist
```

Get a key at https://aistudio.google.com/apikey.

### Configuration

Optional `~/.gemini/settings.json`:

```json
{
  "model": "gemini-2.5-pro",
  "yolo": false,
  "tools": ["search", "browse", "image"]
}
```

The `gca` wrapper sets `--yolo` per call, so global yolo isn't necessary.

### Test

```bash
gemini -p "What's the capital of France?"
```

---

## Windows-specific notes

### Native PowerShell

Both CLIs work in PowerShell directly. Make sure npm's global bin is on your PATH:

```powershell
$env:PATH += ";$(npm prefix -g)"
```

Or permanently:
```powershell
[Environment]::SetEnvironmentVariable('Path', "$([Environment]::GetEnvironmentVariable('Path','User'));$(npm prefix -g)", 'User')
```

### WSL2 / Kali

Install Node.js inside WSL (don't rely on Windows-side Node.js):

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt-get install -y nodejs
```

Then proceed with the Codex/Gemini installs above.

### Git Bash

Use the npm install from Git Bash directly. The binaries land under `~/.npm-global/` or your npm prefix.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `npm install -g` permission denied | Use a user-scoped npm prefix: `npm config set prefix ~/.npm-global` then add `~/.npm-global/bin` to PATH. Avoid sudo. |
| `codex` not found after install | npm prefix not on PATH. `npm prefix -g` to find it; add `<prefix>/bin` to PATH. |
| `gemini auth` fails on WSL | Browser callback hits localhost; if browser is on Windows, use API key auth instead. |
| Codex models unavailable | API key tier doesn't have access. Upgrade plan or wait for rollout. |
| Gemini rate-limit errors | Free tier limits. Pro tier or paid API key resolves. |

---

## After installation

Run the routing system installer (see top-level `README.md`):

```bash
./INSTALL.sh   # or INSTALL.ps1 on Windows
```

It verifies both CLIs are installed and reports back.

After installation, start a Codex-led session with:

```bash
ai-mode codex
cx
```

When you want Claude to orchestrate the session:

```bash
ai-mode claude
```

The global mode file lives at `~/.claude/.ai-routing/mode` unless `AI_ROUTING_HOME` is set.

End a Codex session with:

```bash
ai-session-save
```

In connected Codex sessions, this saves local session logs and writes the Obsidian wiki session log in one closeout step.
