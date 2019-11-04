param(
    [String]$Key = $(throw '$Key required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$ServerName = $(throw '$ServerName required.')
)

try
{
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname

    . $scriptpath\config\ArcheAgeSetupConfig.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_CommonModule -DisableNameChecking
    Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking

	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
    $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
    $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
    
    LogInfo "Checking for Server Aliases in config..."
    CreateServerAliasFromConfig -ServerName $ServerName -ConfigSection $XMLConfigSection.ServerAliases.ServerAlias
    
    LogInfo "Checking for Linked Servers in config..."
    CreateLinkedServerFromConfig -ServerName $ServerName -ConfigSection $XMLConfigSection.LinkedServers.LinkedServer -Key $Key
    
    LogInfo "Checking for Folders to Copy..."
    CopyFoldersFromConfig -ServerName $ServerName -ConfigSection $XMLConfigSection.CopyFolders.Folder
    
    LogInfo "Checking for Server Scripts..."
    RunScriptsFromConfig -ServerName $ServerName -ConfigSection $XMLConfigSection.Scripts.Script
}
catch
{
    if (Get-Module | ?{$_.Name -eq 'LogFunctions'}) {LogErrorObject $_;throw $_} else {throw $_;}
}



