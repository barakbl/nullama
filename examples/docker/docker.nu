# nudocker - Nushell wrapper for docker

def nudocker [
    --info (-i)             # Show docker help as structured table
    ...rest: string         # Pass-through args to docker
] {
    if $info {
        let result = do { ^docker --help } | complete
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
        run-external docker ...$rest
    }
}

def "nudocker ps" [
    --all (-a)              # Show all containers
    --filter (-f): string = ""  # Filter output based on conditions
    --format: string = ""   # Format output using a Go template
    --last (-n): string = ""    # Show n last created containers
    --latest (-l)           # Show the latest created container
    --no-trunc              # Don't truncate output
    --quiet (-q)            # Only display container IDs
    --size (-s)             # Display total file sizes
] {
    mut args = ["ps"]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if ($last | is-not-empty) { $args = ($args | append ["--last" $last]) }
    if $latest { $args = ($args | append "--latest") }
    if $no_trunc { $args = ($args | append "--no-trunc") }
    if $quiet { $args = ($args | append "--quiet") }
    if $size { $args = ($args | append "--size") }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker images" [
    --all (-a)              # Show all images including intermediates
    --digests               # Show digests
    --filter (-f): string = ""  # Filter output based on conditions
    --format: string = ""   # Format output using a Go template
    --no-trunc              # Don't truncate output
    --quiet (-q)            # Only show image IDs
    repository?: string     # Repository name with optional tag
] {
    mut args = ["images"]
    if $all { $args = ($args | append "--all") }
    if $digests { $args = ($args | append "--digests") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if $no_trunc { $args = ($args | append "--no-trunc") }
    if $quiet { $args = ($args | append "--quiet") }
    if ($repository != null) { $args = ($args | append $repository) }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker logs" [
    container: string       # Container name or ID
    --details               # Show extra details provided to logs
    --follow (-f)           # Follow log output
    --since: string = ""    # Show logs since timestamp or relative (e.g. 42m)
    --tail (-n): string = ""    # Number of lines to show from end
    --timestamps (-t)       # Show timestamps
    --until: string = ""    # Show logs before a timestamp or relative
] {
    mut args = ["logs"]
    if $details { $args = ($args | append "--details") }
    if ($since | is-not-empty) { $args = ($args | append ["--since" $since]) }
    if ($tail | is-not-empty) { $args = ($args | append ["--tail" $tail]) }
    if $timestamps { $args = ($args | append "--timestamps") }
    if ($until | is-not-empty) { $args = ($args | append ["--until" $until]) }
    $args = ($args | append $container)

    if $follow {
        $args = ($args | append "--follow")
        run-external docker ...$args
    } else {
        let result = run-external docker ...$args | complete
        let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
        if ($raw | str trim | is-empty) { return [] }
        $raw
        | lines
        | enumerate
        | flatten
        | rename index line
    }
}

def "nudocker stats" [
    --all (-a)              # Show all containers, not just running
    --format: string = ""   # Format output using a Go template
    --no-trunc              # Do not truncate output
    container?: string      # Container name or ID
] {
    mut args = ["stats" "--no-stream"]
    if $all { $args = ($args | append "--all") }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if $no_trunc { $args = ($args | append "--no-trunc") }
    if ($container != null) { $args = ($args | append $container) }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker top" [
    container: string       # Container name or ID
] {
    mut args = ["top" $container]

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker events" [
    --filter (-f): string = ""  # Filter output based on conditions
    --format: string = ""       # Format output using a Go template
    --since: string = ""        # Show events created since timestamp
    --until: string = ""        # Stream events until this timestamp
] {
    mut args = ["events"]
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if ($since | is-not-empty) { $args = ($args | append ["--since" $since]) }
    if ($until | is-not-empty) { $args = ($args | append ["--until" $until]) }

    run-external docker ...$args
}

def "nudocker port" [
    container: string           # Container name or ID
    private_port?: string       # Private port with optional proto (e.g. 80/tcp)
] {
    mut args = ["port" $container]
    if ($private_port != null) { $args = ($args | append $private_port) }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | parse "{private_port} -> {public_addr}"
    | update private_port { str trim }
    | update public_addr { str trim }
}

def "nudocker version" [
    --format (-f): string = ""  # Format output using a Go template
] {
    mut args = ["version"]
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines
    | each {|line| $line | parse "{key}: {value}" }
    | flatten
    | update key { str trim }
    | update value { str trim }
}

def "nudocker info" [
    --format (-f): string = ""  # Format output using a Go template
] {
    mut args = ["info"]
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | lines
    | each {|line| $line | parse "{key}: {value}" }
    | flatten
    | update key { str trim }
    | update value { str trim }
}

def "nudocker history" [
    image: string               # Image name or ID
    --format: string = ""       # Format output using a Go template
    --human (-H)                # Print sizes and dates in human readable format
    --no-trunc                  # Don't truncate output
    --quiet (-q)                # Only show image IDs
] {
    mut args = ["history"]
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if $human { $args = ($args | append "--human") }
    if $no_trunc { $args = ($args | append "--no-trunc") }
    if $quiet { $args = ($args | append "--quiet") }
    $args = ($args | append $image)

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker inspect" [
    target: string              # Name or ID of the object to inspect
    --format (-f): string = ""  # Format output using a Go template
    --size (-s)                 # Display total file sizes for containers
    --type: string = ""         # Only inspect objects of the given type
] {
    mut args = ["inspect"]
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    if $size { $args = ($args | append "--size") }
    if ($type | is-not-empty) { $args = ($args | append ["--type" $type]) }
    $args = ($args | append $target)

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | from json
}

def "nudocker diff" [
    container: string           # Container name or ID
] {
    mut args = ["diff" $container]

    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | parse "{change_type} {path}"
    | update change_type { str trim }
    | update path { str trim }
}
