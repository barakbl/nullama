# 🐚 Generate Nushell `def` Commands from POSIX CLI Tools

> Point it at any CLI tool — get structured, tab-completing Nushell commands back. Automatically.

---

**[Nushell](https://www.nushell.sh/)** is a modern shell that treats data as structured tables instead of plain text. Pipelines output real columns, types, and records — making filtering, sorting, and transforming data feel like querying a database rather than wrangling strings.

**This project** provides [Claude Code](https://docs.anthropic.com/en/docs/claude-code) slash commands that read any POSIX CLI tool's `--help`, generate a TOML spec, and produce ready-to-use Nushell `def` blocks with structured output parsing.

> ⚠️ **Disclaimer** — This project is **not affiliated with, endorsed by, or associated with** the Nushell project. It is an independent community tool.

---

## ⚡ How It Works

```
CLI tool  ──▶  TOML spec  ──▶  Nushell def blocks
         /nu_create_toml_      /to_nu
         from_posix_command
```

1. **`/nu_create_toml_from_posix_command <tool>`** — inspects `--help`, asks what you want, writes a TOML spec
2. **`/to_nu <spec.toml>`** — reads the spec and generates Nushell commands with structured output

---

## 🚀 Quick Start

```bash
git clone git@github.com:barakbl/nullama.git
cd nullama
# Slash commands are now available when running Claude Code from this directory
```

### Generate and use in two steps

```
/nu_create_toml_from_posix_command docker
/to_nu docker.toml
```

```nushell
nudocker ps --all | where status =~ "Up"
nugit log --max-count 10 | where author == "Alice"
```

### Loading into Nushell

After generating a `.nu` file, you have several ways to use it:

**Option 1 — Source it in your current session:**

```nushell
source brew.nu
```

**Option 2 — Add it permanently to your Nushell config:**

```nushell
# Append the generated file to your config
open brew.nu | save --append $nu.config-path
```

**Option 3 — Source from a dedicated directory:**

```nushell
# Copy to a commands directory
mkdir ~/.config/nushell/commands
cp brew.nu ~/.config/nushell/commands/

# Add this line to your config.nu to auto-load on startup
"source ~/.config/nushell/commands/brew.nu" | save --append $nu.config-path
```

**Option 4 — Fetch and load directly from GitHub (no clone needed):**

```nushell
# Load a pre-built example straight into your session
http get https://raw.githubusercontent.com/barakbl/nullama/main/wrappers/brew/brew.nu | save brew.nu
source brew.nu

# Or append it to your config in one go
http get https://raw.githubusercontent.com/barakbl/nullama/main/wrappers/brew/brew.nu | save --append $nu.config-path
```

---

## 📖 Commands

### `/nu_create_toml_from_posix_command <command>`

Inspects a POSIX CLI tool and generates a TOML spec file.

**What it does:**

1. Runs `<command> --help` to discover subcommands and flags
2. Asks whether you want **all subcommands** or **specific ones**
3. Asks whether to include **all flags** or **most common** only
4. Inspects each selected subcommand's `--help` for detailed flag info
5. Writes `<command>.toml` to the current directory

### `/to_nu <path-to-toml>`

Reads a TOML spec and generates Nushell `def` blocks that wrap each subcommand with structured output parsing.

> 💡 **No TOML yet?** If the file doesn't exist, `/to_nu` will detect this and offer to create it for you automatically by running `/nu_create_toml_from_posix_command` — so you can go straight from `/to_nu docker.toml` without generating the spec first.

**What it generates:**

- A base command with `--info (-i)` that returns the tool's help as a structured table
- Pass-through for unwrapped subcommands (`nutool doctor` → `tool doctor`)
- Nushell `def` blocks with proper flag signatures
- **Tab completion** — because the wrappers are proper `def` blocks, Nushell automatically provides tab completion for all flags and subcommands. Press `Tab` after `nudocker` to see all subcommands; press `Tab` after `--` to complete flags
- Automatic output parsing: tabular detection, format patterns, or raw passthrough
- Safe output capture via `complete` with null-safe field access and empty-output guard
- Stderr capture for tools that write to stderr (e.g. `docker logs`)
- Streaming mode — follow flags stream raw, non-follow parses into tables
- Header sanitization (`CONTAINER ID` → `container_id`)

---

## 💡 Usage Examples

### Structured help for any wrapped tool

Every generated wrapper includes `--info (-i)` that returns the tool's help as a filterable table:

```nushell
nubrew -i
```

```
╭────┬──────────────────┬─────────────────────────────────────────────┬─────────────╮
│  # │     section      │                   command                   │ description │
├────┼──────────────────┼─────────────────────────────────────────────┼─────────────┤
│  0 │ Example usage    │ brew search TEXT|/REGEX/                    │             │
│  1 │ Example usage    │ brew info [FORMULA|CASK...]                 │             │
│  2 │ Troubleshooting  │ brew config                                 │             │
│  3 │ Troubleshooting  │ brew doctor                                 │             │
│  4 │ Further help     │ brew commands                               │             │
╰────┴──────────────────┴─────────────────────────────────────────────┴─────────────╯
```

```nushell
# Filter help by section
nubrew -i | where section == "Troubleshooting"

# Unwrapped subcommands pass through directly
nubrew doctor
nubrew update
```

### Tab completion — out of the box

Because the wrappers are native Nushell `def` blocks, **tab completion works automatically** for every generated command — no extra configuration needed:

```nushell
nudocker <Tab>        # shows: ps, images, logs, stats, top, events, port, version, info, history, inspect, diff
nudocker ps --<Tab>   # shows: --all, --filter, --format, --last, --latest, --no-trunc, --quiet, --size
nugit log --<Tab>     # shows: --all, --graph, --author, --since, --until, --grep, --max-count
nuzero <Tab>          # shows: status, providers, models, memory, doctor, config, ...
```

This works in any Nushell-compatible editor or terminal — no shell-specific completion scripts to install.

### Docker — filter running containers

```nushell
nudocker ps --all | where status =~ "Up"
```

```
╭───┬──────────────┬───────────┬─────────┬────────────────┬───────────┬───────────────────┬───────╮
│ # │ container_id │   image   │ command │    created     │  status   │      ports        │ names │
├───┼──────────────┼───────────┼─────────┼────────────────┼───────────┼───────────────────┼───────┤
│ 0 │ a1b2c3d4e5f6 │ nginx     │ …       │ 2 hours ago    │ Up 2 hours│ 0.0.0.0:80->80/tcp│ web   │
│ 1 │ f6e5d4c3b2a1 │ postgres  │ …       │ 3 hours ago    │ Up 3 hours│ 5432/tcp          │ db    │
╰───┴──────────────┴───────────┴─────────┴────────────────┴───────────┴───────────────────┴───────╯
```

### Docker — sort images by size

```nushell
nudocker images | sort-by size
```

### Docker — search error logs

```nushell
nudocker logs --tail 50 my-container | where line =~ "ERROR"
```

### Brew — list outdated packages

```nushell
nubrew outdated --verbose
```

### Brew — search and inspect

```nushell
nubrew search --formula "rust"
nubrew info rustup | where key == "From"
```

### Brew — services as structured table

```nushell
nubrew services
```

```
╭───┬──────────┬─────────┬──────┬─────────────────────╮
│ # │   name   │ status  │ user │        file         │
├───┼──────────┼─────────┼──────┼─────────────────────┤
│ 0 │ nginx    │ started │ root │ /Library/Launch…    │
│ 1 │ postgres │ started │ barak│ ~/Library/Launch…   │
╰───┴──────────┴─────────┴──────┴─────────────────────╯
```

### Pip — find outdated packages

```nushell
nupip list --outdated | sort-by version
```

### Pip — freeze to structured records

```nushell
nupip freeze | where package =~ "request"
```

```
╭───┬──────────┬─────────╮
│ # │ package  │ version │
├───┼──────────┼─────────┤
│ 0 │ requests │ 2.31.0  │
╰───┴──────────┴─────────╯
```

---

## 📂 Wrappers

| Tool | TOML Spec | Generated `.nu` | Subcommands |
|------|-----------|------------------|-------------|
| 🐳 Docker | [`docker.toml`](wrappers/docker/docker.toml) | [`docker.nu`](wrappers/docker/docker.nu) | ps, images, logs, stats, top, events, port, version, info, history, inspect, diff |
| 🍺 Homebrew | [`brew.toml`](wrappers/brew/brew.toml) | [`brew.nu`](wrappers/brew/brew.nu) | list, info, search, outdated, deps, services |
| 📦 pip | [`pip.toml`](wrappers/pip/pip.toml) | [`pip.nu`](wrappers/pip/pip.nu) | list, show, freeze, install, check |
| 🐍 Python | [`python.toml`](wrappers/python/python.toml) | [`python.nu`](wrappers/python/python.nu) | version, eval, module |
| 🐙 Git | [`git.toml`](wrappers/git/git.toml) | [`git.nu`](wrappers/git/git.nu) | log, status, branch, diff, remote, stash, tag, show |
| 🦀 ZeroClaw | [`zeroclaw.toml`](wrappers/zeroclaw/zeroclaw.toml) | [`zeroclaw.nu`](wrappers/zeroclaw/zeroclaw.nu) | status, providers, models list/status, memory list/stats, doctor, config |
| 📷 OpenFang | [`openfang.toml`](wrappers/openfang/openfang.toml) | [`openfang.nu`](wrappers/openfang/openfang.nu) | status, agent list, skill list/search, channel list, models, sessions, logs, health, doctor, config |

---

## 📋 TOML Spec Reference

| Field | Description |
|---|---|
| `cli_command` | The CLI tool to wrap (e.g. `"docker"`) |
| `cli_new_command` | Nu command name prefix (e.g. `"nudocker"`) |
| `args` | Subcommand + fixed args |
| `flags` | Flags to expose (long, short, type, description) |
| `positional_args` | Positional parameters |
| `parse_helper` | Hint for output parsing (tabular, streaming, etc.) |
| `parse_format` | Simple parse pattern with `{column}` placeholders |
| `columns` / `delimiter` | Explicit column names and delimiter |
| `column_types` | Type coercion per column |
| `stderr` | Set `true` if output comes from stderr |
| `follow_flag` | Bool flag name that enables streaming mode |
| `reverse` | Reverse row order |

---

## 🎯 `parse_helper` Guide

The `parse_helper` field tells `/to_nu` how to parse the CLI tool's output into structured data. It's a free-text hint — the generator reads it and picks the right Nushell parsing strategy. Here are the recognized patterns and what they produce:

### Tabular output → `detect columns --guess`

For commands that print aligned columns with a header row (like `docker ps`, `brew services`).

```toml
parse_helper = "tabular aligned columns, header row present"
# With multi-word headers:
parse_helper = "tabular aligned columns, header row present, headers have spaces (e.g. CONTAINER ID)"
```

**Generated Nushell:**
```nushell
run-external docker ps | detect columns --guess
| rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
# CONTAINER ID → container_id, MEM USAGE → mem_usage
```

### Key-value output → `parse "{key}: {value}"`

For commands that print `key: value` pairs (like `docker version`, `pip show`).

```toml
parse_helper = "key-value pairs, colon-separated"
# Variants:
parse_helper = "key-value pairs, colon-separated, nested sections"
parse_helper = "key-value pairs, colon-separated (RFC-compliant mail header format)"
parse_helper = "key-value pairs, TOML format"
```

**Generated Nushell:**
```nushell
run-external docker version
| lines | each {|line| $line | parse "{key}: {value}" } | flatten
| update key { str trim } | update value { str trim }
```

### Line-oriented output → `lines | enumerate`

For commands that output one item per line without a table structure (like logs, search results, dependency lists).

```toml
parse_helper = "line-oriented text, each line is a log entry"
# Variants:
parse_helper = "line-oriented text, one package per line"
parse_helper = "line-oriented text, one result per line"
parse_helper = "line-oriented text, dependency compatibility check output"
```

**Generated Nushell:**
```nushell
run-external brew search "rust"
| lines | enumerate | flatten | rename index line
```

### JSON output → `from json`

For commands that return JSON (like `docker inspect`).

```toml
parse_helper = "JSON output, parse with from json"
# Variants:
parse_helper = "key-value pairs or JSON output"
```

**Generated Nushell:**
```nushell
run-external docker inspect my-container | from json
```

### Streaming / raw output → no parsing

For commands whose output should not be parsed (like `docker events`, `pip install` progress).

```toml
parse_helper = "streaming text, do not parse"
```

**Generated Nushell:**
```nushell
run-external docker events  # raw output, no pipe
```

### Custom format → `parse_format`

When none of the above fit, use `parse_format` instead of `parse_helper` for explicit patterns:

```toml
parse_format = "{package}=={version}"
# or
parse_format = "{private_port} -> {public_addr}"
```

**Generated Nushell:**
```nushell
run-external pip3 freeze | parse "{package}=={version}"
run-external docker port web | parse "{private_port} -> {public_addr}"
```

---

## 🔧 Nushell Compatibility Notes

- **`--help` is reserved** — Nushell intercepts `--help (-h)` before your code runs. Use `--info (-i)` instead for custom help
- **Null-safe output capture** — `complete` can return `null` for stdout/stderr; always use `($result.stdout? | default "") + ($result.stderr? | default "")`
- **Empty output guard** — commands that return no output need `if ($raw | str trim | is-empty) { return [] }` before parsing
- **Name collisions** — a positional arg must not share a name with a flag (e.g. `--formula` + `formula?`); the positional shadows the flag variable
- String flags must have `= ""` defaults to avoid `missing_flag_param` parser errors
- Use `parse "{col}"` (simple format) instead of `parse --regex` with named groups — angle brackets in regex cause parser issues
- Use `detect columns --guess` for tabular output with multi-word headers

---

## 📄 License

See [LICENSE](LICENSE).
