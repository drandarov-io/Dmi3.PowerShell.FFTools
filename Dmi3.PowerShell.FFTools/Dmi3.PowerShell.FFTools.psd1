@{
    Description =
@'
Module that provides short and consise utility functions for working with ffmpeg.
- https://github.com/drandarov-io/Dmi3.PowerShell.FFTools
'@

    RootModule           = 'Dmi3.PowerShell.FFTools.psm1'
    GUID                 = '7bfe1227-a660-4dda-8f53-5f4772fb7d53'

    ModuleVersion        = '0.1.4'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')

    Author               = 'Dmitrij Drandarov'
    CompanyName          = 'dmi3.io'
    Copyright            = '(c) 2024 Dmitrij Drandarov'



    RequiredModules      = @()
    RequiredAssemblies   = @()

    ScriptsToProcess     = @()
    TypesToProcess       = @()
    FormatsToProcess     = @()

    NestedModules        = @()

    FunctionsToExport    = @('Invoke-FFTools')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @('ff')
    DscResourcesToExport = @()

    ModuleList           = @()
    FileList             = @('Dmi3.PowerShell.FFTools.psm1', 'Dmi3.PowerShell.FFTools.psd1')

    PrivateData          = @{
        PSData = @{
            Tags       = @('ffmpeg', 'video', 'audio', 'subtitles', 'transcode')
            ProjectUri = 'https://github.com/drandarov-io/Dmi3.PowerShell.FFTools'
            LicenseUri = 'https://github.com/drandarov-io/Dmi3.PowerShell.FFTools/blob/master/LICENSE'
            IconUri    = 'https://raw.githubusercontent.com/drandarov-io/Dmi3.PowerShell.FFTools/master/assets/icon.png'
        }
    }
}
