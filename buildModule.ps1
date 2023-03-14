param (
    [Parameter()]
    [string]
    $ModuleName = 'ETA',

    [Parameter()]
    [string]
    $SourcesPath = '.\Sources\*.ps1',

    [Parameter()]
    [string]
    $TargetPath = '.\',

    [Parameter()]
    [version]
    $Version,

    [Parameter()]
    [string]
    $Author = 'Maximilian Otter'
)

$OutputPath = @{
    Source = $TargetPath + $ModuleName + ".psm1"
    Manifest = $TargetPath + $ModuleName + ".psd1"
}

# always recreate source file from scratch
Out-File -Path $OutputPath.Source -Encoding utf8 -Force
Get-ChildItem $SourcesPath |
    Foreach-Object {
        Get-Content $_ -Raw | Add-Content -Path $OutputPath.Source
    }

# only create new manifest if there is none present
if ( Test-Path $OutputPath.Manifest ) {

    if ( $PSBoundParameters.ContainsKey('Version') ) {
        $ModuleVersion = $Version
    } else {
        $ModuleVersion = ( Get-Module $OutputPath.Manifest -ListAvailable ).Version
        $ModuleVersion = [version]( "{0}.{1}.{2}.{3}" -f $ModuleVersion.Major, $ModuleVersion.Minor, $ModuleVersion.Build, ( $ModuleVersion.Revision + 1 ) )
    }

    Update-ModuleManifest -Path $OutputPath.Manifest -ModuleVersion $ModuleVersion

} else {

    $ModuleVersion = if ( $PSBoundParameters.ContainsKey('Version') ) {
        $Version
    } else {
        '0.0.0.1'
    }

    New-ModuleManifest -Path $OutputPath.Manifest -Author $Author -RootModule $OutputPath.Source -ModuleVersion $ModuleVersion -Description 'Contains a class and wrapper functions to provide end time estimation for loops, e.g. in Write-Progress' -PowerShellVersion 5.1
}