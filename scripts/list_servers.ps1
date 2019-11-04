param(
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.')
)


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
    
    #if server name or type passed in
    $Servers = GetObjectFromXML -XML $XMLConfigSection.Servers.Server -ObjectToGet $ServerName -ServerType $ServerType

    $Servers | select type, name -ft
