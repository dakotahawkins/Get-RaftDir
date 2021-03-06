# Get Raft's installation directory with Get-RaftDir.

using namespace System.Text.RegularExpressions

[System.IO.DirectoryInfo] $RaftDir = $null

Function Get-SteamAppsDir {
    # Find Steam's installation directory / library folder

    [OutputType([System.IO.DirectoryInfo])]
    Param()

    ForEach ($key in @("HKLM:\SOFTWARE\Wow6432Node", "HKLM:\SOFTWARE")) {
        [String] $SteamKey = "$key\Valve\Steam"
        If (Test-Path $SteamKey) {
            [System.IO.DirectoryInfo] $SteamDir = `
                [System.IO.Path]::Combine( `
                    (Get-ItemProperty -Path $SteamKey).InstallPath, "steamapps" `
                )
            If ($SteamDir.Exists) {
                Return $SteamDir
            }
        }
    }

    Throw [System.IO.DirectoryNotFoundException] "Could not find Steam apps directory."
}

Function Get-SteamLibraryPaths {
    # Find all of Steam's library paths

    [OutputType([System.IO.DirectoryInfo[]])]
    Param()

    [System.IO.DirectoryInfo] $SteamAppsDir = Get-SteamAppsDir
    [System.IO.DirectoryInfo[]] $SteamLibraryPaths = @($SteamAppsDir)

    # Find alternate library paths
    [System.IO.FileInfo] $LibraryFoldersFile = `
        [System.IO.Path]::Combine($SteamAppsDir, "libraryfolders.vdf")

    If ($LibraryFoldersFile.Exists) {
        (Get-Content $LibraryFoldersFile.FullName) | `
            Select-String '^\s*"\d+"\s+"([^"]+)"\s*$' -AllMatches | `
                ForEach-Object { $_.Matches } | `
                    ForEach-Object { [Regex]::Unescape($_.Groups[1].Value) } | `
                        Select-Object @{ `
                            Name = "SteamAppsDir"; `
                            Expression = { `
                                [System.IO.DirectoryInfo] `
                                    [System.IO.Path]::Combine($_, "steamapps") `
                            } `
                        } | `
                            Where-Object { $_.SteamAppsDir.Exists } | `
                                ForEach-Object { $SteamLibraryPaths += $_.SteamAppsDir }
    }

    Return $SteamLibraryPaths
}

Function Get-RaftDir {
    # Get Raft's installation directory

    [OutputType([System.IO.DirectoryInfo])]
    Param()

    If ($null -ne $script:RaftDir -And $script:RaftDir.Exists) {
        Return $script:RaftDir
    }

    ForEach ($SteamLibraryPath in Get-SteamLibraryPaths) {
        [System.IO.FileInfo] $RaftManifest = `
            [System.IO.Path]::Combine($SteamLibraryPath, "appmanifest_648800.acf")
        [System.IO.DirectoryInfo] $RaftDir = `
            [System.IO.Path]::Combine($SteamLibraryPath, "common", "Raft")
        If ($RaftManifest.Exists -And $RaftDir.Exists) {
            $script:RaftDir = $RaftDir
            Return $script:RaftDir
        }
    }

    Throw [System.IO.DirectoryNotFoundException] "Could not find Raft directory."
}

Export-ModuleMember -Function Get-RaftDir
