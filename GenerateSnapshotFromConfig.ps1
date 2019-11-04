param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$PublicationName,
    [String]$PublicationDBName
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
'@      
    
     #------------------Subscriber------------------
    $PublisherName = CheckParam `
        -Name '$PublisherName' `
        -Value $PublisherName `
        -ConfigPath $XMLConfigSection.Replication.Publisher.PublisherName `
        -Required;
    $PublicationName = CheckParam `
        -Name '$PublicationName' `
        -Value $PublicationName `
        -ConfigPath $XMLConfigSection.Replication.Publisher.PublicationName `
        -Required;
    $PublicationDBName = CheckParam `
        -Name '$PublicationDBName' `
        -Value $PublicationDBName `
        -ConfigPath $XMLConfigSection.Replication.Publisher.PublicationDBName `
        -Required;
    
    #does server exists?
    Test-Server -ServerName $PublisherName
    
    #connection to publisher
    $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;   
    $PublisherConnection.Connect();
    
    $Publication = GetPublication -ServerConnection $PublisherConnection -PublicationName $PublicationName -PublicationDBName $PublicationDBName;
    
    #start snapshot agent job
    StartSnapshotGenerationAgentJob -TransPublication $Publication
}    
catch
{
    LogErrorObject $_;throw $_; 
}         