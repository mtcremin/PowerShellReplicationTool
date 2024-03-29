param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [Switch]$DisablePublishing
)
try
{
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname
    
    . $scriptpath\config\ReplicationVariables.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_ReplicationModule -DisableNameChecking
    
    $HelpMsg = @'
    All parameters are required.  A config file can be used.  An * indicates the parameters that must be passed on the command line.
     
    [String]$Key,							      *Key to decrypt passwords
    [String]$ConfigType                           *Config type to use, e.g. dal,ams,dev,blah, etc.
    [String]$Config,                              *Path to the config file
    [String]$PublisherName,                       *Name of publisher
    [String]$PublicationName,                     Name of publication
    [String]$PublicationDBName,                   Database for publication
    [Switch]$Debug
'@      

    RemovePublicationFromConfig `
        -Key $Key `
        -Config $Database.Replication.Config `
        -ConfigType $Database.Replication.Type `
        -PublisherName $Server.Name `
        -PublicationName $PublicationName `
        -PublicationDBName $Database.Name `
        -DisablePublishing:$DisablePublishing
    
}
catch
{
    if (Get-Module | ?{$_.Name -eq 'LogFunctions'}) {LogErrorObject $_;throw $_} else {throw $_;}
}           