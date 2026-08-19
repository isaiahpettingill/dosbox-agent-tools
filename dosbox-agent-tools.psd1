@{
    RootModule        = 'dosbox-agent-tools.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = '0f9a5c1e-4b2a-4f8d-9e6c-2d1a0b3c4d5e'
    Author            = 'isaiahpettingill'
    CompanyName       = 'isaiahpettingill'
    Copyright         = '(c) isaiahpettingill. All rights reserved.'
    Description       = 'Cross-platform PowerShell driver for the dosbox-automation HTTP REST API. Start/stop headless sessions, inject throttled keyboard input, read the screen, swap disk images, mount directories, record input, and capture video. Requires PowerShell 7 (pwsh); runs on Windows and Linux.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Start-DosboxSession',
        'Stop-DosboxSession',
        'Get-DosboxSession',
        'Connect-DosboxSession',
        'Get-DosboxStatus',
        'Get-DosboxProgramState',
        'Get-DosboxInfo',
        'Get-DosboxScreenText',
        'Get-DosboxFrameInfo',
        'Save-DosboxScreenshot',
        'Send-DosboxText',
        'Send-DosboxKey',
        'Send-DosboxSequence',
        'Invoke-DosboxCommand',
        'Set-DosboxDrive',
        'Mount-DosboxDirectory',
        'Lock-DosboxMounts',
        'Get-DosboxMountLock',
        'Wait-DosboxShell',
        'Wait-DosboxProgram',
        'Wait-DosboxScreenText',
        'Wait-DosboxScreenStable',
        'Wait-DosboxInputIdle',
        'Wait-DosboxPrompt',
        'Start-DosboxInputRecording',
        'Stop-DosboxInputRecording',
        'Get-DosboxInputRecordingStatus',
        'Start-DosboxVideoCapture',
        'Stop-DosboxVideoCapture',
        'Get-DosboxVideoCaptureStatus'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('dosbox', 'automation', 'emulation', 'dos')
        }
    }
}
