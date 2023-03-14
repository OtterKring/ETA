$ModuleHash = @{
    Path = "$PSScriptRoot/../ETA.psd1"
    RootModule = "$PSScriptRoot/../ETA.psm1"
    Author = 'Maximilian Otter'
    ModuleVersion = '0.0.0.1'
    Description = 'Contains a class and wrapper functions to provide end time estimation for loops, e.g. in Write-Progress'
    FunctionsToExport = [regex]::Matches( ( get-content .\Tests\ETA.Tests.ps1 ) , '(?<=\$ExpectedFunctions = @\().*?(?=\))').Value -split "'\s+'" -replace "(\s+)?'(\s+)?"
    PowerShellVersion = "5.1"
    Guid = 'bbfe4155-7bd2-46ac-a258-0b11cb8053c5'
    Tags= @(
        'eta'
        'write-progress'
        'progress'
        'estimate'
     )
     LicenseUri = 'https://github.com/OtterKring/ETA/blob/main/LICENSE'
     ProjectUri = 'https://github.com/OtterKring/ETA'
}

if ( Test-Path $ModuleHash.Path ) {
    Update-ModuleManifest @ModuleHash
} else {
    New-ModuleManifest @ModuleHash
}