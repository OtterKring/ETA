#region CLASSES

class ETA {

    # holds the time until completion
    [timespan] $Value = [timespan]0

    # when the Start() method was called. Will be used for calculating the average time between triggers and so the expected time until completion ($Value)
    [datetime] $StartTime = [datetime]0
    # when the Stop() method was called. Currently no further use.
    [datetime] $EndTime = [datetime]0
    # the average time between triggers, will be updated after every trigger.
    [timespan] $TriggerAverageTime
    # percentage of triggers received compared to the initially set trigger limit. To be used e.g. for Write-Progress -PercentCompleted
    [UInt32] $PercentCompleted = 0

    # the amount of triggers to be expected. This value is obligatory to be set either with the constructor or with the Start() method.
    # There is no way to calculate the expected time to completion without this.
    hidden [uint32] $TriggerLimit = 0
    # time of the latest trigger
    hidden [datetime] $CurrentTrigger = [datetime]0
    # time of the trigger before the current one
    hidden [datetime] $PreviousTrigger = [datetime]0
    # amount of triggers received
    hidden [UInt32] $TriggerCount = 0
    # a status flag to avoid time comparison
    hidden [bool] $Running = $false


    ETA ( [uint32] $TriggerLimit ) {
        $this.TriggerLimit = $TriggerLimit
    }

    [void] Trigger () {

        $this.TriggerCount++
        $this.PreviousTrigger = $this.CurrentTrigger
        $this.CurrentTrigger = [datetime]::Now

        # the first trigger starts the process
        # there is the opportunity, though to call the hidden Start() method manually,
        # so it could be, we don't have to do it for some reason.
        if ( -not $this.Running ) {
            # Start() must not be called after Stop()
            if ( $this.EndTime -le $this.StartTime ) {
                $this.Start( $this.CurrentTrigger )
            } else {
                Throw 'ETA instance was stopped or reached the maximum trigger count and cannot be triggered again. Reinitialize to reuse.'
            }
        }

        # no point in calculating any average before we received at least 2 triggers.
        # And even then we must use one trigger less for the division to get the correct value,
        # because we do not divide by the amount of triggers, but by the amount of gaps between triggers.
        if ( $this.TriggerCount -gt 1 ) {
            $this.TriggerAverageTime = [timespan]::FromTicks( ( $this.CurrentTrigger.Ticks - $this.StartTime.Ticks ) / ( $this.TriggerCount - 1 ) )
            $this.Value = ( $this.TriggerLimit - $this.TriggerCount ) * $this.TriggerAverageTime
        }

        $this.PercentCompleted = [math]::Round( $this.TriggerCount * 100 / $this.TriggerLimit, 0, 1 )

        if ( $this.TriggerLimit -eq $this.TriggerCount ) {
            $this.Stop()
        }

    }

    hidden [void] Start () {
        $this.Start( [datetime]::Now )
    }

    hidden [void] Start ( [datetime] $StartTime ) {
        if ( -not $this.Running ) {
            $this.Running = $true
            $this.StartTime = $StartTime
        } else {
            Throw "ETA instance was already started and cannot be started again."
        }
    }

    hidden [void] Stop () {
        if ( $this.Running ) {
            $this.EndTime = [datetime]::Now
            $this.PercentCompleted = 100
            $this.Running = $false
        } else {
            Throw "ETA instance was already stopped and cannot be stopped again"
        }
    }

    hidden [string] formatTimeSpan ( [timespan]$TS ) {

        $Output = switch ( $TS ) {
            { $_.Days }     { return "{0} d {1} h {2} m {3} s" -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds; break }
            { $_.Hours }    { return "{0} h {1} m {2} s" -f $_.Hours, $_.Minutes, $_.Seconds; break }
            { $_.Minutes }  { return "{0} m {1} s" -f $_.Minutes, $_.Seconds; break }
            { $_.Seconds }  { return "{0} s" -f $_.Seconds; break }
            { $_.TotalMilliseconds} { return "{0:0} ms" -f $_.TotalMilliseconds; break }
            default         { return ' ' }
        }

        return $Output

    }

    hidden [string] ToString () {
        return $this.formatTimeSpan( $this.Value )
    }

}

#endregion CLASSES

#region WRAPPER_FUNCTIONS

<#
.SYNOPSIS
Returns a new instance of the ETA class

.DESCRIPTION
Returns a new instance of the ETA class

.PARAMETER MaximumEvents
Amount of events the ETA class should expect to happen

.EXAMPLE
$myETA = New-ETA -MaximumEvents 100

.NOTES
2023-03-08 ... initial version by Maximilian Otter
#>
function New-ETA {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change system state')]
    [OutputType([ETA])]
    param (
        [Parameter(Mandatory)]
        [uint32]
        $MaximumEvents
    )

    [ETA]::new( $MaximumEvents )
}

<#
.SYNOPSIS
raises a new event trigger in the ETA instance

.DESCRIPTION
raises a new event trigger in the ETA instance

.PARAMETER ETA
The variable holding the ETA instance to trigger

.EXAMPLE
Invoke-ETATrigger -ETA $myETA

.NOTES
2023-03-08 ... initial version by Maximilian Otter
#>
function Invoke-ETATrigger {
    param (
        [Parameter(Mandatory)]
        [ETA]
        $ETA
    )

    $ETA.Trigger()
}

<#
.SYNOPSIS
Returns the current completion state of the ETA instance

.DESCRIPTION
Returns the current completion state of the ETA instance (in whole number percent)

.PARAMETER ETA
The variable holding the ETA instance of which the completion state should be received

.EXAMPLE
Get-ETAProgress -ETA $myETA

.NOTES
2023-03-08 ... initial version by Maximilian Otter
#>
function Get-ETAProgress {
    [OutputType([UInt32])]
    param (
        [Parameter(Mandatory)]
        [ETA]
        $ETA
    )

    $ETA.PercentCompleted
}

<#
.SYNOPSIS
Returns the [timespan] estimated until the predefined trigger count should be reached.

.DESCRIPTION
Returns the [timespan] estimated until the predefined trigger count should be reached.

.PARAMETER ETA
The variable holding the ETA instance of which the estimated endtime should be returned.

.EXAMPLE
Get-ETA -ETA $myETA

.NOTES
2023-08-14 ... initial version by Maximilian Otter
#>
function Get-ETA {
    [OutputType([timespan])]
    param (
        [Parameter(Mandatory)]
        [ETA]
        $ETA
    )

    $ETA.Value
}

#endregion WRAPPER_FUNCTIONS

#region DEMO

if ( $MyInvocation.InvocationName -eq '&' ) {
    $Iterations = 11
    $Eta = [ETA]::new( $Iterations )
    $Progress = @{
        Id = 0
        Activity = "Demoing ETA time estimating class for {0} random intervals" -f ( $Iterations - 1 )
        Status = [string]$Eta
        PercentComplete = $Eta.PercentCompleted
    }
    Write-Progress @Progress
    foreach ( $i in 1..$Iterations ) {
        $Eta.Trigger()
        $Progress.Status = [string]$Eta
        $Progress.PercentComplete = $Eta.PercentCompleted
        Write-Progress @Progress
        Start-Sleep -Milliseconds ( Get-Random -Minimum 100 -Maximum 750 )
    }
    Write-Progress -Id $Progress.Id -Activity $Progress.Activity -Completed
}

#endregion DEMO