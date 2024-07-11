@{
    RootModule           = 'Dmi3.PowerShell.FFTools.psm1'
    GUID                 = '7bfe1227-a660-4dda-8f53-5f4772fb7d53'

    ModuleVersion        = '0.1.0.beta'
    CompatiblePSEditions = @('Core')

    Author               = 'Dmitrij Drandarov'
    CompanyName          = 'dmi3.io'
    Copyright            = '(c) 2024 Dmitrij Drandarov'

    Description          = 'Module that provides short and consise utility functions for working with ffmpeg.'

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
    FileList             = @()

    PrivateData          = @{
        PSData = @{
            Tags       = @('ffmpeg', 'video', 'audio', 'subtitles', 'transcode')
            ProjectUri = 'https://github.com/drandarov-io/Dmi3.PowerShellModules'
            LicenseUri = 'https://github.com/drandarov-io/Dmi3.PowerShellModules/blob/main/LICENSE'
            IconUri    = ''
        }
    }

    HelpInfoURI = ''
}
