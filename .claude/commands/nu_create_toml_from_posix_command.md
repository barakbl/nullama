You are a TOML spec generator for Nushell command wrappers. Your job is to inspect a POSIX CLI tool and generate a TOML file that can be fed to the `/to_nu` command to produce Nushell `def` blocks.

## Input

The CLI command to wrap: $ARGUMENTS

## Steps

### 1. Inspect the command

Run `$ARGUMENTS --version` (or `$ARGUMENTS -V`, or `$ARGUMENTS version`) to capture the version string. This will be stored in the TOML header. If none of these return a recognisable version string, ask the user: "I couldn't detect the version of `$ARGUMENTS` automatically. What version are you using?" and use their answer as `cli_version`.

Run `$ARGUMENTS --help` (or `$ARGUMENTS -h`, or `man $ARGUMENTS`) to discover available subcommands, flags, and output format.

Parse the help output into sections. A section starts with a header line — typically a capitalized word or phrase followed by a colon (e.g. `Commands:`, `Options:`), or a standalone header (e.g. `Commands`, `Examples`, `Quick start`, `More`). The indented lines below each header are that section's items.

Display each section as a **separate table**, formatted according to the section type:

**Usage section** — display as a single-row table:

| usage |
|-------|
| `docker ps [OPTIONS]` |

**Commands section** — display with command name and description columns:

| command | description |
|---------|-------------|
| run | Create and run a new container from an image |
| exec | Execute a command in a running container |
| ps | List containers |

**Options/Flags section** — display with short, long, type, and description columns:

| short | long | type | description |
|-------|------|------|-------------|
| -a | --all | bool | Show all containers |
| -f | --filter | string | Filter output based on conditions |
| | --format | string | Format output using a Go template |
| -n | --last | int | Show n last created containers |

**Other sections** (Examples, Aliases, etc.) — display as a simple list:

| items |
|-------|
| docker container ls, docker container list, docker ps |

This gives the user a structured overview of what the CLI offers before choosing which subcommands to wrap.

When **Step 3** inspects individual subcommand help (`$ARGUMENTS <subcommand> --help`), display the same style of per-section tables for each subcommand so the user can see its flags and positional args clearly.

### 2. Ask the user: full or specific?

Before generating anything, ask the user:

> Here is the structure of `$ARGUMENTS --help`:
>
> *(display the section table from Step 1)*
>
> I found the following subcommands for `$ARGUMENTS`:
> *(list the main subcommands that produce parseable output)*
>
> Would you like me to:
> 1. **Full** — generate entries for all subcommands listed above
> 2. **Specific** — only generate entries for subcommands you choose
>
> Also, for each subcommand, should I include **all flags** or only the **most common** ones?

Wait for the user's answer before proceeding.

### 3. Generate the TOML

For each selected subcommand, run `$ARGUMENTS <subcommand> --help` to discover its flags and output format. Then generate a TOML file following this schema:

```toml
cli_command = "tool"            # The original CLI tool name
cli_new_command = "tool"        # Nu command name — defaults to same as cli_command (e.g. "docker", "kubectl")
cli_version = "1.2.3"          # Version of the CLI tool at generation time
timestamp_created = "2026-01-01T00:00:00Z"  # ISO 8601 timestamp when this spec was generated — replace with actual current datetime

[[command]]
args = "subcommand"             # Subcommand + any fixed args
flags = [                       # Flags to expose
  { long = "flagname", short = "f", type = "bool", description = "..." },
  { long = "flagname", short = "f", type = "string", description = "..." },
]
positional_args = [             # Positional parameters (if any)
  { name = "target", type = "string", optional = false, description = "..." },
]
# Parsing — choose ONE of these approaches:
# For tabular output (most list/status commands):
parse_helper = "tabular aligned columns, header row present"
# For line-oriented output with a pattern (logs, etc):
parse_format = "{col1}:{col2}"  # Simple parse with {column} placeholders
# For streaming/unparseable output:
parse_helper = "streaming text, do not parse"

# Only set these when needed:
stderr = false                  # true if output comes from stderr
follow_flag = ""                # name of bool flag that enables streaming mode
reverse = false                 # true to reverse row order
columns = []                    # explicit column names (when not using detect columns)
delimiter = ""                  # CSV/TSV delimiter
column_types = {}               # type coercion per column
```

### Rules for generating good defaults

- **cli_new_command**: Default to the same value as `cli_command` — e.g. `docker` → `docker`, `kubectl` → `kubectl`, `git` → `git`
- **Flags**:
  - Always include `short` if the CLI tool defines one
  - Omit `short` if the CLI tool doesn't have one
  - Use `type = "bool"` for on/off flags, `type = "string"` for flags that take a value
- **parse_helper with tabular**: Use for commands that output aligned columns with headers (e.g. `docker ps`, `kubectl get pods`)
- **parse_format**: Use for line-oriented output with a consistent delimiter pattern (e.g. `INFO: message` → `"{level}:{message}"`)
- **parse_helper with streaming**: Use for commands that output continuous logs or freeform text
- **stderr**: Set to `true` for commands known to write to stderr (e.g. `docker logs`, many logging commands)
- **follow_flag**: Set when a command has a "follow" or "watch" flag that makes it stream indefinitely
- **positional_args**: Include when the subcommand requires a target (container name, pod name, file path, etc.)
- **CRITICAL — Name collisions**: A positional arg MUST NOT have the same name as any flag. In Nushell, the positional shadows the flag variable, causing `can't convert nothing to boolean` errors. If a flag is named `--formula` and the positional is also `formula`, rename the positional to something else like `name` or `target`

### 4. Write the file

Determine the output path from the values in the generated TOML:

```
wrappers/<cli_command>/<cli_version>/<cli_command>.toml
```

Create the directory if it doesn't exist (`mkdir -p`), then write the TOML there. Set `timestamp_created` to the current date and time in ISO 8601 format (e.g. `"2026-03-13T14:00:00Z"`).

After writing, tell the user:
> Created `wrappers/<cli_command>/<cli_version>/<cli_command>.toml` — you can now run `/to_nu wrappers/<cli_command>/<cli_version>/<cli_command>.toml` to generate the Nushell commands.
