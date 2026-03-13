def nuzero [
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

def "nuzero status" [] {
    mut args = ["status"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nuzero providers" [] {
    mut args = ["providers"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuzero providers-quota" [] {
    mut args = ["providers-quota"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuzero models list" [
    --provider: string = ""  # Provider name
] {
    mut args = ["models", "list"]
    if ($provider | is-not-empty) { $args = ($args | append ["--provider", $provider]) }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuzero models status" [
    --provider: string = ""  # Provider name
] {
    mut args = ["models", "status"]
    if ($provider | is-not-empty) { $args = ($args | append ["--provider", $provider]) }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}

def "nuzero memory list" [
    --category: string = ""  # Filter by category
    --limit: string = ""     # Max entries to return
] {
    mut args = ["memory", "list"]
    if ($category | is-not-empty) { $args = ($args | append ["--category", $category]) }
    if ($limit | is-not-empty) { $args = ($args | append ["--limit", $limit]) }
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuzero memory stats" [] {
    mut args = ["memory", "stats"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}

def "nuzero doctor" [] {
    mut args = ["doctor"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nuzero config" [] {
    mut args = ["config"]
    let result = run-external zeroclaw ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}
