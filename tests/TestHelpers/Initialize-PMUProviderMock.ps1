function Initialize-PMUProviderMock {
    Mock Find-ProviderResource {
        $script:repositoryFixture.Calls.Add([pscustomobject]@{ Kind = 'Find'; Repository = $Request.Repository; Credential = $Credential })
        [pscustomobject]@{ Name = $Request.Name; Version = [version]'2.0.0'; Prerelease = 'preview.2'; AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' }; Dependencies = @() }
    }
    Mock Save-ProviderResource {
        $script:repositoryFixture.Calls.Add([pscustomobject]@{ Kind = 'Save'; Repository = (Get-OperationRepositoryName $Operation); Credential = $Operation.Credential })
        $null = Initialize-PMUTestPackage $Operation.StageRoot $Operation.Plan.TargetVersion $Operation.Plan.ModuleGuid $Operation.Plan.ModuleName
    }
    Mock Install-ProviderResource {
        $script:repositoryFixture.Calls.Add([pscustomobject]@{ Kind = 'Install'; Repository = (Get-OperationRepositoryName $Operation); Credential = $Operation.Credential })
        Invoke-PMUFixtureInstallation $Operation
    }
}
