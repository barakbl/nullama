def nupython [
    --info (-i)             # Show python3 help as structured table
    ...rest: string         # Pass-through args to python3
] {
    if $info {
        let result = do { ^python3 --help } | complete
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
        run-external python3 ...$rest
    }
}

def "nupython version" [] {
    let result = run-external python3 "--version" | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | parse "Python {version}"
    | update version { str trim }
}

def "nupython eval" [
    code: string            # Python code to execute
] {
    mut args = ["-c", $code]
    let result = run-external python3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines | enumerate | flatten | rename index line
}

def "nupython module" [
    module: string          # Python module to run as script
    ...rest: string         # Pass-through args to the module
] {
    mut args = ["-m", $module]
    run-external python3 ...$args ...$rest
}
