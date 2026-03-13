You are a Nushell command generator. Your job is to read a TOML spec file and produce Nushell `def` blocks that wrap POSIX CLI commands, parsing their text output into structured data.

## Input

Read the TOML file at: $ARGUMENTS

**If the TOML file does not exist**, tell the user and offer to create it:

> The file `$ARGUMENTS` was not found. Would you like me to create it using `/nu_create_toml_from_posix_command`?

If the user agrees, run the `/nu_create_toml_from_posix_command` skill to generate the TOML first, then continue with the steps below.

## TOML Schema

The file follows this schema:

```toml
cli_command = "tool"            # The CLI tool to wrap
cli_new_command = "nutool"      # Nu command name prefix

[[command]]
args = "subcommand --fixed-flag" # Subcommand + fixed args (required)
flags = [                        # Flags to expose as nu flags (optional)
  { long = "all", short = "a", type = "bool", description = "Show everything" },
  { long = "filter", short = "f", type = "string", description = "Filter" },
]
positional_args = [              # Positional parameters (optional)
  { name = "target", type = "string", optional = false, description = "The target" },
]
parse_helper = ""                # LLM hint for how to parse output (optional)
columns = []                     # Explicit column names (optional)
delimiter = ""                   # CSV/TSV delimiter (optional)
parse_format = ""                # Simple nu `parse` pattern using {col} placeholders (optional, preferred over regex)
parse_pattern = ""               # Explicit nu `parse --regex` pattern — AVOID if possible, angle brackets cause parser issues (optional)
column_types = {}                # Type coercion per column (optional)
reverse = false                  # Reverse row order (optional)
stderr = false                   # If true, output comes from stderr — use `complete` to capture (optional)
follow_flag = ""                 # Name of a bool flag that enables streaming — when set, skip parsing and stream raw (optional)
```

## Generation Rules

### 0. Base Command (ALWAYS generate first)

Always generate a base `def cli_new_command` that:
- With `...rest` args: passes them through to the bare `cli_command` so unwrapped subcommands still work (e.g. `nutool doctor`)
- With `--info (-i)`: parses `cli_command --help` output into a single structured Nushell table with columns: `section`, `command`, `description`. This makes the help output filterable and pipeable (e.g. `nutool -i | where section == "Commands"`)
- **CRITICAL**: Do NOT use `--help (-h)` — Nushell reserves that flag and intercepts it to show its own built-in help instead of running your code. Use `--info (-i)` instead.

```nushell
def nutool [
    --info (-i)             # Show cli_command help as structured table
    ...rest: string         # Pass-through args to cli_command
] {
    if $info {
        let result = do { ^cli_command --help } | complete
        let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
        if ($raw | str trim | is-empty) { return [] }
        mut rows = []
        mut current_section = ""
        for line in ($raw | lines) {
            if ($line | str trim | is-empty) {
                # skip blank lines
            } else if ($line =~ '^\S') {
                $current_section = ($line | str trim | str replace ':$' '')
            } else if ($line =~ '^\s+\S') {
                let parts = ($line | str trim | split row -r '\s{2,}')
                let item = ($parts | first)
                let desc = if ($parts | length) > 1 { $parts | skip 1 | str join ' ' } else { '' }
                $rows = ($rows | append {section: $current_section, command: $item, description: $desc})
            }
        }
        $rows
    } else {
        run-external cli_command ...$rest
    }
}
```

Then generate the subcommand `def` blocks below.

For each `[[command]]` entry, generate a Nushell `def` block following these rules:

### 1. Command Name
- Format: `"cli_new_command subcommand"` where subcommand is the first word of `args`
- Example: cli_new_command = "nudocker", args = "ps -a" → `def "nudocker ps"`

### 2. Signature
- **Bool flags**: `--flagname (-x)` (no type annotation)
- **String flags**: `--flagname (-x): string = ""` (with type annotation and empty default — REQUIRED to avoid `missing_flag_param` parser error)
- **Flags without short**: `--flagname` or `--flagname: string = ""`
- **Required positional args**: `name: type`
- **Optional positional args**: `name?: type`
- **CRITICAL — Name collisions**: If a positional arg has the same name as a flag (e.g. `--formula` flag and `formula?` positional), Nushell will shadow the flag with the positional. The positional will be `null` when not provided, and `if $formula` will fail with `can't convert nothing to boolean`. **Always rename the positional arg** to avoid collisions (e.g. rename `formula?` to `name?`)
- Add descriptions using `# description` comments in the signature

### 3. Command Body
Build an argument list and call the external command.

**CRITICAL**: `run-external` can return `nothing` (e.g. when a command writes to stderr, or produces empty stdout). Piping `nothing` into `detect columns`, `parse`, `lines`, etc. causes `Input type not supported` errors. Therefore, **whenever the output will be parsed** (i.e. any parsing pipeline is applied), ALWAYS use `complete` to capture the output, then use `($result.stdout? | default "")` and `($result.stderr? | default "")` to safely handle null fields — in Nushell, `null + string` evaluates to `null`, so both fields MUST be defaulted:

```nushell
def "nutool sub" [
    --all (-a)          # Show all
    --filter (-f): string = ""  # Filter condition
    target: string      # The target
] {
    mut args = [sub --fixed-flags]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    $args = ($args | append $target)
    let result = run-external cli_command ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | <parsing pipeline>
}
```

Only when `parse_helper` says "streaming text, do not parse" (no parsing pipeline) should you pipe `run-external` directly without `complete`.

### 4. Parsing Pipeline — Priority Order

Choose the parsing approach in this priority:

1. **`parse_format` is set**: Use `| parse $format` (simple `{column}` placeholders, no `--regex` flag). If columns need trimming, append `| update column_name { str trim }` for each column that may have extra whitespace
1b. **`parse_pattern` is set**: Use `| parse --regex $pattern` — but AVOID this when possible as `<>` in regex named groups can cause Nushell parser issues. Prefer `parse_format` instead
2. **`columns` + `delimiter` are set**: Use `| from csv --separator $delimiter` or `| split column $delimiter ...columns`
3. **`columns` are set (no delimiter)**: Use `| detect columns` then rename to match specified columns
4. **`parse_helper` suggests tabular output**: Use `| detect columns --guess` with header sanitization (see below)
5. **`parse_helper` suggests line-oriented output** (e.g. "line-oriented text", logs): Use `| lines | enumerate | flatten | rename index line` to produce a table with numbered lines
6. **`parse_helper` suggests non-tabular output** (e.g. "streaming text", "do not parse"): Do NOT add any parsing pipeline — just return the raw output from `run-external` directly (no `complete`)

### 5. Header Sanitization (CRITICAL for `detect columns`)

Whenever `detect columns` is used, ALWAYS sanitize headers immediately after:

```nushell
| detect columns --guess
| rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
```

This converts headers like "CONTAINER ID" → "container_id", "IMAGE ID" → "image_id", etc.

### 6. Column Type Coercion

If `column_types` is specified, add conversion after parsing:

```nushell
| update size { into int }
```

### 7. Stderr Capture

Since all parsed commands already use `complete` (see rule 3), the `stderr = true` flag is mainly a documentation hint. The `($result.stdout? | default "") + ($result.stderr? | default "")` concatenation in the standard pattern already captures both streams. No additional changes are needed for stderr commands — the default `complete` pattern handles it.

### 8. Follow Flag (Streaming Mode)

If `follow_flag` is set (e.g. `follow_flag = "follow"`), the named bool flag enables streaming mode. When that flag is active, parsing is impossible (stream never ends). Generate an `if`/`else` branch:

```nushell
if $follow {
    run-external cli_command ...$args
} else {
    let result = run-external cli_command ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | <parsing pipeline>
}
```

Only the non-follow branch gets the parsing pipeline. The follow branch streams raw output.

### 9. Reverse

If `reverse = true`, append `| reverse` at the end of the pipeline.

## Output Format

Write the generated `def` blocks to a `.nu` file in the same directory as the input TOML:

```
wrappers/<cli_command>/<cli_version>/<cli_command>.nu
```

Create the directory with `mkdir -p` if it doesn't exist. The file should contain ONLY the generated `def` blocks, one after another, with a blank line between each — no markdown fences, no explanation, no preamble.

After writing, tell the user:
> Created `wrappers/<cli_command>/<cli_version>/<cli_command>.nu`.

## Important Notes

- **Regex named groups**: Nushell uses `(?<name>...)` syntax, NOT Python-style `(?P<name>...)` — the `P` will cause a parse error
- Use `run-external` (not `^command`) for calling the CLI tool — this is the idiomatic Nushell way to call external commands with dynamic args
- For bool flags, check with `if $flagname { ... }`
- For string flags, check with `if ($flagname | is-not-empty) { ... }`
- When `follow_flag` is set, only parse in the non-follow branch — the follow branch must stream raw output
- Keep generated code minimal and clean — no unnecessary comments in the body
- **CRITICAL**: Nushell uses `mut` for mutable variables, NOT `let mut`. `let mut` is a syntax error. Always use `mut x = ...` (never `let mut x = ...`)
