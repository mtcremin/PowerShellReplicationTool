param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$DistributorName,
    [String]$DistributionDBName,
    [String]$DistributorAdminEncryptedPassword,
    [String]$WorkingDirectory,
    [String]$VerifyDistributionDB,
    [String]$PublisherName
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
    [String]$DistributorName,                     Server for distributor (or localhost)
    [String]$DistributionDBName,                  Database for distributor
    [String]$DistributorAdminEncryptedPassword,   Encrypted password for the distributor_admin
    [String]$WorkingDirectory,                    Directory for snapshot
    [Bool]$VerifyDistributionDB                   1 = verify distribution database exists. 0 = don't do that
    [String]$PublisherName,                       Server for the publisher
    [String]$Debug 
'@      
   
    CreateDistributorFromConfig `
    -Key $Key `
    -Config $Database.Replication.Config `
    -ConfigType $Database.Replication.Type `
    -PublisherName $Server.Name `
    -DistributorName $DistributorName `
    -DistributionDBName $DistributionDBName `
    -DistributorAdminEncryptedPassword $DistributorAdminEncryptedPassword `
    -WorkingDirectory $WorkingDirectory `
    -VerifyDistributionDB $VerifyDistributionDB `
    -PublisherName $PublisherName
    
}
catch
{
     LogErrorObject $_;throw $_; 
}        