param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [String]$SubscriberName,
    [String]$SubscriptionDBName,
    [String]$SubscriberWindowsAuthentication,
    [String]$SubscriberSQLLogin,
    [String]$SubscriberSQLPasswordEncrypted,
    [String]$VerifySubscriptionDB,
    [String]$CreateSubscriptionDB
)
try
{
    $HelpMsg = @'
    All parameters are required.  A config file can be used.  An * indicates the parameters that must be passed on the command line.
     
    [String]$Key,							      *Key to decrypt passwords
    [String]$ConfigType                           *Config type to use, e.g. dal,ams,dev,blah, etc.
    [String]$Config,                              *Path to the config file
    [String]$PublisherName                        Name of Publisher
    [String]$PublicationName,                     Name of publication
    [String]$PublicationDBName,                   Database for publication
    [String]$SubscriberName,                      Server for the subscriber
    [String]$SubscriptionDBName,                  Database on subscriber for subscription database
    [Bool]$SubscriberWindowsAuthentication,		  1 = windows auth. 0 = sql login.
    [String]$SubscriberSQLLogin,				  Login used by distributor agent connect to the subscriber
    [String]$SubscriberSQLPasswordEncrypted,	  Encrypted password for distributor agent
    [String]$VerifySubscriptionDB                   1 = verify subscription database exists.  this uses windows auth, so if it is across domains it will fail.  0 = do not do that
    [String]$CreateSubscriptionDB                 1 = create subscription db. this uses windows auth, so if it is across domains it will fail.  0 = do not do that
'@      
    
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname
    
    . $scriptpath\config\ReplicationVariables.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_ReplicationModule -DisableNameChecking

    $SubscriptionCreated = CreateSubscriptionFromConfig `
        -Key $Key `
        -ConfigType $ConfigType `
        -Config $Config `
        -PublisherName $PublisherName `
        -PublicationName $PublicationName `
        -PublicationDBName $PublicationDBName `
        -SubscriberName $SubscriberName `
        -SubscriptionDBName $SubscriptionDBName `
        -SubscriberWindowsAuthentication $SubscriberWindowsAuthentication `
        -SubscriberSQLLogin $SubscriberSQLLogin `
        -SubscriberSQLPasswordEncrypted $SubscriberSQLPasswordEncrypted `
        -VerifySubscriptionDB $VerifySubscriptionDB `
        -CreateSubscriptionDB $CreateSubscriptionDB 
   
}
catch
{
    if ($SubscriberConnection) {$SubscriberConnection.Disconnect()};
    if ($PublisherConnection) {$PublisherConnection.Disconnect()};

    if (Get-Module | ?{$_.Name -eq 'LogFunctions'}) {LogErrorObject $_;throw $_} else {throw $_;}
}    