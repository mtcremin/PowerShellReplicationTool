param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    #distributor
    [String]$DistributorName,
    [String]$DistributionDBName,
    [String]$DistributorAdminEncryptedPassword,
    [String]$WorkingDirectory,
    [String]$VerifyDistributionDB,
    #publisher
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [String]$LogReaderAgentLogin,
    [String]$LogReaderEncryptedPassword,
    [String]$SnapshotAgentLogin,
    [String]$SnapshotAgentEncryptedPassword,
    [String]$VerifyPublicationDB,
    #subscriber
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
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname
    
     . $scriptpath\config\ReplicationVariables.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_CommonModule -DisableNameChecking
    Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
    Import-Module $GLOBAL:_ReplicationModule -DisableNameChecking

    $HelpMsg = @'
    All parameters are required.  A config file can be used.  An * indicates the parameters that must be passed on the command line.
     
    [String]$Key,							      *Key to decrypt passwords
    [String]$ConfigType                           *Config type to use, e.g. dal,ams,dev,blah, etc.
    [String]$Config,                              *Path to the config file,
    [Switch]$Debug
'@      
    CreateDistributorFromConfig -Key $Key -Config $Config -ConfigType $ConfigType -PublisherName $PublisherName -DistributorName $DistributorName -DistributionDBName $DistributionDBName;

    CreatePublicationFromConfig `
        -Key $Key `
        -Config $Config `
        -ConfigType $ConfigType `
        -PublisherName $PublisherName `
        -PublicationName $PublicationName `
        -PublicationDBName $PublicationDBName `
        -DistributorName $DistributorName `
        -DistributionDBName $DistributionDBName;
        
        
    $SubscriptionCreated = CreateSubscriptionFromConfig `
        -Key $Key `
        -Config $Config `
        -ConfigType $ConfigType `
        -PublisherName $PublisherName `
        -PublicationName $PublicationName `
        -PublicationDBName $PublicationDBName `
        -SubscriberName $SubscriberName `
        -SubscriptionDBName $SubscriptionDBName;
        
    if ($SubscriptionCreated)
    {
        StartSnapshotAgentJobFromConfig `
            -Key $Key `
            -Config $Config `
            -ConfigType $ConfigType `
            -PublisherName $PublisherName `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName;
		};  
}
catch
{
    if (Get-Module | ?{$_.Name -eq 'LogFunctions'}) {LogErrorObject $_;throw $_} else {throw $_;}
}       