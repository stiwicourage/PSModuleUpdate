function Get-CiLaneOperatingSystem {
    if ($IsWindows) {
        return 'Windows'
    }
    if ($IsMacOS) {
        return 'macOS'
    }

    return 'Linux'
}

function Get-CiLaneEnvironment {
    [CmdletBinding()]
    param()

    $runtime = [System.Runtime.InteropServices.RuntimeInformation]
    return [pscustomobject][ordered]@{
        OperatingSystem = Get-CiLaneOperatingSystem
        OsArchitecture = $runtime::OSArchitecture.ToString()
        ProcessArchitecture = $runtime::ProcessArchitecture.ToString()
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        PowerShellEdition = $PSVersionTable.PSEdition
        RunnerOs = $env:RUNNER_OS
        RunnerArch = $env:RUNNER_ARCH
        RunnerEnvironment = $env:RUNNER_ENVIRONMENT
        ImageOs = $env:ImageOS
        ImageVersion = $env:ImageVersion
    }
}

function Get-CiEqualityMismatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Label,
        [AllowNull()]$Actual,
        [Parameter(Mandatory)]$Expected
    )

    if ($Actual -ne $Expected) {
        "$Label is '$Actual' but the lane expects '$Expected'."
    }
}

function Get-CiChannelMismatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Channel,
        [Parameter(Mandatory)][string]$Version
    )

    if ($Channel -match '^\d+\.\d+$' -and -not $Version.StartsWith("$Channel.")) {
        "PowerShell version '$Version' is not in the requested '$Channel' channel."
    }
}

function Get-CiRunnerMismatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$Actual
    )

    if ($Actual.RunnerOs) {
        Get-CiEqualityMismatch -Label 'RUNNER_OS' -Actual $Actual.RunnerOs -Expected $Expected.OperatingSystem
    }
    if ($Actual.RunnerArch) {
        Get-CiEqualityMismatch -Label 'RUNNER_ARCH' -Actual $Actual.RunnerArch -Expected $Expected.Architecture
    }
}

function Test-CiLaneEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$Actual,
        [switch]$RequireGitHubHosted
    )

    Get-CiEqualityMismatch -Label 'Operating system' -Actual $Actual.OperatingSystem -Expected $Expected.OperatingSystem
    Get-CiEqualityMismatch -Label 'OS architecture' -Actual $Actual.OsArchitecture -Expected $Expected.Architecture
    Get-CiEqualityMismatch -Label 'Process architecture' -Actual $Actual.ProcessArchitecture -Expected $Expected.Architecture
    Get-CiEqualityMismatch -Label 'PowerShell version' -Actual $Actual.PowerShellVersion -Expected $Expected.PowerShellVersion
    Get-CiChannelMismatch -Channel $Expected.PowerShellChannel -Version $Actual.PowerShellVersion
    Get-CiRunnerMismatch -Expected $Expected -Actual $Actual
    if ($Actual.PowerShellEdition -ne 'Core') {
        "PowerShell edition is '$( $Actual.PowerShellEdition )' but 'Core' is required."
    }
    if ($RequireGitHubHosted -and $Actual.RunnerEnvironment -ne 'github-hosted') {
        "Runner environment is '$( $Actual.RunnerEnvironment )' but 'github-hosted' is required."
    }
}
