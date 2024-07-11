<#
.SYNOPSIS
    A module for various FFmpeg tasks including subtitle syncing, extractopm, copy and transcode streams for compatibilty, counting streams, analysing audio and codecs and merging.

.DESCRIPTION
    This module provides a set of functions to perform various FFmpeg tasks.

.EXAMPLE
    Invoke-FFTools subsync 'movie.mkv' -Offset 2.5
    Synchronizes the subtitles in 'movie.mkv' by adding an offset of 2.5 seconds.

    Generates the following ffmpeg command:
    # TODO

.EXAMPLE
    Invoke-FFTools extract 'movie.mkv' -Video -Audio -Sub
    Extracts the video, audio, and subtitle streams from 'movie.mkv'.

    Generates the following ffmpeg command:
    # TODO

.EXAMPLE
    Invoke-FFTools merge 'movie1.mkv' -ExtraInputFiles 'audio.mka', 'movie2.mkv'
    Merges 'movie1.mkv', 'movie2.mkv', and 'audio.mkv' into a single file.

    Generates the following ffmpeg command:
    # TODO

.PARAMETER Command
    The command to execute. This parameter has the index 0 and is mandatory, so `-Command` can be omitted.

.PARAMETER InputFile
    The input file for the command. This parameter has the index 1 and is mandatory, so `-InputFile` can be omitted.

.PARAMETER Preview
    Show the FFmpeg command that will be executed and asks for confirmation before executing.

.PARAMETER Video
    Processes the video stream for certain commands. Alias: -v

.PARAMETER Audio
    Processes the audio stream for certain commands. Alias: -a

.PARAMETER Sub
    Processes the subtitle stream for certain commands. Alias: -s

.PARAMETER AudioMap
    Specifies the audio stream map for certain commands in ffmpeg syntax. Default is '0:a:0'.

.PARAMETER SubMap
    Specifies the subtitle stream map for certain commands in ffmpeg syntax. Default is '0:s:0'.

.PARAMETER NoPathFix
    Disable automatic path fixing for certain use-cases.

.PARAMETER Offset
    The offset for the subsync command. Can be a positive or negative double.

.PARAMETER SubFormat
    The subtitle format for the extract command.

.PARAMETER ExtraInputFiles
    Additional input files for the merge command.

.Notes
    Author: Dmitrij Drandarov
    Source: https://github.com/drandarov-io/Dmi3.PowerShell.FFTools
#>
function Invoke-FFTools {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet('subsync', 'extract', 'copytranscode', 'countstreams', 'codecs', 'audiomap', 'map', 'merge')]
        [string]$Command,

        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [string]$InputFile,


        ###############
        # Common
        [Alias('p')]
        [switch]$Preview,
        [Alias('v')]
        [switch]$Video,
        [Alias('a')]
        [switch]$Audio,
        [Alias('s')]
        [switch]$Sub,
        [string]$AudioMap = '0:a:0',
        [string]$SubMap = '0:s:0',
        [switch]$NoPathFix = $false,

        ###############
        # Subsync
        [Parameter(Mandatory=$true, Position=2, ParameterSetName='subsync')]
        [double]$Offset,

        ###############
        # Subextract
        [Parameter(Mandatory=$false, Position=3, ParameterSetName='extract')]
        [ValidateSet('srt', 'ass')]
        [string]$SubFormat = 'srt',

        ###############
        # Merge
        [Parameter(Mandatory=$true, Position=2, ParameterSetName='merge')]
        [string[]]$ExtraInputFiles
    )

    process {
        filter ext        { [IO.Path]::ChangeExtension($_ ? $_ : $args[0], $_ ? $args[0] : $args[1]) }
        filter suffix     { ($_ ? $_ : $args[0]) -replace '\.[^.]+$', "$($_ ? $args[0] : $args[1])$&" }
        function mergeobj { $obj1, $prop1, $obj2, $prop2 = $args; $obj1 | ForEach-Object { $p = $_; $obj2 | Where-Object { $p.$prop1 -eq $_.$prop2 } } }

        # ffmpeg requires literal paths, also this script uses single quotes so they need to be escaped as ''
        if (-not $NoPathFix) {
            if (-not (Test-Path -LiteralPath $InputFile)) {
                $InputFile = Resolve-Path -Relative $InputFile -ErrorAction SilentlyContinue # Convert to literal path
                if (-not $InputFile) { Write-Error "File is not accessible or does not exist."; return }
                Write-Host "Converted Path: $InputFile"
            }
            $InputFile = $InputFile.Replace("'", "''")
        }

        $vas = (!$Video -and !$Audio -and !$Sub)

        # TODO: Try to replace Command strings with actual commands that get translated into strings
        # TODO Proper object output
        switch ($Command) {
            'subsync' {
                if ($Offset -eq 0 ) { Write-Error "subsync -Offset [double] is mandatory and must not be 0"; return }
                $newSubtitleFile = suffix $InputFile ('.' + (($Offset -gt 0) ? "+$Offset" : "$Offset"))
                $ffmpegCommand = "ffmpeg -y -itsoffset $Offset -i '$InputFile' '$newSubtitleFile'"
            }

            'extract' {
                $ffmpegCommand += ($Video -or $vas) ? "ffmpeg -y -i '$InputFile' -map 0:v:0 -c copy '$(suffix $InputFile .ext)';" : ""
                $ffmpegCommand += ($Audio -or $vas) ? "ffmpeg -y -i '$InputFile' -map $AudioMap -c copy '$(ext $InputFile mka)';" : ""
                $ffmpegCommand += ($Sub -or $vas)   ? "ffmpeg -y -i '$InputFile' -map $SubMap -c copy '$(ext $InputFile $SubFormat)'" : ""
            }

            'copytranscode' {
                $audioIndex = ff countstreams -a $InputFile -NoPathFix
                if ($null -eq $audioIndex) { exit }
                $ffmpegCommand = "ffmpeg -i '$InputFile' -map 0 -c copy -map $AudioMap -c:a:$audioIndex libvorbis -metadata:s:a:$audioIndex title='Vorbis (Compatibility)' '$(suffix $InputFile _VORBIS)'"
            }

            'countstreams' {
                $vCount = ($Video -or $vas) ? (Invoke-Expression "ffprobe -v error -select_streams v -show_entries stream=index -of json=c=1 '$InputFile' | ConvertFrom-Json | Select-Object -Expand streams | Measure-Object | %{`$_.Count}") : 0
                $aCount = ($Audio -or $vas) ? (Invoke-Expression "ffprobe -v error -select_streams a -show_entries stream=index -of json=c=1 '$InputFile' | ConvertFrom-Json | Select-Object -Expand streams | Measure-Object | %{`$_.Count}") : 0
                $sCount = ($Sub -or $vas)   ? (Invoke-Expression "ffprobe -v error -select_streams s -show_entries stream=index -of json=c=1 '$InputFile' | ConvertFrom-Json | Select-Object -Expand streams | Measure-Object | %{`$_.Count}") : 0
                $ffmpegCommand = "$vCount + $aCount + $sCount"
            }

            'codecs' {
                $vCodecs = ($Video -or $vas) ? "Video:`t" + (Invoke-Expression "ffprobe -v error -select_streams v -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '$InputFile'") + "`n" : ""
                $aCodecs = ($Audio -or $vas) ? "Audio:`t" + (Invoke-Expression "ffprobe -v error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '$InputFile'") + "`n" : ""
                $sCodecs = ($Sub -or $vas)   ? "Subs:`t"  + (Invoke-Expression "ffprobe -v error -select_streams s -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '$InputFile'") + "`n" : ""
                $ffmpegCommand = "Write-Host -NoNewline '$vCodecs'; Write-Host -NoNewline '$aCodecs'; Write-Host -NoNewline '$sCodecs'"
            }

            'audiomap' {
                $i = 0
                $ffmpegCommand = "ffprobe -v error -select_streams a -show_entries stream=index,codec_name,bit_rate,channels:stream_tags=title,language -of json=c=1 '$InputFile' | ConvertFrom-Json | Select-Object -Expand streams |
                    Add-Member -Pass 'file_name' '$InputFile' | ForEach-Object {Add-Member -Pass -InputObject `$_ 'audio_index' ('0:a:' + `$i++)}"
                # TODO (lfr -Filter '*.mkv' | ff audiomap)[0] should return all audio streams and not only one
            }

            'map' {
                $vMap = ($Video -or $vas) ? "Video:`t" + (Invoke-Expression "ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 '$InputFile'") + "`n" : ""
                $aMap = ($Audio -or $vas) ? "Audio:`t" + (Invoke-Expression "ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 '$InputFile'") + "`n" : ""
                $sMap = ($Sub -or $vas)   ? "Subs:`t"  + (Invoke-Expression "ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 '$InputFile'") + "`n" : ""
                $ffmpegCommand = "Write-Host -NoNewline '$vMap'; Write-Host -NoNewline '$aMap'; Write-Host -NoNewline '$sMap'"
            }

            'merge' {
                $i = 0
                (,$InputFile + $ExtraInputFiles) | ForEach-Object { $ffmpegCommand += " -i '$_'" }
                (,$InputFile + $ExtraInputFiles) | ForEach-Object { $ffmpegCommand += (" -map " + $i++) }
                $ffmpegCommand = "ffmpeg -y$ffmpegCommand -c copy '$(suffix $InputFile _merged)'"
            }

            default {
                Write-Host "Unknown command: $Command"; return
            }
        }

        if ($Preview) {
            Write-Host $ffmpegCommand
        }
        if (!$Preview -or (Read-Host "Execute? (Y/n)") -match '^[Yy]?$') {
            Invoke-Expression $ffmpegCommand
        }
    }
}

Set-Alias -Name ff -Value Invoke-FFTools
