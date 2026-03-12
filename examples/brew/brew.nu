def nubrew [
    --info (-i)             # Show brew help as structured table
    ...rest: string         # Pass-through args to brew
] {
    if $info {
        let result = do { ^brew --help } | complete
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
        run-external brew ...$rest
    }
}

def "nubrew list" [
    --formula              # List only formulae
    --cask                 # List only casks
    --full-name            # Print formulae with fully-qualified names
    --versions             # Show the version number for installed formulae
    --pinned               # List only pinned formulae
    name?: string          # Formula or cask name
] {
    mut args = [list]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $full_name { $args = ($args | append "--full-name") }
    if $versions { $args = ($args | append "--versions") }
    if $pinned { $args = ($args | append "--pinned") }
    if ($name | is-not-empty) { $args = ($args | append $name) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nubrew info" [
    --json                 # Print a JSON representation
    --installed            # Print JSON of formulae that are currently installed
    --formula              # Treat all named arguments as formulae
    --cask                 # Treat all named arguments as casks
    --sizes                # Show the size of installed formulae and casks
    --verbose (-v)         # Show more verbose analytics data
    name?: string          # Formula or cask name
] {
    mut args = [info]
    if $json { $args = ($args | append "--json") }
    if $installed { $args = ($args | append "--installed") }
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $sizes { $args = ($args | append "--sizes") }
    if $verbose { $args = ($args | append "--verbose") }
    if ($name | is-not-empty) { $args = ($args | append $name) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | each {|line| $line | parse "{key}: {value}" } | flatten
    | update key { str trim }
    | update value { str trim }
}

def "nubrew search" [
    --formula              # Search for formulae
    --cask                 # Search for casks
    --desc                 # Search descriptions
    text: string           # Search text or /regex/
] {
    mut args = [search]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $desc { $args = ($args | append "--desc") }
    $args = ($args | append $text)
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nubrew outdated" [
    --formula              # List only outdated formulae
    --cask                 # List only outdated casks
    --json                 # Print output in JSON format
    --greedy (-g)          # Include casks with auto_updates or version :latest
    --verbose (-v)         # Include detailed version information
    --quiet (-q)           # List only the names of outdated kegs
] {
    mut args = [outdated]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $json { $args = ($args | append "--json") }
    if $greedy { $args = ($args | append "--greedy") }
    if $verbose { $args = ($args | append "--verbose") }
    if $quiet { $args = ($args | append "--quiet") }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nubrew deps" [
    --topological (-n)     # Sort dependencies in topological order
    --direct               # Show only direct declared dependencies
    --tree                 # Show dependencies as a tree
    --installed            # List dependencies for currently installed formulae
    --missing              # Show only missing dependencies
    --annotate             # Mark build, test, optional, or recommended dependencies
    --formula              # Treat all named arguments as formulae
    --for-each             # List dependencies for each provided formula, one per line
    name?: string          # Formula or cask name
] {
    mut args = [deps]
    if $topological { $args = ($args | append "--topological") }
    if $direct { $args = ($args | append "--direct") }
    if $tree { $args = ($args | append "--tree") }
    if $installed { $args = ($args | append "--installed") }
    if $missing { $args = ($args | append "--missing") }
    if $annotate { $args = ($args | append "--annotate") }
    if $formula { $args = ($args | append "--formula") }
    if $for_each { $args = ($args | append "--for-each") }
    if ($name | is-not-empty) { $args = ($args | append $name) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nubrew services" [
    --json                 # Output as JSON
] {
    mut args = [services list]
    if $json { $args = ($args | append "--json") }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}
