function Register-NativeRepository {
    param([object]$Operation)
    if ($Operation.RepositoryName -ieq 'PSGallery') {
        $null = PowerShellGet\Register-PSRepository -Default -ErrorAction Stop
        return
    }
    $parameters = Get-NativeRepositoryParameter $Operation
    $null = PowerShellGet\Register-PSRepository @parameters
}
