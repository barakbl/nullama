# Nu Shell Skills and Commands

Claude Code slash commands that turn any POSIX CLI tool into structured Nushell commands — automatically.

## How It Works

```
CLI tool  ──>  TOML spec  ──>  Nushell `def` blocks
         /nu_create_toml_    /to_nu
         from_posix_command
```

1. Point `/nu_create_toml_from_posix_command` at any CLI tool — it reads `--help`, asks what you want, and writes a TOML spec.
2. Point `/to_nu` at that TOML — it generates ready-to-paste Nushell `def` blocks that wrap each subcommand with structured output.

## Commands

### `/to_nu <path-to-toml>`

Reads a TOML spec file and generates Nushell `def` blocks that wrap a CLI tool's subcommands, parsing their text output into structured tables.

**Usage:**

```
/to_nu examples/docker/docker.toml
```

**What it generates:**

- Nushell `def` blocks with proper flag signatures (bool and typed string flags with defaults)
- Automatic output parsing: tabular detection, simple format patterns, or raw passthrough
- Stderr capture for tools that write to stderr (e.g. `docker logs`)
- Streaming mode support — follow flags stream raw, non-follow parses into tables
- Header sanitization (`CONTAINER ID` -> `container_id`)

**TOML schema fields:**

| Field | Description |
|---|---|
| `cli_command` | The CLI tool to wrap (e.g. `"docker"`) |
| `cli_new_command` | Nu command name prefix (e.g. `"nudocker"`) |
| `args` | Subcommand + fixed args |
| `flags` | Flags to expose (long, short, type, description) |
| `positional_args` | Positional parameters |
| `parse_helper` | Hint for output parsing (tabular, streaming, etc.) |
| `parse_format` | Simple parse pattern with `{column}` placeholders (preferred) |
| `parse_pattern` | Regex parse pattern (avoid — angle brackets cause issues) |
| `columns` / `delimiter` | Explicit column names and delimiter |
| `column_types` | Type coercion per column |
| `stderr` | Set `true` if output comes from stderr |
| `follow_flag` | Bool flag name that enables streaming mode |
| `reverse` | Reverse row order |

### `/nu_create_toml_from_posix_command <command>`

Inspects a POSIX CLI tool and generates a TOML spec file for `/to_nu`.

**Usage:**

```
/nu_create_toml_from_posix_command docker
/nu_create_toml_from_posix_command kubectl
/nu_create_toml_from_posix_command openfang
```

**What it does:**

1. Runs `<command> --help` to discover subcommands and flags
2. Asks whether you want **full** (all subcommands) or **specific** (pick which ones)
3. Asks whether to include **all flags** or **most common** only
4. Inspects each selected subcommand's `--help` for detailed flag info
5. Writes `<command>.toml` to the current directory

**Output:** A TOML file ready for `/to_nu`.

## Examples

### Docker

```
/nu_create_toml_from_posix_command docker
# -> creates docker.toml

/to_nu examples/docker/docker.toml
# -> generates nudocker ps, nudocker images, nudocker logs
```

Then in Nushell:

```nushell
# Structured table output
nudocker ps --all | where status =~ "Up"
nudocker images | sort-by size

# Logs with level parsing
nudocker logs --tail 50 my-container | where level == "ERROR"

# Streaming mode
nudocker logs -f my-container
```

## Nushell Compatibility Notes

- String flags must have `= ""` defaults to avoid `missing_flag_param` parser errors
- Use `parse "{col}"` (simple format) instead of `parse --regex` with named groups — angle brackets in regex cause parser issues
- Use `detect columns --guess` for tabular output with multi-word headers
- Use `complete` to capture stderr output, then concatenate `stdout + stderr`

## Installation

These are [Claude Code slash commands](https://docs.anthropic.com/en/docs/claude-code). Clone this repo and the commands in `.claude/commands/` will be available when you run Claude Code from this directory.

```bash
git clone git@github.com:barakbl/nu_shell_skills_and_commands.git
cd nu_shell_skills_and_commands
# Commands are now available as /to_nu and /nu_create_toml_from_posix_command
```

## License

See [LICENSE](LICENSE).
