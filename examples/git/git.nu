def nugit [
    --info (-i)             # Show git help as structured table
    ...rest: string         # Pass-through args to git
] {
    if $info {
        let result = do { ^git --help } | complete
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
        run-external git ...$rest
    }
}

def "nugit status" [
    --short (-s)            # Give output in short format
    --branch (-b)           # Show branch and tracking info
    --porcelain             # Give output in porcelain format
] {
    mut args = [status]
    if $short { $args = ($args | append "--short") }
    if $branch { $args = ($args | append "--branch") }
    if $porcelain { $args = ($args | append "--porcelain") }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nugit log" [
    --all                   # Show all refs
    --graph                 # Draw text graphical representation of history
    --author: string = ""   # Filter commits by author
    --since: string = ""    # Show commits more recent than a specific date
    --until: string = ""    # Show commits older than a specific date
    --grep: string = ""     # Filter commits by message pattern
    --max-count (-n): string = ""  # Limit number of commits to show
    revision_range?: string # Revision range (e.g. HEAD~5..HEAD)
] {
    mut args = [log "--format=%H|%as|%an|%s"]
    if $all { $args = ($args | append "--all") }
    if $graph { $args = ($args | append "--graph") }
    if ($author | is-not-empty) { $args = ($args | append ["--author" $author]) }
    if ($since | is-not-empty) { $args = ($args | append ["--since" $since]) }
    if ($until | is-not-empty) { $args = ($args | append ["--until" $until]) }
    if ($grep | is-not-empty) { $args = ($args | append ["--grep" $grep]) }
    if ($max_count | is-not-empty) { $args = ($args | append ["--max-count" $max_count]) }
    if ($revision_range | is-not-empty) { $args = ($args | append $revision_range) }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | each {|line| $line | split column "|" hash date author subject }
    | flatten
    | update hash { str trim }
    | update date { str trim }
    | update author { str trim }
    | update subject { str trim }
}

def "nugit branch" [
    --all (-a)              # List both remote-tracking and local branches
    --remotes (-r)          # List only remote-tracking branches
    --verbose (-v)          # Show sha1 and commit subject line for each head
    --merged: string = ""   # Only list branches merged into the named commit
    --no-merged: string = "" # Only list branches not merged into the named commit
    --delete (-d)           # Delete a branch
    name?: string           # Branch name
] {
    mut args = [branch]
    if $all { $args = ($args | append "--all") }
    if $remotes { $args = ($args | append "--remotes") }
    if $verbose { $args = ($args | append "--verbose") }
    if ($merged | is-not-empty) { $args = ($args | append ["--merged" $merged]) }
    if ($no_merged | is-not-empty) { $args = ($args | append ["--no-merged" $no_merged]) }
    if $delete { $args = ($args | append "--delete") }
    if ($name | is-not-empty) { $args = ($args | append $name) }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nugit diff" [
    --stat                  # Show diffstat instead of patch
    --staged                # Compare staged changes to HEAD
    --name-only             # Show only names of changed files
    --name-status           # Show names and status of changed files
    commit?: string         # Commit, branch, or range to diff against
] {
    mut args = [diff]
    if $stat { $args = ($args | append "--stat") }
    if $staged { $args = ($args | append "--staged") }
    if $name_only { $args = ($args | append "--name-only") }
    if $name_status { $args = ($args | append "--name-status") }
    if ($commit | is-not-empty) { $args = ($args | append $commit) }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nugit remote" [
    --verbose (-v)          # Show remote URL after the name
] {
    mut args = [remote]
    if $verbose { $args = ($args | append "--verbose") }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | parse "{name}\t{url}"
    | update name { str trim }
    | update url { str trim }
}

def "nugit stash" [] {
    let result = run-external git stash list | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | parse "{ref}: On {branch}: {message}"
    | update ref { str trim }
    | update branch { str trim }
    | update message { str trim }
}

def "nugit tag" [
    --list (-l)             # List tags
    --sort: string = ""     # Sort by a specific key (e.g. -version:refname)
    --annotate (-a)         # Make an unsigned annotated tag object
    --message (-m): string = "" # Tag message
    --delete (-d)           # Delete existing tags
    name?: string           # Tag name
] {
    mut args = [tag]
    if $list { $args = ($args | append "--list") }
    if ($sort | is-not-empty) { $args = ($args | append ["--sort" $sort]) }
    if $annotate { $args = ($args | append "--annotate") }
    if ($message | is-not-empty) { $args = ($args | append ["--message" $message]) }
    if $delete { $args = ($args | append "--delete") }
    if ($name | is-not-empty) { $args = ($args | append $name) }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "nugit show" [
    --stat                  # Show diffstat
    object?: string         # Object to show (commit, tag, tree, blob)
] {
    mut args = [show "--stat"]
    if ($object | is-not-empty) { $args = ($args | append $object) }
    let result = run-external git ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}
