Import-Module "$PSScriptRoot/../ETA.psd1"

# number of iterations the loop will go through aka how many triggers ETA will receive
$Events = 10

# initiate ETA instance
$Eta = New-ETA -MaximumEvents $Events

# hashtable for splatting Write-Progress. "Events - 1" because we are measuring intervals between events.
$Progress = @{
    Id = 0
    Activity = "Demoing ETA time estimating class for {0} random intervals" -f ( $Events - 1 )
    Status = [string]$Eta
    PercentComplete = $Eta.PercentCompleted
}

# init Write-Progress
Write-Progress @Progress

foreach ( $i in 1..$Events ) {

    # send a trigger to $Eta
    Invoke-ETATrigger -ETA $Eta

    # make use of the overload ToString() method in $Eta
    $Progress.Status = [string]$Eta

    # get the PercentCompleted value for the Write-Progress PercentComplete property
    $Progress.PercentComplete = $Eta.PercentCompleted

    # update Write-Progress
    Write-Progress @Progress

    # random delay between triggers
    Start-Sleep -Milliseconds ( Get-Random -Minimum 100 -Maximum 1500 )

}

# final Write-Progress
Write-Progress -Id $Progress.Id -Activity $Progress.Activity -Completed