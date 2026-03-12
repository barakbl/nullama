def "nudocker ps" [
    --all (-a)          # Show all containers
    --filter (-f): string = ""  # Filter condition
    --format: string = ""  # Pretty-print using a Go template
] {
    mut args = [ps]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if ($format | is-not-empty) { $args = ($args | append ["--format" $format]) }
    run-external docker ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker images" [
    --all (-a)          # Show all images
    --filter (-f): string = ""  # Filter condition
] {
    mut args = [images]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    run-external docker ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nudocker logs" [
    --follow (-f)       # Follow log output
    --tail (-n): string = ""  # Number of lines to show from end
    --timestamps (-t)   # Show timestamps
    --since: string = ""  # Show logs since timestamp or relative
    container: string   # Container name or ID
] {
    mut args = [logs]
    if $follow { $args = ($args | append "--follow") }
    if ($tail | is-not-empty) { $args = ($args | append ["--tail" $tail]) }
    if $timestamps { $args = ($args | append "--timestamps") }
    if ($since | is-not-empty) { $args = ($args | append ["--since" $since]) }
    $args = ($args | append $container)
    if $follow {
        run-external docker ...$args
    } else {
        let result = run-external docker ...$args | complete
        $result.stdout + $result.stderr
        | parse "{level}:{message}"
        | update level { str trim }
        | update message { str trim }
    }
}
