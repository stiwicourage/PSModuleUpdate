function Assert-NativeWorkerGo {
    param([IO.TextReader]$Reader)
    if ($Reader.ReadLine() -cne 'GO') {
        Write-PMUError 'PMU.PlanStale' 'The native worker did not receive an explicit live handoff.'
    }
}
