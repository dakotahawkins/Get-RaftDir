# Get-RaftDir

A utility to find the install path for the game [Raft](https://raft-game.com/).

## Example Usage

```PowerShell
Import-Module "RaftDir.psm1"

[System.IO.DirectoryInfo] $RaftDir = (Get-RaftDir)
```
