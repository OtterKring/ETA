BeforeAll {
    Import-Module "$PSScriptRoot/../ETA.psd1"
}

Describe 'Module' {

    BeforeAll {
        $ExpectedFunctions = @(
            'New-ETA'
            'Invoke-ETATrigger'
            'Get-ETAProgress'
            'Get-ETA'
        )
    }

    It "Should not contain more functions than expected" {
        $functions = Get-Command -Module ETA
        $functions.Count | Should -BeLessOrEqual $ExpectedFunctions.Count
    }

    It 'Should only include $ExpectedFunctions' {
        foreach ( $function in $functions ) {
            $function | Should -BeIn $ExpectedFunctions
        }
    }

}

Describe 'New-ETA' {

    It 'Should return ETA instance' {
        $myETA = New-ETA -MaximumEvents 1
        $myETA.GetType().Name | Should -Be 'ETA'
    }

}

Describe 'Invoke-ETATrigger' {

    BeforeAll {
        $myETA = New-ETA -MaximumEvents 3
    }

    It 'Should set StartTime on first run' {
        $myETA.StartTime | Should -Be ( [datetime]0 )
        Invoke-ETATrigger -ETA $myETA
        $myETA.StartTime | Should -Not -Be ( [datetime]0 )
    }

    It 'Should set CurrentTrigger' {
        $myETA.CurrentTrigger | Should -Not -Be ( [datetime]0 )
    }

    It 'Should NOT set TriggerAverageTime on first trigger' {
        $firstavg = $myETA.TriggerAverageTime
        $firstavg | Should -Be ( [timespan]0 )
    }

    It 'Should NOT set Value on first trigger' {
        $firstval = $myETA.Value
        $firstval | Should -Be ( [timespan]0 )
    }

    It 'Should set PreviousTrigger to CurrentTrigger after second trigger' {
        $tmp = $myETA.CurrentTrigger
        Invoke-ETATrigger -ETA $myETA
        $myETA.PreviousTrigger | Should -Be $tmp
    }

    It 'Should set TriggerAverageTime after second trigger' {
        $myETA.TriggerAverageTime | Should -Not -Be ( [timespan]0 )
        $myETA.TriggerAverageTime | Should -Not -Be $firstavg
    }

    It 'Should set Value after second trigger' {
        $myETA.Value | Should -Not -Be ( [timespan]0 )
        $myETA.Value | Should -Not -Be $firstval
    }

    It 'Should set EndTime when TriggerCount -eq TriggerLimit (MaximumEvents)' {
        while ( $myETA.TriggerCount -lt $myETA.TriggerLimit ) {
            Invoke-ETATrigger -ETA $myETA
        }
        $myETA.EndTime | Should -Not -Be ( [datetime]0 )
        $myETA.EndTime | Should -BeGreaterThan $myETA.StartTime
    }

}

Describe Get-ETAProgress {

    BeforeAll {
        $myETA = New-ETA -MaximumEvents 3
    }

    It 'Should show 0 progress after initializing' {
        $myETA.PercentCompleted | Should -Be 0
    }

    It 'Should have a PercentCompleted set after first Trigger' {
        Invoke-ETATrigger -ETA $myETA
        $myETA.PercentCompleted | Should -BeGreaterThan 0
    }

    It 'Should have a larger PercentCompleted value after second Trigger' {
        $prevperc = $myETA.PercentCompleted
        Invoke-ETATrigger -ETA $myETA
        $myETA.PercentCompleted | Should -BeGreaterThan $prevperc
    }

}

Describe Get-ETA {

    BeforeAll {
        $myETA = New-ETA -MaximumEvents 3
    }

    It 'Should show 0 after initializing' {
        $myETA.Value | Should -Be ([timespan]0)
    }

    It 'Should have a value greater 0 after second trigger' {
        Invoke-ETATrigger -ETA $myETA
        Start-Sleep -Seconds 1
        Invoke-ETATrigger -ETA $myETA
        $myETA.Value | Should -BeGreaterThan ([timespan]0)
    }

}