param(
    [string]$Repo = "dragon43ppp/docugen-markdown-docx",
    [string]$OutputDir = "data/github-metrics"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

$repoApiPath = "/repos/$Repo"
$snapshotLocal = Get-Date
$snapshotDate = $snapshotLocal.ToString("yyyy-MM-dd")
$snapshotTime = $snapshotLocal.ToString("yyyy-MM-dd HH:mm:ss")
$snapshotDir = Join-Path $OutputDir "snapshots"
$summaryPath = Join-Path $OutputDir "weekly-summary.csv"
$snapshotPath = Join-Path $snapshotDir "$snapshotDate.json"

New-Item -ItemType Directory -Force -Path $snapshotDir | Out-Null

$repoInfo = gh api $repoApiPath | ConvertFrom-Json
$views = gh api "$repoApiPath/traffic/views" | ConvertFrom-Json
$clones = gh api "$repoApiPath/traffic/clones" | ConvertFrom-Json

$stargazers = @(
    gh api -H "Accept: application/vnd.github.star+json" "$repoApiPath/stargazers?per_page=100" --paginate |
    ConvertFrom-Json
)

$last7DaysUtc = (Get-Date).ToUniversalTime().Date.AddDays(-7)
$starsLast7Days = @($stargazers | Where-Object { $_.starred_at -and ([datetime]$_.starred_at) -ge $last7DaysUtc }).Count

$previousStarsTotal = $null
$existingRows = @()
if (Test-Path -LiteralPath $summaryPath) {
    $existingRows = @(Import-Csv -LiteralPath $summaryPath)
    if ($existingRows.Count -gt 0) {
        $previousRow = $existingRows | Select-Object -Last 1
        if ($previousRow.stars_total) {
            $previousStarsTotal = [int]$previousRow.stars_total
        }
    }
    $existingRows = @($existingRows | Where-Object { $_.snapshot_date_local -ne $snapshotDate })
}

$starsSinceLastSnapshot = ""
if ($null -ne $previousStarsTotal) {
    $starsSinceLastSnapshot = [int]$repoInfo.stargazers_count - $previousStarsTotal
}

$summaryRow = [PSCustomObject]@{
    snapshot_date_local        = $snapshotDate
    snapshot_time_local        = $snapshotTime
    repo                       = $Repo
    traffic_window_start_utc   = if ($views.views.Count -gt 0) { $views.views[0].timestamp } else { "" }
    traffic_window_end_utc     = if ($views.views.Count -gt 0) { $views.views[-1].timestamp } else { "" }
    views_14d_total            = $views.count
    views_14d_uniques          = $views.uniques
    clones_14d_total           = $clones.count
    clones_14d_uniques         = $clones.uniques
    stars_total                = $repoInfo.stargazers_count
    stars_last_7d              = $starsLast7Days
    stars_since_last_snapshot  = $starsSinceLastSnapshot
    watchers_total             = $repoInfo.subscribers_count
    forks_total                = $repoInfo.forks_count
    open_issues_total          = $repoInfo.open_issues_count
}

$rawSnapshot = [PSCustomObject]@{
    snapshot = [PSCustomObject]@{
        repo                = $Repo
        snapshot_date_local = $snapshotDate
        snapshot_time_local = $snapshotTime
    }
    summary  = $summaryRow
    repoInfo = $repoInfo
    views    = $views
    clones   = $clones
    stargazers = $stargazers
}

$rawSnapshot | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $snapshotPath -Encoding utf8

$allRows = @($existingRows + $summaryRow)
$allRows | Export-Csv -LiteralPath $summaryPath -NoTypeInformation -Encoding utf8

Write-Output "Saved summary: $summaryPath"
Write-Output "Saved snapshot: $snapshotPath"
Write-Output ($summaryRow | ConvertTo-Json -Compress)
