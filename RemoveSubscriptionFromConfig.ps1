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
    [Switch]$SubscriptionCleanup
)
try
{
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname
    
    . $scriptpath\config\ReplicationVariables.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_ReplicationModule -DisableNameChecking
 
    RemoveSubscriptionFromConfig `
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
        -SubscriberSQLPassword $SubscriberSQLPassword `
        -SubscriptionCleanup $SubscriptionCleanup;
}
catch
{
     LogErrorObject $_;throw $_; 
} 