#
# git era versioning
#
# A simple and hassle free versioning approach for standalone self-contained applications
# using an incremental rollout strategy (CI/CD) without upstream dependencies.
#
#
# Fomat:
# <DaysElapsed>.<HoursElapsed><MinutesElapsed>.0[-<pre-release>[+<build>]],
#   where <pre-release> ::= canary | ci | rc
#   and <build> ::= <commitsSinceVersionSource>.<currentCommitHashShort>
#

# era of beginning can be static date ("2019-08-16T10:15:00") or date of inital commit
# -> might be configurable
$eraBeginning = Get-Date "2018-10-01"

# requires git 1.7.4.2+
$initialCommitHash = (git rev-list --max-parents=0 HEAD) | Out-String
$initialCommitHashShort = $initialCommitHash.Substring(0,7)
$initialCommitDate = (git show -s --format=%cI $initialCommitHashShort) | Get-Date

$currentCommitHash = (git rev-parse HEAD) | Out-String
$currentCommitHashShort = $currentCommitHash.Substring(0,7)
$currentCommitDate = (git show -s --format=%cI $currentCommitHashShort) | Get-Date

$timeSpan = New-TimeSpan -Start $eraBeginning -End $currentCommitDate

$semVerBase = "{0:dd}.{1:hhmm}.0" -f $timeSpan, $timeSpan

$commitsOnCurrentBranch = ((git rev-list --count HEAD) | Out-String).Trim()
Write-Output $commitsOnCurrentBranch

# master: F (aka. rtm), release: A (aka. rc), develop: 4 (aka. ci), topic: 0 (aka. canary)
$branchNibble = "4"
$hashUpperWord = $branchNibble + $currentCommitHashShort.Substring(0,3)
$hashLowerWord = $currentCommitHashShort.Substring(3,4)

$major = $semVerBase.Split(".")[0]
$minor = $semVerBase.Split(".")[1]
$build = [convert]::ToInt32($hashUpperWord, 16)
$revision = [convert]::ToInt32($hashLowerWord, 16)
$semVer = "{0}-canary+{1}.{2}" -f $semVerBase, $commitsOnCurrentBranch, $currentCommitHashShort

# NOTE: AssemblyVersion and FileVersion are not fully ascending, but to the same degree unique as the hash!
#       While the values for Major and Minor are ascending, the values for Build and Revision are composed
#       of a hash which might produce random results.
#       Nevertheless, since it is pretty unlikely to have multiple builds within the same minute,
#       we settle for it!
$assemblyVersion = "{0}.{1}.{2}.{3}" -f $major, $minor, $build, $revision
# FIXME: add 16bit overflow check for FileVersion (warning when -1y, error when -30d)
$fileVersion = $assemblyVersion

Write-Output "SemVerBase: $($SemVerBase)"
Write-Output "SemVer: $($SemVer)"
Write-Output "AssemblyVersion: $($assemblyVersion)"
Write-Output "FileVersion: $($FileVersion)"
