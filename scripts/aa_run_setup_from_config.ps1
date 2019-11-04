param(
    [String]$Key = $(throw '$Key required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$ServerName,
    [String]$DatabaseName,
    [Switch]$ServerSetup,
    [Switch]$DatabaseSetup,
    [Switch]$ReplicationSetup,
    [Switch]$AgentSetup,
    [String]$Branch,
    [String]$Action,
    [String]$ServerType,
    [Switch]$Verbose,
    [Switch]$Debug
)
try
{
    $scriptpath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
    $scriptparent = (Get-Item $scriptpath).parent.fullname
    $sqlserverroot = (Get-Item $scriptparent).parent.fullname

    . $scriptpath\config\ArcheAgeSetupConfig.ps1
    Import-Module $GLOBAL:_LogModule -DisableNameChecking
    Import-Module $GLOBAL:_CommonModule -DisableNameChecking
    Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking

    $GLOBAL:Debug = $Debug
    $BranchVariable = $GLOBAL:_BranchVariable

    CheckArgs -TheseArgs $Args

	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
    $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
    $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
    #if server name or type passed in
    $Servers = GetObjectFromXML -XML $XMLConfigSection.Servers.Server -ObjectToGet $ServerName -ServerType $ServerType
    
    foreach ($Server in $Servers)
    {
        if (!$Server.Name) {continue};
        
        LogInfo "Server: $($Server.Name)"
        Test-Server $Server.Name
        
        if($ServerSetup)
        {
            LogDebug "Checking for ServerConfig..."
            if ($Server.ServerConfig)
            {
                LogInfo "Calling aa_setup_game_server.ps1"
                & $scriptpath\aa_setup_game_server.ps1 `
                    -ServerName $Server.Name `
                    -ConfigType $Server.ServerConfig `
                    -Config $Config `
                    -Key $key
            }
            else
            {
                LogDebug "None found.  Move along."
            };
        } 
        else {LogDebug "Skipping server setup"} #ServerSetup         


        LogDebug "Checking for DatabaseConfig $($Server.DatabaseConfig)..."
        if ($Server.DatabaseConfig)
        {
            $DatabaseConfig = GetXMLConfigSection -XML $XMLConfig -ConfigType $Server.DatabaseConfig
        
            #if database name passed in select that database
            $Databases = GetObjectFromXML -XML $DatabaseConfig.Databases.Database -ObjectToGet $DatabaseName
            
            foreach ($Database in $Databases)
            {
                if ($DatabaseSetup)
                {
                    LogInfo "Database: $($Database.Name)"
                    if(!(Test-DB $Server.Name $Database.Name))
                    {
                        if ($Database.Config -and $Database.ConfigType)
                        {
                            #not calling scripts from db setup anymore. Have to pass -Action
                            $SkipScripts = $True
                        #LogInfo "Database: $($Database.Name)"
                            LogDebug "Calling twn_setup_gamedb.ps1"
                            & $scriptpath\twn_setup_gamedb.ps1 `
                                -i $Server.Name `
                                -pfx $Database.Name `
                                -config $Database.Config `
                                -sc $Database.ConfigType `
                                -key $Key `
                                -nocaps `
                                -SkipScripts:$SkipScripts
                        }
                        else
                        {
                            LogWarning "Could not find Config or ConfigType in config file.  Skipping"
                        }                                
                    }
                    else
                    {
                        LogDebug "Database $($Database.Name) already exists on $($Server.Name).  Only running security."
                        if ($Database.Config -and $Database.ConfigType)
                        {
                            LogDebug "Calling twn_channel_securitysetup.ps1"
                            & $scriptpath\twn_channel_securitysetup.ps1 `
                                -i $Server.Name `
                                -dbname $Database.Name `
                                -config $Database.Config `
                                -sc $Database.ConfigType `
                                -key $Key `
                                -SkipScripts
                        }
                        else
                        {
                            LogDebug "No Database Config section - continue..."
                        }                                
                    };
                } #DatabaseSetup
                else {LogDebug "Skipping database setup"}                    
            } #foreach

            #run any updates (and run scripts on repl dbs)
            foreach ($Database in $Databases)
            {
                if ($Action -and $Database.Scripts)
                {
                    #run sql scripts
                    LogInfo "Database: $($Database.Name)"
                    if (!(Test-DB $Server.Name $Database.Name)) {throw "Database $($Database.Name) does not exist"}
                    
                    if (!$Branch)
                    {
                        throw 'Missing $Branch parameter'
                    }

                    if ($Database.Scripts.Contains($BranchVariable))
                    {
                        $UpdateSQLScriptPath = $scriptpath + "\sqlscripts\" + $Database.Scripts.Replace($BranchVariable,$Branch) +"\Releases"
                    }
                    else
                    {
                        throw "Database.Scripts does not contain branch variable: $BranchVariable"
                    }

                    LogDebug "Running database update scripts..." 
                    if (Test-Path $UpdateSQLScriptPath)
                    {
                        & $scriptparent\DBUpdateTool\DatabaseUpdate.ps1 `
                            -ServerName $Server.Name `
                            -DatabaseName $Database.Name `
                            -DeployDir $UpdateSQLScriptPath `
                            -Action $Action `
                            -VerifySchemaMigrations:$True `
                            -Verbose:$Verbose
                    }
                    else
                    {
                         throw "Scripts directory not found: $UpdateSQLScriptPath"
                    }
                }
                else
                {
                    LogWarning "No Scripts Defined."
                }
            };#end run any updates
            
            foreach ($Database in $Databases)
            {
                LogDebug "Checking for replication..."
                if ($Database.Replication.Config -and $Database.Replication.Type)
                {
                    if ($ReplicationSetup)
                    {
                        foreach($Subscriber in $Database.Replication.Subscribers.Subscriber)
                        {
                            LogDebug "Subscriber: $($Subscriber.SubscriberName)."
                            LogDebug "Calling twn_repl_create_replication_from_config.ps1"

                            $PostSnapshotScriptsFolder = $scriptpath + "\sqlscripts\" + $Database.Replication.Publication.PostSnapshotScriptsFolder

                            & $scriptpath\twn_repl_create_replication_from_config.ps1 `
                                -Key $Key `
                                -Config $Database.Replication.Config `
                                -ConfigType $Database.Replication.Type `
                                -PublisherName $Server.Name `
                                -PublicationDBName $Database.Name `
                                -PublicationName $Database.Replication.Publisher.PublicationName `
                                -SubscriberName $Subscriber.SubscriberName `
                                -SubscriptionDBName $Subscriber.SubscriptionDBName `
                                -DistributorName $Database.Replication.Distributor.DistributorName `
                                -DistributionDBName $Database.Replication.Distributor.DistributionDBName `
                                -PostSnapshotScriptsFolder $Database.Replication.Publication.PostSnapshotScriptsFolder;
                                
                        }; #foreach
                    } #ReplicationSetup
                    else {LogDebug "Skipping replication setup"}                    
                } #If replication config
            }#foreach database
        } #if database config
        else
        {
            LogDebug "None found.  Move along."
        };
        
        if ($AgentSetup)
        {
            LogDebug "Checking for agent config..."
            if ($Server.AgentConfig)
            {
                $AgentSetupConfig = GetXMLConfigSection -XML $XMLConfig -ConfigType $Server.AgentConfig
                
                if (!$AgentSetupConfig) {throw "$($Server.AgentConfig) is not a valid type in the $config file."}
                
                LogDebug "Checking for Scripts..."
                RunScriptsFromConfig -ServerName $ServerName -ConfigSection $AgentSetupConfig.Scripts.Script 
            }
            else
            {
                LogDebug "None found.  Move along."
            };
        }
        else {LogDebug "Skipping agent setup"} #Agent            
    }
                           
}
catch
{
    if (Get-Module | ?{$_.Name -eq 'LogFunctions'}) {LogErrorObject $_;throw $_} else {throw $_;}
}



