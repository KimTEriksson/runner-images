function Install-ChocoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageName,
        [string[]] $ArgumentList,
        [int] $RetryCount = 5
    )

    process {
        $count = 1
        while ($true) {
            Write-Host "Running [#$count]: choco install $packageName -y $argumentList"
            choco install $packageName -y @argumentList --no-progress

            $pkg = choco list --localonly $packageName --exact --all --limitoutput
            if ($pkg) {
                Write-Host "Package installed: $pkg"
                break
            } else {
                $count++
                if ($count -ge $retryCount) {
                    Write-Host "Could not install $packageName after $count attempts"
                    exit 1
                }
                Start-Sleep -Seconds 30
            }
        }
    }
}

function Resolve-ChocoPackageVersion {
    param(
        [Parameter(Mandatory)]
        [string] $PackageName,
        [Parameter(Mandatory)]
        [string] $TargetVersion
    )

    $versionNumbers = $TargetVersion.Split(".")
    [int]$versionNumbers[-1] += 1
    $incrementedVersion = $versionNumbers -join "."
    $filterQuery = "`$filter=(Id eq '$PackageName') and (IsPrerelease eq false) and (Version ge '$TargetVersion') and (Version lt '$incrementedVersion')"
    $latestVersion = (Invoke-RestMethod "https://community.chocolatey.org/api/v2/Packages()?$filterQuery").properties.Version |
        Where-Object { $_ -Like "$TargetVersion.*" -or $_ -eq $TargetVersion } |
        Sort-Object { [version]$_ } |
        Select-Object -Last 1

    return $latestVersion
}
