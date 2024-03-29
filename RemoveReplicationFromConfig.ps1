param(
    [String]$Key = $(throw '$Key required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$ServerName,
    [String]$DatabaseName,
    [Switch]$DisablePublishing,
    [Switch]$SubscriptionCleanup
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
    
    $ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
    $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
    $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
	#if server name passed in, select that server
    $Servers = GetObjectFromXML -XML $XMLConfigSection.Servers.Server -ObjectToGet $ServerName
    
    foreach ($Server in $Servers)
    {
        if (!$Server.Name) 
        {
        continue
        };
        LogInfo "Server: $($Server.Name)"
        Test-Server -ServerName $Server.Name
        
        LogInfo "Checking for DatabaseConfig..."
        if ($Server.DatabaseConfig)
        {
            $DatabaseConfig = GetXMLConfigSection -XML $XMLConfig -ConfigType $Server.DatabaseConfig

            #if database name passed in select that database
            $Databases = GetObjectFromXML -XML $DatabaseConfig.Databases.Database -ObjectToGet $DatabaseName
            
            foreach($Database in $Databases)
            {
                LogInfo "Config found for database $($Database.Name)."
                if ($Database.Replication)
                {
                    LogInfo "Replication section found."
                    foreach($Subscriber in $Database.Replication.Subscribers.Subscriber | ?{$_})
                    {  
                        RemoveSubscriptionFromConfig `
                            -Key $Key `
                            -Config $Database.Replication.Config `
                            -ConfigType $Database.Replication.Type `
                            -PublisherName $Server.Name `
                            -PublicationDBName $Database.Name `
                            -SubscriberName $Subscriber.SubscriberName `
                            -SubscriptionDBName $Subscriber.SubscriptionDBName `
                            -SubscriptionCleanup:$SubscriptionCleanup
                    };
               
                    RemovePublicationFromConfig `
                        -Key $Key `
                        -Config $Database.Replication.Config `
                        -ConfigType $Database.Replication.Type `
                        -PublisherName $Server.Name `
                        -PublicationName $PublicationName `
                        -PublicationDBName $Database.Name `
                        -DisablePublishing:$DisablePublishing
                    };
            };
            
            
        }
        else
        {
            LogInfo "None found.  Move along."
        };
        
       
    }
                           
}
catch
{
    LogErrorObject $_;throw $_; 
}  



