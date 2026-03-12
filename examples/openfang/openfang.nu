def "nuof agent list" [] {
    run-external openfang agent list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof agent new" [
    template?: string   # Template name (e.g. coder, assistant). Interactive if omitted
] {
    mut args = [agent new]
    if ($template | is-not-empty) { $args = ($args | append $template) }
    run-external openfang ...$args
}

def "nuof agent kill" [
    agent_id: string    # Agent ID (UUID)
] {
    run-external openfang agent kill $agent_id
}

def "nuof workflow list" [] {
    run-external openfang workflow list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof trigger list" [
    --agent-id: string = ""  # Filter by agent ID
] {
    mut args = [trigger list]
    if ($agent_id | is-not-empty) { $args = ($args | append ["--agent-id" $agent_id]) }
    run-external openfang ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof skill list" [] {
    run-external openfang skill list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof skill search" [
    query: string       # Search query
] {
    run-external openfang skill search $query
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof channel list" [] {
    run-external openfang channel list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof hand list" [] {
    run-external openfang hand list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof hand active" [] {
    run-external openfang hand active
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof config show" [] {
    run-external openfang config show
}

def "nuof config get" [
    key: string         # Dotted key path (e.g. default_model.provider)
] {
    run-external openfang config get $key
}

def "nuof status" [] {
    run-external openfang status
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof models list" [
    --provider: string = ""  # Filter by provider name
] {
    mut args = [models list]
    if ($provider | is-not-empty) { $args = ($args | append ["--provider" $provider]) }
    run-external openfang ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof models aliases" [] {
    run-external openfang models aliases
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof models providers" [] {
    run-external openfang models providers
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof gateway status" [] {
    run-external openfang gateway status
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof approvals list" [] {
    run-external openfang approvals list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof approvals approve" [
    id: string          # Approval request ID
] {
    run-external openfang approvals approve $id
}

def "nuof approvals reject" [
    id: string          # Approval request ID
] {
    run-external openfang approvals reject $id
}

def "nuof cron list" [] {
    run-external openfang cron list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof sessions" [
    agent?: string      # Agent name or ID to filter by
] {
    mut args = [sessions]
    if ($agent | is-not-empty) { $args = ($args | append $agent) }
    run-external openfang ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof logs" [
    --follow (-f)            # Follow log output in real time
    --lines: string = ""     # Number of lines to show
] {
    mut args = [logs]
    if $follow { $args = ($args | append "--follow") }
    if ($lines | is-not-empty) { $args = ($args | append ["--lines" $lines]) }
    if $follow {
        run-external openfang ...$args
    } else {
        let result = run-external openfang ...$args | complete
        $result.stdout + $result.stderr | lines | parse "{level}:{message}" | update message { str trim }
    }
}

def "nuof vault list" [] {
    run-external openfang vault list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof security status" [] {
    run-external openfang security status
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof security audit" [
    --limit: string = ""  # Maximum number of entries to show
] {
    mut args = [security audit]
    if ($limit | is-not-empty) { $args = ($args | append ["--limit" $limit]) }
    run-external openfang ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof memory list" [
    agent: string       # Agent name or ID
] {
    run-external openfang memory list $agent
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof devices list" [] {
    run-external openfang devices list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof webhooks list" [] {
    run-external openfang webhooks list
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof integrations" [
    query?: string      # Search query (lists all if omitted)
] {
    mut args = [integrations]
    if ($query | is-not-empty) { $args = ($args | append $query) }
    run-external openfang ...$args
    | detect columns --guess
    | rename -b {|it| $it | str downcase | str replace -a ' ' '_'}
}

def "nuof system info" [] {
    run-external openfang system info
}

def "nuof system version" [] {
    run-external openfang system version
}
