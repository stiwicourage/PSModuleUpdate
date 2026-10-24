@{
    Severity = @('Error', 'Warning', 'ParseError')
    # Host output is intentional in this PowerShell 7.4+ project.
    ExcludeRules = @('PSAvoidUsingWriteHost')
}
