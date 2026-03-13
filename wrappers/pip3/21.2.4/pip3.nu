def pip3 [
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
        run-external pip3 ...$rest
    }
}

def "pip3 list" [
    --outdated (-o)         # List outdated packages
    --uptodate (-u)         # List uptodate packages
    --user                  # Only output packages installed in user-site
    --local (-l)            # Do not list globally-installed packages
    --not-required          # List packages that are not dependencies of installed packages
] {
    mut args = ["list"]
    if $outdated { $args = ($args | append "--outdated") }
    if $uptodate { $args = ($args | append "--uptodate") }
    if $user { $args = ($args | append "--user") }
    if $local { $args = ($args | append "--local") }
    if $not_required { $args = ($args | append "--not-required") }
    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "pip3 install" [
    --requirement (-r): string = ""  # Install from the given requirements file
    --upgrade (-U)                   # Upgrade package to the newest available version
    --editable (-e)                  # Install in editable mode from a local path or VCS url
    --no-deps                        # Don't install package dependencies
    --user                           # Install to the Python user install directory
    --target (-t): string = ""       # Install packages into this directory
    package?: string                 # Package name (with optional version specifier)
] {
    mut args = ["install"]
    if ($requirement | is-not-empty) { $args = ($args | append ["--requirement" $requirement]) }
    if $upgrade { $args = ($args | append "--upgrade") }
    if $editable { $args = ($args | append "--editable") }
    if $no_deps { $args = ($args | append "--no-deps") }
    if $user { $args = ($args | append "--user") }
    if ($target | is-not-empty) { $args = ($args | append ["--target" $target]) }
    if $package != null { $args = ($args | append $package) }
    run-external pip3 ...$args
}

def "pip3 uninstall" [
    --yes (-y)                       # Don't ask for confirmation of uninstall deletions
    --requirement (-r): string = ""  # Uninstall all packages listed in the given requirements file
    package?: string                 # Package to uninstall
] {
    mut args = ["uninstall"]
    if $yes { $args = ($args | append "--yes") }
    if ($requirement | is-not-empty) { $args = ($args | append ["--requirement" $requirement]) }
    if $package != null { $args = ($args | append $package) }
    run-external pip3 ...$args
}

def "pip3 show" [
    --files (-f)            # Show the full list of installed files for each package
    package: string         # Package name to show information about
] {
    mut args = ["show"]
    if $files { $args = ($args | append "--files") }
    $args = ($args | append $package)
    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "pip3 freeze" [
    --local (-l)            # Do not list globally-installed packages
    --user                  # Only output packages installed in user-site
] {
    mut args = ["freeze"]
    if $local { $args = ($args | append "--local") }
    if $user { $args = ($args | append "--user") }
    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "pip3 download" [
    --requirement (-r): string = ""  # Download from the given requirements file
    --dest (-d): string = ""         # Download packages into this directory
    package?: string                 # Package to download
] {
    mut args = ["download"]
    if ($requirement | is-not-empty) { $args = ($args | append ["--requirement" $requirement]) }
    if ($dest | is-not-empty) { $args = ($args | append ["--dest" $dest]) }
    if $package != null { $args = ($args | append $package) }
    run-external pip3 ...$args
}

def "pip3 cache list" [] {
    mut args = ["cache" "list"]
    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "pip3 check" [] {
    mut args = ["check"]
    let result = run-external pip3 ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}
