param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [String]$DistributorName,
    [String]$DistributionDBName,
    [String]$DistributorAdminEncryptedPassword,
    [String]$LogReaderAgentLogin,
    [String]$LogReaderEncryptedPassword,
    [String]$SnapshotAgentLogin,
    [String]$SnapshotAgentEncryptedPassword,
    [String]$VerifyPublicationDB
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
    [String]$PublisherName,                       Name of publisher
    [String]$DistributorName,                     Server for distributor
    [String]$DistributionDBName                    Distribution database.
    [String]$DistributorAdminEncryptedPassword,   Encrypted password for the distributor_admin
    [String]$LogReaderAgentLogin,                 Login used for logreader agent                      		   
    [String]$LogReaderEncryptedPassword,          Encrypted password for the logreader agent login
    [String]$SnapshotAgentLogin,                  Login used for snapshot agent
    [String]$SnapshotAgentEncryptedPassword,      Encrypted password for the snapshot agent logn
    [String]$PublicationName,                     *Name of publication
    [String]$PublicationDBName,                   Database for publication
    [Bool]$VerifyPublicationDB                    1 = verify publication database exists. 0 = do not do that
    [Switch]$Debug
'@      

    $PublicationCreated = CreatePublicationFromConfig `
        -Key $Key `
        -ConfigType $ConfigType `
        -Config $Config `
        -PublisherName $PublisherName `
        -PublicationName $PublicationName `
        -PublicationDBName $PublicationDBName `
        -DistributorName $DistributorName `
        -DistributionDBName $DistributionDBName `
        -DistributorAdminPassword $DistributorAdminPassword `
        -LogReaderAgentLogin $LogReaderAgentLogin `
        -LogReaderPassword $LogReaderPassword `
        -SnapshotAgentLogin $SnapshotAgentLogin `
        -SnapshotAgentPassword $SnapshotAgentPassword `
        -VerifyPublicationDB $VerifyPublicationDB
    
}
catch
{
    LogErrorObject $_;throw $_; 
}           