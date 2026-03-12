# nupip - Nushell wrapper for pip3

def nupip [
    --info (-i)             # Show pip3 help as structured table
    ...rest: string         # Pass-through args to pip3
] {
    if $info {
        let result = do { ^pip3 --help } | complete
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
        run-external pip3 ...$rest
    }
}

def "nupip list" [
    --outdated (-o)         # List outdated packages
    --uptodate (-u)         # List uptodate packages
    --editable (-e)         # List editable projects
    --local (-l)            # Do not list globally-installed packages
    --user                  # Only output packages installed in user-site
    --format: string = ""   # Output format: columns (default), freeze, or json
    --not-required          # List packages that are not dependencies of installed packages
    --exclude: string = ""  # Exclude specified package from the output
] {
    mut args = ["list"]
    if $outdated { $args = ($args | append "--outdated") }
    if $uptodate { $args = ($args | append "--uptodate") }
    if $editable { $args = ($args | append "--editable") }
    if $local { $args = ($args | append "--local") }
    if $user { $args = ($args | append "--user") }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if $not_required { $args = ($args | append "--not-required") }
    if ($exclude | is-not-empty) { $args = ($args | append ["--exclude" $exclude]) }

    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nupip show" [
    package: string         # Package name to show info for
    --files (-f)            # Show the full list of installed files for each package
] {
    mut args = ["show"]
    if $files { $args = ($args | append "--files") }
    $args = ($args | append $package)

    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines
    | each {|line| $line | parse "{key}: {value}" }
    | flatten
    | update key { str trim }
    | update value { str trim }
}

def "nupip freeze" [
    --local (-l)            # Do not output globally-installed packages
    --user                  # Only output packages installed in user-site
    --all                   # Do not skip setuptools, pip, wheel
    --exclude-editable      # Exclude editable package from output
    --exclude: string = ""  # Exclude specified package from the output
] {
    mut args = ["freeze"]
    if $local { $args = ($args | append "--local") }
    if $user { $args = ($args | append "--user") }
    if $all { $args = ($args | append "--all") }
    if $exclude_editable { $args = ($args | append "--exclude-editable") }
    if ($exclude | is-not-empty) { $args = ($args | append ["--exclude" $exclude]) }

    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | parse "{package}=={version}"
    | update package { str trim }
    | update version { str trim }
}

def "nupip install" [
    package: string         # Package specifier to install
    --requirement (-r): string = ""  # Install from the given requirements file
    --upgrade (-U)          # Upgrade all specified packages to newest version
    --no-deps               # Don't install package dependencies
    --user                  # Install to the Python user install directory
    --force-reinstall       # Reinstall all packages even if up-to-date
] {
    mut args = ["install"]
    if ($requirement | is-not-empty) { $args = ($args | append ["--requirement" $requirement]) }
    if $upgrade { $args = ($args | append "--upgrade") }
    if $no_deps { $args = ($args | append "--no-deps") }
    if $user { $args = ($args | append "--user") }
    if $force_reinstall { $args = ($args | append "--force-reinstall") }
    $args = ($args | append $package)

    run-external pip3 ...$args
}

def "nupip check" [] {
    let result = run-external pip3 "check" | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines
    | enumerate
    | flatten
    | rename index line
}
