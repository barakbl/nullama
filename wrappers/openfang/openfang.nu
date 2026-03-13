def nufang [
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

def "nufang status" [] {
    mut args = ["status"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}

def "nufang agent list" [] {
    mut args = ["agent", "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nufang skill list" [] {
    mut args = ["skill", "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nufang skill search" [
    query: string  # Search query string
] {
    mut args = ["skill", "search", $query]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nufang channel list" [] {
    mut args = ["channel", "list"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nufang models" [] {
    mut args = ["models"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nufang sessions" [] {
    mut args = ["sessions"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nufang logs" [] {
    run-external openfang "logs"
}

def "nufang health" [] {
    mut args = ["health"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}

def "nufang doctor" [] {
    mut args = ["doctor"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nufang config show" [] {
    mut args = ["config", "show"]
    let result = run-external openfang ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | each {|line| $line | parse "{key}: {value}" } | flatten | update key { str trim } | update value { str trim }
}
