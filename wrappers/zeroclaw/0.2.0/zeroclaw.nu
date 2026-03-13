def zeroclaw [
    --info (-i)             # Show zeroclaw help as structured table
    ...rest: string         # Pass-through args to zeroclaw
] {
    if $info {
        let result = do { ^zeroclaw --help } | complete
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
        run-external zeroclaw ...$rest
    }
}

def "zeroclaw status" [] {
    mut args = ["status"]
    run-external zeroclaw ...$args
}

def "zeroclaw doctor" [] {
    mut args = ["doctor"]
    run-external zeroclaw ...$args
}

def "zeroclaw models list" [
    --provider (-p): string = ""    # Filter models by provider name
] {
    mut args = ["models" "list"]
    if ($provider | is-not-empty) { $args = ($args | append ["--provider" $provider]) }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw models status" [] {
    mut args = ["models" "status"]
    run-external zeroclaw ...$args
}

def "zeroclaw models set" [
    model: string           # Model name or ID to set as default
] {
    mut args = ["models" "set"]
    $args = ($args | append $model)
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "zeroclaw models refresh" [] {
    mut args = ["models" "refresh"]
    run-external zeroclaw ...$args
}

def "zeroclaw channel list" [] {
    mut args = ["channel" "list"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw channel add" [
    type: string            # Channel type (telegram, discord, slack, github, matrix, email, etc.)
    config: string          # JSON config string
] {
    mut args = ["channel" "add"]
    $args = ($args | append $type)
    $args = ($args | append $config)
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "zeroclaw channel remove" [
    name: string            # Channel name to remove
] {
    mut args = ["channel" "remove"]
    $args = ($args | append $name)
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "zeroclaw channel doctor" [] {
    mut args = ["channel" "doctor"]
    run-external zeroclaw ...$args
}

def "zeroclaw skill list" [] {
    mut args = ["skill" "list"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw skill install" [
    source: string          # Local path, git URL, or registry namespace/name
] {
    mut args = ["skill" "install"]
    $args = ($args | append $source)
    run-external zeroclaw ...$args
}

def "zeroclaw skill remove" [
    name: string            # Skill name to remove
] {
    mut args = ["skill" "remove"]
    $args = ($args | append $name)
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "zeroclaw skill new" [
    name?: string           # Skill project name
] {
    mut args = ["skill" "new"]
    if $name != null { $args = ($args | append $name) }
    run-external zeroclaw ...$args
}

def "zeroclaw memory list" [
    --category (-c): string = ""    # Filter by category
    --limit (-l): string = ""       # Limit number of results
] {
    mut args = ["memory" "list"]
    if ($category | is-not-empty) { $args = ($args | append ["--category" $category]) }
    if ($limit | is-not-empty) { $args = ($args | append ["--limit" $limit]) }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw memory get" [
    key: string             # Memory key to retrieve
] {
    mut args = ["memory" "get"]
    $args = ($args | append $key)
    run-external zeroclaw ...$args
}

def "zeroclaw memory stats" [] {
    mut args = ["memory" "stats"]
    run-external zeroclaw ...$args
}

def "zeroclaw memory clear" [
    --category (-c): string = ""    # Clear memories by category
    --yes (-y)                      # Skip confirmation prompt
] {
    mut args = ["memory" "clear"]
    if ($category | is-not-empty) { $args = ($args | append ["--category" $category]) }
    if $yes { $args = ($args | append "--yes") }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "zeroclaw config show" [] {
    mut args = ["config" "show"]
    run-external zeroclaw ...$args
}

def "zeroclaw cron list" [] {
    mut args = ["cron" "list"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw providers" [] {
    mut args = ["providers"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw providers-quota" [] {
    mut args = ["providers-quota"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw integrations" [] {
    mut args = ["integrations"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "zeroclaw memory reindex" [] {
    mut args = ["memory" "reindex"]
    run-external zeroclaw ...$args
}
