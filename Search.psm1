##############################################################################
# Copyright: (c) Björn Lindqvist 2013
# License  : BSD 3-Clause
#
# Install this script by putting the following in your
# Microsoft.Powershell_profile.ps1 file:
#
#     Import-Module 'C:\path\to\module\Search.psm1'
#
##############################################################################

function Out-ColorMatchInfo {
    <#
    .Synopsis
    	Highlights MatchInfo objects similar to the output from grep.
    .Description
	Highlights MatchInfo objects similar to the output from grep.
    #>
    #requires -version 2
    param ( 
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)] 
	[Microsoft.PowerShell.Commands.MatchInfo] $match
    )
    begin {}
    process { 
	function Get-RelativePath([string] $path) {
		$path = $path.Replace($pwd.Path, '')
		if ($path.StartsWith('\') -and (-not $path.StartsWith('\\'))) { 
			$path = $path.Substring(1) 
		}
		$path
	}

	function Write-PathAndLine($match) {
		Write-Host (Get-RelativePath $match.Path) -foregroundColor White -nonewline
		Write-Host ':' -foregroundColor Cyan -nonewline
		Write-Host $match.LineNumber -foregroundColor DarkYellow
	}

	function Write-HighlightedMatch($match) {
		$index = 0
		foreach ($m in $match.Matches) {
			Write-Host $match.Line.SubString($index, $m.Index - $index) -nonewline
			Write-Host $m.Value -ForegroundColor Red -nonewline
			$index = $m.Index + $m.Length
		}
		if ($index -lt $match.Line.Length) {
			Write-Host $match.Line.SubString($index) -nonewline
		}
		''
	}
	
	Write-PathAndLine $match

	$match.Context.DisplayPreContext

	Write-HighlightedMatch $match

	$match.Context.DisplayPostContext
	''
    }
    end {}
}

function Find-String {
    <#
    .Synopsis
	Searches text files by pattern and displays the results.
    .Description
	Searches text files by pattern and displays the results.
    .Notes
    Based on versions from
    http://weblogs.asp.net/whaggard/archive/2007/03/23/powershell-script-to-find-strings-and-highlight-them-in-the-output.aspx
    and from http://poshcode.org/426
    Makes use of Out-ColorMatchInfo found at http://poshcode.org/1095.
    #>

    #requires -version 2
    param ( 
        [Parameter(Mandatory=$true)] 
        [regex] $pattern,
        [string[]] $include = "*",
        [switch] $recurse = $true,
        [switch] $caseSensitive = $false,
        [string[]] $directoryExclude = "x{999}",
        [int[]] $context = 0
    )
    if ((-not $caseSensitive) -and (-not $pattern.Options -match "IgnoreCase")) {
        $pattern = New-Object regex $pattern.ToString(),@($pattern.Options,"IgnoreCase")
    }
    $allExclude = $directoryExclude -join "|"
    Get-ChildItem -recurse:$recurse -include:$include |
        where { $_.FullName -notmatch $allExclude } |
        Select-String -caseSensitive:$caseSensitive -pattern:$pattern -AllMatches -context $context | 
        Out-ColorMatchInfo
}
