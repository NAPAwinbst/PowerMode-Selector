
<#
.SYNOPSIS
    Sets the Windows 11 Power Mode default: Plugged in (AC) = Best Performance,
    On battery (DC) = Balanced.
 
.DESCRIPTION
    Writes the two machine-wide REG_SZ overlay values that back Settings >
    System > Power & battery > Power Mode. Windows auto-switches between them
    when the device is plugged in or unplugged.
 
    Deploy as an Intune Platform Script (Devices > Scripts and remediations >
    Platform scripts) so it runs ONCE per device. It is not a Remediation, so
    it does not re-assert on a schedule — users remain free to change the mode
    in Settings afterward.
 
    Applies at next sign-in / reboot / power-source change (no forced live apply).
 
.NOTES
    Run using logged-on credentials : No  (runs as SYSTEM)
    Run in 64-bit PowerShell host   : Yes
    Assignment                      : All Devices (covers future enrollments)
#>
 
$RegPath  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes'
$AcValue  = 'ded574b5-45a0-4f42-8737-46345c09c238'   # Plugged in -> Best Performance
$DcValue  = '00000000-0000-0000-0000-000000000000'   # On battery -> Balanced (default)
 
$LogDir   = 'C:\ProgramData\IntunePowerMode'
$LogFile  = Join-Path $LogDir 'Set-PowerMode.log'
 
function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    try { Add-Content -Path $LogFile -Value $line -ErrorAction Stop } catch { }
}
 
try {
    if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
 
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
        Write-Log "Created missing key: $RegPath"
    }
 
    New-ItemProperty -Path $RegPath -Name 'ActiveOverlayAcPowerScheme' -Value $AcValue -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'ActiveOverlayDcPowerScheme' -Value $DcValue -PropertyType String -Force | Out-Null
 
    # Verify
    $ac = (Get-ItemProperty -Path $RegPath -Name 'ActiveOverlayAcPowerScheme').ActiveOverlayAcPowerScheme
    $dc = (Get-ItemProperty -Path $RegPath -Name 'ActiveOverlayDcPowerScheme').ActiveOverlayDcPowerScheme
 
    if ($ac -eq $AcValue -and $dc -eq $DcValue) {
        Write-Log "Success: AC=Best Performance, DC=Balanced (takes effect at next sign-in/reboot/power change)."
        exit 0
    }
    else {
        Write-Log "Verification mismatch. AC='$ac' DC='$dc'"
        exit 1
    }
}
catch {
    Write-Log "Failed: $($_.Exception.Message)"
    exit 1
}
