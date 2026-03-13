def brew [
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

def "brew install" [
    formula_or_cask: string  # Formula or cask to install
    --formula                # Treat all named arguments as formulae
    --cask                   # Treat all named arguments as casks
    --verbose (-v)           # Print verification and post-install steps
    --debug (-d)             # If install fails, open an interactive debugging session
    --dry-run (-n)           # Show what would be installed without actually installing
    --fetch-HEAD             # Fetch the upstream repository to detect if the HEAD installation is outdated
    --ignore-dependencies    # Skip installing any dependencies of any kind
    --only-dependencies      # Install dependencies but not the formula itself
    --build-from-source (-s) # Compile from source even if a bottle is available
    --force (-f)             # Install formulae without checking for previously installed versions
    --quiet (-q)             # Make some output more quiet
] {
    mut args = ["install"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $verbose { $args = ($args | append "--verbose") }
    if $debug { $args = ($args | append "--debug") }
    if $dry_run { $args = ($args | append "--dry-run") }
    if $fetch_HEAD { $args = ($args | append "--fetch-HEAD") }
    if $ignore_dependencies { $args = ($args | append "--ignore-dependencies") }
    if $only_dependencies { $args = ($args | append "--only-dependencies") }
    if $build_from_source { $args = ($args | append "--build-from-source") }
    if $force { $args = ($args | append "--force") }
    if $quiet { $args = ($args | append "--quiet") }
    $args = ($args | append $formula_or_cask)
    run-external brew ...$args
}

def "brew uninstall" [
    formula_or_cask: string  # Formula or cask to uninstall
    --formula                # Treat all named arguments as formulae
    --cask                   # Treat all named arguments as casks
    --force (-f)             # Delete all installed versions of the formula
    --zap                    # Remove all files associated with a cask (casks only)
    --ignore-dependencies    # Uninstall even if other formulae depend on this one
    --dry-run (-n)           # List files that would be uninstalled without actually uninstalling
] {
    mut args = ["uninstall"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $force { $args = ($args | append "--force") }
    if $zap { $args = ($args | append "--zap") }
    if $ignore_dependencies { $args = ($args | append "--ignore-dependencies") }
    if $dry_run { $args = ($args | append "--dry-run") }
    $args = ($args | append $formula_or_cask)
    run-external brew ...$args
}

def "brew update" [
    --merge                  # Use git merge to apply updates (instead of git rebase)
    --auto-update            # Run on auto-updates (lower verbosity)
    --force (-f)             # Always do a slower full update check
    --verbose (-v)           # Print warnings for outdated repositories
    --quiet (-q)             # Make some output more quiet
] {
    mut args = ["update"]
    if $merge { $args = ($args | append "--merge") }
    if $auto_update { $args = ($args | append "--auto-update") }
    if $force { $args = ($args | append "--force") }
    if $verbose { $args = ($args | append "--verbose") }
    if $quiet { $args = ($args | append "--quiet") }
    run-external brew ...$args
}

def "brew upgrade" [
    formula_or_cask?: string # Formula or cask to upgrade (upgrades all if omitted)
    --formula                # Treat all named arguments as formulae
    --cask                   # Treat all named arguments as casks
    --dry-run (-n)           # Show what would be upgraded without actually upgrading
    --fetch-HEAD             # Fetch the upstream repository to detect if the HEAD installation is outdated
    --ignore-pinned          # Set a successful exit status even if pinned formulae are not upgraded
    --force (-f)             # Install formulae without checking for previously installed versions
    --verbose (-v)           # Print verification and post-install steps
    --quiet (-q)             # Make some output more quiet
    --greedy (-g)            # Also upgrade casks with auto_updates true or version :latest
] {
    mut args = ["upgrade"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $dry_run { $args = ($args | append "--dry-run") }
    if $fetch_HEAD { $args = ($args | append "--fetch-HEAD") }
    if $ignore_pinned { $args = ($args | append "--ignore-pinned") }
    if $force { $args = ($args | append "--force") }
    if $verbose { $args = ($args | append "--verbose") }
    if $quiet { $args = ($args | append "--quiet") }
    if $greedy { $args = ($args | append "--greedy") }
    if $formula_or_cask != null { $args = ($args | append $formula_or_cask) }
    run-external brew ...$args
}

def "brew list" [
    formula_or_cask?: string # Filter list to only the named formula or cask
    --formula                # List only formulae
    --cask                   # List only casks
    --full-name              # Print formulae with fully-qualified names
    --versions (-l)          # Show the version number for installed formulae
    --multiple               # Only show formulae with multiple versions installed
    --pinned                 # List only pinned formulae
    --1                      # Force output to be one entry per line
    --quiet (-q)             # Make some output more quiet
] {
    mut args = ["list"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $full_name { $args = ($args | append "--full-name") }
    if $versions { $args = ($args | append "--versions") }
    if $multiple { $args = ($args | append "--multiple") }
    if $pinned { $args = ($args | append "--pinned") }
    if $1 { $args = ($args | append "--1") }
    if $quiet { $args = ($args | append "--quiet") }
    if $formula_or_cask != null { $args = ($args | append $formula_or_cask) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index name
}

def "brew search" [
    query: string            # Text or /regex/ to search for
    --formula                # Search for formulae only
    --cask                   # Search for casks only
    --desc (-d)              # Search for descriptions as well as names
    --eval-all               # Evaluate all available formulae and casks
] {
    mut args = ["search"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $desc { $args = ($args | append "--desc") }
    if $eval_all { $args = ($args | append "--eval-all") }
    $args = ($args | append $query)
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index name
}

def "brew info" [
    formula_or_cask?: string # Formula or cask to show info for
    --formula                # Treat all named arguments as formulae
    --cask                   # Treat all named arguments as casks
    --json (-j)              # Output in JSON format
    --all                    # Print JSON of all available formulae
    --installed              # Print JSON of all installed formulae
    --verbose (-v)           # Show more verbose analytics data for all installs
    --quiet (-q)             # Make some output more quiet
] {
    mut args = ["info"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $json { $args = ($args | append "--json") }
    if $all { $args = ($args | append "--all") }
    if $installed { $args = ($args | append "--installed") }
    if $verbose { $args = ($args | append "--verbose") }
    if $quiet { $args = ($args | append "--quiet") }
    if $formula_or_cask != null { $args = ($args | append $formula_or_cask) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "brew doctor" [
    --list-checks            # List all audit methods
    --quiet (-q)             # Make some output more quiet
    --verbose (-v)           # Make some output more verbose
] {
    mut args = ["doctor"]
    if $list_checks { $args = ($args | append "--list-checks") }
    if $quiet { $args = ($args | append "--quiet") }
    if $verbose { $args = ($args | append "--verbose") }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "brew outdated" [
    --formula                # List only outdated formulae
    --cask                   # List only outdated casks
    --json (-j)              # Output in JSON format
    --greedy (-g)            # Print outdated casks with auto_updates true or version :latest too
    --verbose (-v)           # Include detailed version information
    --quiet (-q)             # List only the names of outdated kegs
] {
    mut args = ["outdated"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $json { $args = ($args | append "--json") }
    if $greedy { $args = ($args | append "--greedy") }
    if $verbose { $args = ($args | append "--verbose") }
    if $quiet { $args = ($args | append "--quiet") }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | where ($it | str trim | is-not-empty) | parse "{name} ({current_version}) != {latest_version}"
}

def "brew leaves" [
    --installed-on-request (-r)   # Only list leaves that were manually installed
    --installed-as-dependency (-p) # Only list leaves that were installed as dependencies
] {
    mut args = ["leaves"]
    if $installed_on_request { $args = ($args | append "--installed-on-request") }
    if $installed_as_dependency { $args = ($args | append "--installed-as-dependency") }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index name
}

def "brew deps" [
    formula_or_cask?: string # Formula or cask to list dependencies for
    --formula                # Treat all named arguments as formulae
    --cask                   # Treat all named arguments as casks
    --full-name (-n)         # List dependencies by their full name
    --for-each               # Print a formula per line with each formula's dependencies
    --installed              # List dependencies for formulae that are currently installed
    --include-build          # Include build dependencies for formula
    --include-optional       # Include optional dependencies for formula
    --tree                   # Show dependencies as a tree
    --quiet (-q)             # Make some output more quiet
] {
    mut args = ["deps"]
    if $formula { $args = ($args | append "--formula") }
    if $cask { $args = ($args | append "--cask") }
    if $full_name { $args = ($args | append "--full-name") }
    if $for_each { $args = ($args | append "--for-each") }
    if $installed { $args = ($args | append "--installed") }
    if $include_build { $args = ($args | append "--include-build") }
    if $include_optional { $args = ($args | append "--include-optional") }
    if $tree { $args = ($args | append "--tree") }
    if $quiet { $args = ($args | append "--quiet") }
    if $formula_or_cask != null { $args = ($args | append $formula_or_cask) }
    let result = run-external brew ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index name
}
