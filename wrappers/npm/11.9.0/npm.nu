def npm [
    --info (-i)             # Show npm help as structured table
    ...rest: string         # Pass-through args to npm
] {
    if $info {
        let result = do { ^npm --help } | complete
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
        run-external npm ...$rest
    }
}

def "npm install" [
    --save-dev (-D)         # Save to devDependencies
    --save-optional (-O)    # Save to optionalDependencies
    --global (-g)           # Install package globally
    --no-save               # Do not save to package.json
    package?: string        # Package to install (omit to install from package.json)
] {
    mut args = ["install"]
    if $save_dev { $args = ($args | append "--save-dev") }
    if $save_optional { $args = ($args | append "--save-optional") }
    if $global { $args = ($args | append "--global") }
    if $no_save { $args = ($args | append "--no-save") }
    if $package != null { $args = ($args | append $package) }
    run-external npm ...$args
}

def "npm uninstall" [
    --save-dev (-D)         # Remove from devDependencies
    --global (-g)           # Uninstall a global package
    package: string         # Package to uninstall
] {
    mut args = ["uninstall"]
    if $save_dev { $args = ($args | append "--save-dev") }
    if $global { $args = ($args | append "--global") }
    $args = ($args | append $package)
    run-external npm ...$args
}

def "npm update" [
    --global (-g)           # Update global packages
    package?: string        # Package to update (omit to update all)
] {
    mut args = ["update"]
    if $global { $args = ($args | append "--global") }
    if $package != null { $args = ($args | append $package) }
    run-external npm ...$args
}

def "npm ls" [
    --all (-a)              # Show all installed packages including transitive dependencies
    --global (-g)           # List global packages
    --depth: string = ""    # Max display depth of the dependency tree
    --json                  # Output as JSON
] {
    mut args = ["ls"]
    if $all { $args = ($args | append "--all") }
    if $global { $args = ($args | append "--global") }
    if ($depth | is-not-empty) { $args = ($args | append ["--depth" $depth]) }
    if $json { $args = ($args | append "--json") }
    let result = run-external npm ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "npm outdated" [
    --all (-a)              # Show all outdated packages
    --global (-g)           # Check global packages
    --json                  # Output as JSON
] {
    mut args = ["outdated"]
    if $all { $args = ($args | append "--all") }
    if $global { $args = ($args | append "--global") }
    if $json { $args = ($args | append "--json") }
    let result = run-external npm ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | detect columns --guess | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "npm run" [
    script: string          # Script name from package.json scripts
] {
    mut args = ["run"]
    $args = ($args | append $script)
    run-external npm ...$args
}

def "npm test" [
] {
    mut args = ["test"]
    run-external npm ...$args
}

def "npm audit" [
    --fix                   # Automatically install compatible updates to vulnerable dependencies
    --json                  # Output audit report as JSON
    --production            # Only audit production dependencies
] {
    mut args = ["audit"]
    if $fix { $args = ($args | append "--fix") }
    if $json { $args = ($args | append "--json") }
    if $production { $args = ($args | append "--production") }
    run-external npm ...$args
}

def "npm publish" [
    --access: string = ""   # Set package access level: public or restricted
    --tag: string = ""      # Register published package with this tag
    --dry-run               # Performs all steps except actually publishing
] {
    mut args = ["publish"]
    if ($access | is-not-empty) { $args = ($args | append ["--access" $access]) }
    if ($tag | is-not-empty) { $args = ($args | append ["--tag" $tag]) }
    if $dry_run { $args = ($args | append "--dry-run") }
    run-external npm ...$args
}

def "npm init" [
    --yes (-y)              # Automatically generate package.json with defaults
] {
    mut args = ["init"]
    if $yes { $args = ($args | append "--yes") }
    run-external npm ...$args
}
