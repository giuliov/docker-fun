$url = $env:TFS_URL
$token = $env:TFS_PAT
$pool = $env:TFS_POOL_NAME
$agentName = $env:TFS_AGENT_NAME
$dbPassword = $env:SA_PASSWORD

Write-Verbose -Verbose "Starting SQL Server Express"

.\start-sql.ps1 -sa_password $dbPassword -ACCEPT_EULA "Y" -Verbose

Write-Verbose -Verbose "Configuring agent $agentName for pool $pool"

.\config.cmd --unattended `
            --url $url  `
            --auth pat  `
            --token $token  `
            --pool $pool  `
            --agent $agentName  `
            --acceptteeeula `
            --replace

Write-Verbose -Verbose "Starting Pipeline agent"

.\run.cmd
