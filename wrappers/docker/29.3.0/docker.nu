def docker [
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
        run-external docker ...$rest
    }
}

def "docker ps" [
    --all (-a)              # Show all containers (default shows just running)
    --filter (-f): string = ""  # Filter output based on conditions provided
    --quiet (-q)            # Only display container IDs
] {
    mut args = ["ps"]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if $quiet { $args = ($args | append "--quiet") }
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "docker images" [
    --all (-a)              # Show all images (including intermediate)
    --filter (-f): string = ""  # Filter output based on conditions provided
    --quiet (-q)            # Only show image IDs
    repository?: string     # Repository[:tag] to filter
] {
    mut args = ["images"]
    if $all { $args = ($args | append "--all") }
    if ($filter | is-not-empty) { $args = ($args | append ["--filter" $filter]) }
    if $quiet { $args = ($args | append "--quiet") }
    if $repository != null { $args = ($args | append $repository) }
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "docker logs" [
    --follow (-f)           # Follow log output
    --tail (-n): string = ""  # Number of lines to show from end (default all)
    --timestamps (-t)       # Show timestamps
    --since: string = ""    # Show logs since timestamp or relative time (e.g. 42m)
    container: string       # Container name or ID
] {
    mut args = ["logs"]
    if $follow { $args = ($args | append "--follow") }
    if ($tail | is-not-empty) { $args = ($args | append ["--tail" $tail]) }
    if $timestamps { $args = ($args | append "--timestamps") }
    if ($since | is-not-empty) { $args = ($args | append ["--since" $since]) }
    $args = ($args | append $container)
    if $follow {
        run-external docker ...$args
    } else {
        let result = run-external docker ...$args | complete
        let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
        if ($raw | str trim | is-empty) { return [] }
        $raw | lines | enumerate | flatten | rename index line
    }
}

def "docker build" [
    --tag (-t): string = ""     # Name and optionally a tag (name:tag)
    --file (-f): string = ""    # Name of the Dockerfile
    --no-cache                  # Do not use cache when building the image
    --platform: string = ""     # Set target platform (e.g. linux/amd64)
    path: string                # Build context path
] {
    mut args = ["build"]
    if ($tag | is-not-empty) { $args = ($args | append ["--tag" $tag]) }
    if ($file | is-not-empty) { $args = ($args | append ["--file" $file]) }
    if $no-cache { $args = ($args | append "--no-cache") }
    if ($platform | is-not-empty) { $args = ($args | append ["--platform" $platform]) }
    $args = ($args | append $path)
    run-external docker ...$args
}

def "docker run" [
    --rm                        # Automatically remove container when it exits
    --detach (-d)               # Run container in background and print container ID
    --interactive (-i)          # Keep STDIN open even if not attached
    --tty (-t)                  # Allocate a pseudo-TTY
    --publish (-p): string = "" # Publish a container port to the host (host:container)
    --volume (-v): string = ""  # Bind mount a volume
    --name: string = ""         # Assign a name to the container
    --env (-e): string = ""     # Set environment variables
    --network: string = ""      # Connect container to a network
    image: string               # Image to run
] {
    mut args = ["run"]
    if $rm { $args = ($args | append "--rm") }
    if $detach { $args = ($args | append "--detach") }
    if $interactive { $args = ($args | append "--interactive") }
    if $tty { $args = ($args | append "--tty") }
    if ($publish | is-not-empty) { $args = ($args | append ["--publish" $publish]) }
    if ($volume | is-not-empty) { $args = ($args | append ["--volume" $volume]) }
    if ($name | is-not-empty) { $args = ($args | append ["--name" $name]) }
    if ($env | is-not-empty) { $args = ($args | append ["--env" $env]) }
    if ($network | is-not-empty) { $args = ($args | append ["--network" $network]) }
    $args = ($args | append $image)
    run-external docker ...$args
}

def "docker exec" [
    --interactive (-i)          # Keep STDIN open even if not attached
    --tty (-t)                  # Allocate a pseudo-TTY
    --detach (-d)               # Detached mode: run command in background
    --env (-e): string = ""     # Set environment variables
    container: string           # Container name or ID
] {
    mut args = ["exec"]
    if $interactive { $args = ($args | append "--interactive") }
    if $tty { $args = ($args | append "--tty") }
    if $detach { $args = ($args | append "--detach") }
    if ($env | is-not-empty) { $args = ($args | append ["--env" $env]) }
    $args = ($args | append $container)
    run-external docker ...$args
}

def "docker pull" [
    image: string               # Image to pull (name[:tag|@digest])
] {
    mut args = ["pull"]
    $args = ($args | append $image)
    run-external docker ...$args
}

def "docker push" [
    image: string               # Image to push (name[:tag])
] {
    mut args = ["push"]
    $args = ($args | append $image)
    run-external docker ...$args
}

def "docker rm" [
    --force (-f)                # Force removal of a running container
    --volumes (-v)              # Remove anonymous volumes associated with the container
    container: string           # Container name or ID
] {
    mut args = ["rm"]
    if $force { $args = ($args | append "--force") }
    if $volumes { $args = ($args | append "--volumes") }
    $args = ($args | append $container)
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "docker rmi" [
    --force (-f)                # Force removal of the image
    image: string               # Image name or ID
] {
    mut args = ["rmi"]
    if $force { $args = ($args | append "--force") }
    $args = ($args | append $image)
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw | lines | enumerate | flatten | rename index line
}

def "docker inspect" [
    name: string                # Container, image, volume, network, or task name or ID
] {
    mut args = ["inspect"]
    $args = ($args | append $name)
    run-external docker ...$args
}

def "docker stats --no-stream" [
    --all (-a)                  # Show all containers (default shows just running)
] {
    mut args = ["stats" "--no-stream"]
    if $all { $args = ($args | append "--all") }
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "docker network ls" [] {
    mut args = ["network" "ls"]
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "docker volume ls" [] {
    mut args = ["volume" "ls"]
    let result = run-external docker ...$args | complete
    let raw = ($result.stdout? | default "") + ($result.stderr? | default "")
    if ($raw | str trim | is-empty) { return [] }
    $raw
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "docker system prune" [
    --all (-a)                  # Remove all unused images not just dangling ones
    --force (-f)                # Do not prompt for confirmation
    --volumes                   # Prune anonymous volumes
] {
    mut args = ["system" "prune"]
    if $all { $args = ($args | append "--all") }
    if $force { $args = ($args | append "--force") }
    if $volumes { $args = ($args | append "--volumes") }
    run-external docker ...$args
}
