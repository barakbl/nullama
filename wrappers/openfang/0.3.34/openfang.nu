def openfang [
    --info (-i)             # Show openfang help as structured table
    ...rest: string         # Pass-through args to openfang
] {
    if $info {
        let result = do { ^openfang --help } | complete
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
        run-external openfang ...$rest
    }
}

def "openfang status" [] {
    mut args = ["status"]
    run-external openfang ...$args
}

def "openfang health" [] {
    mut args = ["health"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "openfang doctor" [] {
    mut args = ["doctor"]
    run-external openfang ...$args
}

def "openfang agent list" [] {
    mut args = ["agent" "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang agent new" [
    name?: string           # Agent template name
] {
    mut args = ["agent" "new"]
    if $name != null { $args = ($args | append $name) }
    run-external openfang ...$args
}

def "openfang agent chat" [
    agent?: string          # Agent name to chat with
] {
    mut args = ["agent" "chat"]
    if $agent != null { $args = ($args | append $agent) }
    run-external openfang ...$args
}

def "openfang agent kill" [
    agent: string           # Agent name or ID to kill
] {
    mut args = ["agent" "kill"]
    $args = ($args | append $agent)
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "openfang skill list" [] {
    mut args = ["skill" "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang skill search" [
    query: string           # Search query for FangHub skills
] {
    mut args = ["skill" "search"]
    $args = ($args | append $query)
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang skill install" [
    name: string            # Skill name or local path to install
] {
    mut args = ["skill" "install"]
    $args = ($args | append $name)
    run-external openfang ...$args
}

def "openfang skill remove" [
    name: string            # Skill name to remove
] {
    mut args = ["skill" "remove"]
    $args = ($args | append $name)
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "openfang models list" [
    --provider (-p): string = ""    # Filter models by provider
] {
    mut args = ["models" "list"]
    if ($provider | is-not-empty) { $args = ($args | append ["--provider" $provider]) }
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang models providers" [] {
    mut args = ["models" "providers"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang channel list" [] {
    mut args = ["channel" "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang config show" [] {
    mut args = ["config" "show"]
    run-external openfang ...$args
}

def "openfang config get" [
    key: string             # Config key to get
] {
    mut args = ["config" "get"]
    $args = ($args | append $key)
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "openfang config set" [
    key: string             # Config key to set
    value: string           # Value to set
] {
    mut args = ["config" "set"]
    $args = ($args | append $key)
    $args = ($args | append $value)
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "openfang logs" [
    --follow (-f)           # Follow log output
] {
    mut args = ["logs"]
    if $follow {
        run-external openfang ...$args
    } else {
        let result = run-external openfang ...$args | complete
        let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
        if ($raw | str trim | is-empty) { return [] }
        $raw | lines | enumerate | flatten | rename index line
    }
}

def "openfang cron list" [] {
    mut args = ["cron" "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang sessions" [] {
    mut args = ["sessions"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang memory list" [
    --category (-c): string = ""    # Filter by category
    --limit (-n): string = ""       # Limit number of results
] {
    mut args = ["memory" "list"]
    if ($category | is-not-empty) { $args = ($args | append ["--category" $category]) }
    if ($limit | is-not-empty) { $args = ($args | append ["--limit" $limit]) }
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "openfang memory get" [
    key: string             # Memory key to retrieve
] {
    mut args = ["memory" "get"]
    $args = ($args | append $key)
    run-external openfang ...$args
}

def "openfang memory stats" [] {
    mut args = ["memory" "stats"]
    run-external openfang ...$args
}

def "openfang integrations" [] {
    mut args = ["integrations"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}
