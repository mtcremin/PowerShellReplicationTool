param(
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$ServerName,
    [String]$DatabaseName,
    [String]$ServerType,
    [String]$ListOfArticles = $(throw '$ListOfArticles required.')
)

try
{
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname

    . $scriptpath\config\ReplicationConfig.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_CommonModule -DisableNameChecking
    Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
    Import-Module $GLOBAL:_ReplicationModule -DisableNameChecking
    
    CheckArgs -TheseArgs $Args

    $ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
    $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
    $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
	#if server name or type passed in
    $Servers = GetObjectFromXML -XML $XMLConfigSection.Servers.Server -ObjectToGet $ServerName -ServerType $ServerType
    
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

            $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $Server.Name;   
            $PublisherConnection.Connect();

            #if database name passed in select that database
            $Databases = GetObjectFromXML -XML $DatabaseConfig.Databases.Database -ObjectToGet $DatabaseName
            
            foreach($Database in $Databases)
            {
                LogInfo "Config found for database $($Database.Name)."
                if ($Database.Replication)
                {
                    $Publication = GetPublication `
                        -ServerConnection $PublisherConnection `
                        -PublicationName $Database.Replication.Publisher.PublicationName `
                        -PublicationDBName $Database.Name;
                    
                    LogInfo "Publication: $($Database.Replication.Publisher.PublicationName)"
                    
                    ForEach($Subscriber in $Database.Replication.Subscribers.Subscriber)
                    {
                        LogInfo "Subscriber: $($Subscriber.SubscriberName):$($Subscriber.SubscriptionDBName)"
                        ForEach($Article in $ListOfArticles.Split(','))
                        {
                            $Array = $Article.split('.')
                            
                            LogInfo "Article: $Article"

                            if ($Array.Length -eq 2)
                            {
                                $Schema = $Array[0].Trim()
                                $TableName = $Array[1].Trim()
                            } elseif ($Array.Length -eq 1)
                            {
                                $TableName = $Array[0].Trim()
                            } else
                            {
                                throw "Article can be in format: <schema>.<table> or <table>: $Article" 
                            }
                                                     
                            if($Publication.TransArticles | ?{$_.Name -eq $TableName})
                            {
                                #attempt to remove from subscription
                                try
                                {
                                    RemoveArticleFromSubscription `
                                        -PublisherName $Server.Name `
                                        -PublicationName $Database.Replication.Publisher.PublicationName `
                                        -PublicationDBName $Database.Name `
                                        -SubscriberName $Subscriber.SubscriberName `
                                        -SubscriptionDBName $Subscriber.SubscriptionDBName `
                                        -ArticleName $TableName
                                    
                                    LogInfo "$TableName unsubscribed"
                                }
                                catch
                                {
                                    LogInfo "$TableName not subscribed."
                                }

                                DeleteArticle `
                                    -ServerConnection $PublisherConnection `
                                    -PublicationName $Database.Replication.Publisher.PublicationName `
                                    -PublicationDBName $Database.Name `
                                    -ArticleName $TableName
                            }
                            else
                            {
                                LogInfo "$TableName not in publication $($Database.Replication.Publisher.PublicationName)"
                            }

                        }
                    }
                   
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



