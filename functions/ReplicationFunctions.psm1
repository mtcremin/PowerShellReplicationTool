Import-Module $GLOBAL:_LogModule

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.RMO') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Replication') | Out-Null

function InstallDistributor {
param (
    [Microsoft.SqlServer.Replication.ReplicationServer]$ReplicationServer = $(throw '$ReplicationServer required.'),
    [Microsoft.SqlServer.Replication.DistributionDatabase]$DistributionDB = $(throw '$DistributionDB required.'),
    [String]$DistributorAdminPassword = $(throw '$DistributorAdminPassword required.')
)    
    try
    {    
        if ([string]::IsNullOrEmpty($DistributorAdminPassword)) {throw '$DistributionDBName required.'};
        $DistributorDatabaseExists = if ($ReplicationServer.EnumDistributionDatabases() | ?{$_.Name -eq $DistributionDB.Name} | %{$_.Name}) {$True} else {$False}
        
        if (!$ReplicationServer.IsDistributor -and !$ReplicationServer.DistributorInstalled)
        {
            LogInfo "Installing distributor on $($ReplicationServer.Name) with distribution database $($DistributionDB.Name)...";
            $ReplicationServer.InstallDistributor($DistributorAdminPassword, $DistributionDB);
            LogInfo "Distributor installed on $($ReplicationServer.Name) with distribution database $($DistributionDB.Name).";
        }
        else
        {
            LogInfo "Distributor is already installed on $($ReplicationServer.Name).";
            #if database name is different, create the distribution database
            if (!$DistributorDatabaseExists)
            {
                LogInfo "Creating distribution database $($DistributionDB.Name) on $($ReplicationServer.Name)...";
                $DistributionDB.Create()
                LogInfo "Distribution database $($DistributionDB.Name) created on $($ReplicationServer.Name).";
            }
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }        
};

function RegisterRemoteDistributorOnPublisher {
param (
    [Microsoft.SqlServer.Replication.ReplicationServer]$ReplicationServer = $(throw '$ReplicationServer required.'),
    [String]$DistributorName = $(throw '$DistributorName required.'),
    [String]$DistributorAdminPassword = $(throw '$DistributorAdminPassword required.')
)   
    try
    {    
        if ([string]::IsNullOrEmpty($ReplicationServer)) {throw '$ReplicationServer IsNullOrEmpty.'};
        if ([string]::IsNullOrEmpty($DistributorName)) {throw '$DistributorName IsNullOrEmpty.'};
        if ([string]::IsNullOrEmpty($DistributorAdminPassword)) {throw '$DistributorAdminPassword IsNullOrEmpty.'};
        
        LogInfo "Registering remote distributor $DistributorName on publisher $($ReplicationServer.Name)...";
        if (!$ReplicationServer.DistributorInstalled)
        {
            $ReplicationServer.InstallDistributor($DistributorName, $DistributorAdminPassword);
            LogInfo "Distributor $DistributorName registered on publisher $($ReplicationServer.Name).";
        }
        else
        {
            LogInfo "Distributor $DistributorName is already registered on publisher $($ReplicatioNServer.Name).";
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }        
};

function RegisterRemoteDistributor {
param (
    [Microsoft.SqlServer.Replication.ReplicationServer]$ReplicationServer = $(throw '$ReplicationServer required.'),
    [String]$DistributorName = $(throw '$DistributorName required.'),
    [string]$DistributorAdminPassword = $(throw '$DistributorAdminPassword required.')
)       
    try
    {
        if ([string]::IsNullOrEmpty($ReplicationServer)) {throw '$ReplicationServer required.'};
        if ([string]::IsNullOrEmpty($DistributorName)) {throw '$DistributorName required.'};
        if ([string]::IsNullOrEmpty($DistributorAdminPassword)) {throw '$DistributorAdminPassword required.'};
        LogInfo "Registering distributor on $($ReplicationServer.Name)...";
        $ReplicationServer.InstallDistributor($DistributorName, $DistributorAdminPassword) | out-null;
        LogInfo "Remote distributor installed on $($ReplicationServer.Name).";
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
}   

function UninstallDistributor {
param (
    [Microsoft.SqlServer.Replication.ReplicationServer]$Distributor = $(throw '$Distributor required.'),
    [Bool]$Force = $(throw '$Force required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($Distributor)) {throw '$Distributor required.'};
        if ([string]::IsNullOrEmpty($Force)) {throw '$Force required.'};
        if ($Distributor.LoadProperties())
        {
            if ($Distributor.IsDistributor)
            {
                LogInfo "Unistalling distributor $($Distributor.Name)...";
                $Distributor.UninstallDistributor($Force)
                LogInfo "Distributor $($Distributor.Name) uninstalled.";
            }
            else
            {
                LogInfo "Distributor not installed on $($Distributor.Name).";
            }                
        }    
        else
        {
            throw "Could not load properties for $($Distributor.Name)."
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }             

}

function RemovePublisherFromDistributor {
param (
    [Microsoft.SqlServer.Replication.DistributionPublisher]$DistributionPublisher = $(throw '$DistributionPublisher required.'),
    [Bool]$RemoteDistributor = $(throw '$RemoteDistributor required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($DistributionPublisher)) {throw '$DistributionPublisher required.'};
        if ([string]::IsNullOrEmpty($RemoteDistributor)) {throw '$RemoteDistributor required.'};
        if ($DistributionPublisher.IsExistingObject)
        {
            LogInfo "Removing publisher from distributor $($DistributionPublisher.Name)..."
            $DistributionPublisher.Remove($RemoteDistributor) | out-null;
            LogInfo "Publisher removed from distributor $($DistributionPublisher.Name)."
        }
        else
        {
            LogWarning "DistributionPublisher does not exist on $($DistributionPublisher.Name)."            
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
    
}

function GetDistributionPublisher {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.'),
    [string]$PublisherName = $(throw '$PublisherName required.')
)
    try
    {
    if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};
    if ([string]::IsNullOrEmpty($PublisherName)) {throw '$PublisherName required.'};
        New-Object “Microsoft.SqlServer.Replication.DistributionPublisher” $PublisherName,$ServerConnection;
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
    
}

function SetDistributionPublisher {
param (
    [Microsoft.SqlServer.Replication.DistributionPublishe]$DistributionPublisher = $(throw '$DistributionPublishe required.'),
    [string]$PublisherName = $(throw '$PublisherName required.'),
    [string]$DistributionDBName = $(throw '$DistributionDBName required.'),
    [string]$WorkingDirectory = $(throw '$WorkingDirectory required.')
)
#TODO
# Add repl parameters like MaxDistributionRetention
    try
    {
    if ([string]::IsNullOrEmpty($DistributionPublisher)) {throw '$DistributionPublisher required.'};
    if ([string]::IsNullOrEmpty($PublisherName)) {throw '$PublisherName required.'};
    if ([string]::IsNullOrEmpty($DistributionDBName)) {throw '$DistributionDBName required.'};
    if ([string]::IsNullOrEmpty($WorkingDirectory)) {throw '$WorkingDirectory required.'};
    
        if (!($DistributionPublisher.IsExistingObject))
        {
            $DistributionPublisher.DistributionDatabase = $DistributionDBName;
            $DistributionPublisher.WorkingDirectory = $WorkingDirectory;
            $DistributionPublisher.PublisherSecurity.WindowsAuthentication = $True;
        }
        else
        {
            LogWarning "Publisher $PublisherName already exists on $($DistributionPublisher.Name).";
        }  
        
        $DistributionPublisher;
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     

}

function CreateDistributionPublisher {
param (
    [Microsoft.SqlServer.Replication.DistributionPublisher]$DistributionPublisher = $(throw '$DistributionPublisher required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($DistributionPublisher)) {throw '$DistributionPublisher required.'};
        if (!($DistributionPublisher.IsExistingObject))
        {
            LogInfo "Creating distributor for publisher $($DistributionPublisher.Name)...";
            $DistributionPublisher.Create() | out-null;
            LogInfo "Distributor created for publisher $($DistributionPublisher.Name).";
        }
        else
        {
            LogInfo "Distributor already configured for Publisher $($DistributionPublisher.Name)";
        }   
        
        $DistributionPublisher
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     

};

function SetupWorkingDirectory {
param (
    [String]$ServerName = $(throw '$ServerName required.'),
    [String]$WorkingDirectory = $(throw '$WorkingDirectory required.'),
    [String]$UserName = $(throw '$UserName required.')
)
    try
    {
        if ($WorkingDirectory.Substring(0,2) -eq '\\') 
        {
            LogInfo "WorkingDirectory is a UNC Share - cannot configure security"
            return;
        }
        if ($env:COMPUTERNAME -ne $ServerName)
        {
            $WorkingDirectory = '\\' + $ServerName + '\' + $WorkingDirectory.Replace(':','$')
        };            
        
        if(!(test-path $WorkingDirectory))
        {
            LogInfo "Creating working directory $WorkingDirectory..."
            New-Item $WorkingDirectory -type directory | out-null
            LogInfo "Working directory $WorkingDirectory created" 
        };
        LogInfo "Setting directory permissions on $WorkingDirectory for $UserName..." 
        $Acl = Get-Acl $WorkingDirectory
        $Ar =  New-Object system.security.accesscontrol.filesystemaccessrule($UserName,"FullControl","ContainerInherit, ObjectInherit", "None", "Allow");
        $Acl.SetAccessRule($Ar)
        Set-Acl $WorkingDirectory $Acl
        LogInfo "Directory permissions set on $WorkingDirectory for $UserName." 
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };
};    

function RegisterPublisherOnDistributor {
param (
    [Microsoft.SqlServer.Replication.DistributionPublisher]$DistributionPublisher = $(throw '$DistributionPublisher required.'),
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$DistributionDBName = $(throw '$DistributionDBName required.'),
    [string]$WorkingDirectory = $(throw '$WorkingDirectory required.')
)       
    try
    {
        if ([string]::IsNullOrEmpty($PublisherName)) {throw '$PublisherName required.'}
        if ([string]::IsNullOrEmpty($DistributionDBName)) {throw '$PublisherName required.'}
        if ([string]::IsNullOrEmpty($WorkingDirectory)) {throw '$PublisherName required.'}
        
       
        
        if (!($DistributionPublisher.IsExistingObject))
        {
            $DistributionPublisher.DistributionDatabase = $DistributionDBName;
            $DistributionPublisher.WorkingDirectory = $WorkingDirectory;
            $DistributionPublisher.PublisherSecurity.WindowsAuthentication = $True;
          
            LogInfo "Creating publisher $PublisherName on Distributor $($ServerConnection.ServerInstance)...";
            $DistributionPublisher.Create() | out-null;
            LogInfo "Publisher $PublisherName created on Distributor $($ServerConnection.ServerInstance).";
            return $True
        }
        else
        {
            LogWarning "Publisher $PublisherName already exists on Distributor $($ServerConnection.ServerInstance).";
            return $False
            
        }        
        
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     

} 


function DropDistributrionDB {
param (
    [Microsoft.SqlServer.Replication.DistributionDatabase]$DistributionDB = $(throw '$DistributionDB required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($DistributionDB)) {throw '$DistributionDB required.'};
        if ($DistributionDB.LoadProperties())
        {
            LogInfo "Dropping distribution database $($DistributionDB.Name)..."
            $DistributionDB.Remove();
            LogInfo "Distribution database $($DistributionDB.Name) dropped."
        }
        else
        {
            throw "Cannot load properties on $($DistributionDB.Name).";
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }         
}

function GetReplicationDatabase {
param (
        [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnectionn required.'),
        [string]$PublicationDBName = $(throw '$PublicationDBName required.')
)       
    try
    {  
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        $PublicationDB = New-Object “Microsoft.SqlServer.Replication.ReplicationDatabase” $PublicationDBName, $ServerConnection;    
        
        if (!($PublicationDB.EnabledTransPublishing))
        {
            $PublicationDB.EnabledTransPublishing = $True;    
        }
        
        $PublicationDB
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }  
}

function GetPublicationDB {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnectionn required.'),
    [String]$PublicationDBName = $(throw '$PublicationDBName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        New-Object “Microsoft.SqlServer.Replication.ReplicationDatabase” $PublicationDBName, $ServerConnection;  
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};


function DisablePublishing {
param (
    [Microsoft.SqlServer.Replication.DistributionPublisher]$DistributionPublisher = $(throw '$DistrobutionPublisher required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($DistributionPublisher)) {throw '$DistributionPublisher required.'};       
        if($DistributionPublisher.LoadProperties())
        {
            LogInfo "Removing publisher $($DistributionPublisher.name)..."
            $DistributionPublisher.Remove($False);
            LogInfo "Publisher $($DistributionPublisher.name) removed."
        }
        else
        {
            throw "Cannot load properties on $($DistributionPublisher.name)."
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function RemoveTransPublication {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.'),
    [Switch]$DisablePublishing
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        
        $TransPublicationName = "$($TransPublication.DatabaseName):$($TransPublication.Name)";
        LogInfo "Deleting publication $TransPublicationName on server $($TransPublication.SqlServerName)..."
        
        if ($TransPublication.IsExistingObject) 
        {       
            if ($TransPublication.LoadProperties())
            {
                if($TransPublication.IsExistingObject)
                {
                    # Remove the transactional publication.
                    $TransPublication.Remove();
                    LogInfo "Publication $TransPublicationName deleted."
                }
                else
                {
                    LogWarning "Publication $TransPublicationName doesn't exists"
                }
            }
            else
            {
                throw "Could not load properties for $($TransPublication.DatabaseName):$($TransPublication.Name)."
            }
        }
        else
        {
            LogWarning "Publication $TransPublicationName does not exist."
        };
        
        if ($DisablePublishing)
        {
            LogInfo "Disabling publishing on database $($TransPublication.DatabaseName)..."
            $PublicationDB =  New-Object Microsoft.SqlServer.Replication.ReplicationDatabase($TransPublication.DatabaseName,$TransPublication.ConnectionContext)
            if ($PublicationDB.LoadProperties())
            {
                if ($PublicationDB.TransPublications.Count -eq 0)
                {
                    $PublicationDB.EnabledTransPublishing = $False
                    LogInfo "Publishing on datbase $($TransPublication.DatabaseName) disabled."
                }
                else
                {
                    LogInfo "$($TransPublication.DatabaseName) still has $($PublicationDB.TransPublications.Count) publications."
                }
            }
            else
            {
                throw "Could not load properties for $($PublicationDB.Name)"
            }
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function CreateLogReaderAgent {
param (
    [Microsoft.SqlServer.Replication.ReplicationDatabase]$PublicatioNDB = $(throw '$PublicatioNDB required.'),
    [String]$LogReaderAgentLogin = $(throw '$LogReaderAgentLogin required.'),
    [String]$LogReaderAgentPassword = $(throw '$LogReaderAgentPassword required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($PublicatioNDB)) {throw '$PublicatioNDB required.'};       
        if ([string]::IsNullOrEmpty($LogReaderAgentLogin)) {throw '$LogReaderAgentLogin required.'};       
        if ([string]::IsNullOrEmpty($LogReaderAgentPassword)) {throw '$LogReaderAgentPassword required.'};       
        if ($PublicationDB.LoadProperties)
        {
            if (!($PublicationDB.EnabledTransPublishing))
            {
                LogInfo "Enabling publishing on database $($PublicationDB.Name).";
                $PublicationDB.EnabledTransPublishing = $True;
                LogInfo "Publishing enabled on database $($PublicationDB.Name).";
            }
            else
            {
                LogInfo "Publishing already enabled on database $($PublicationDB.Name).";
            }
            if (!($PublicatioNDB.LogReaderAgentExists))
            {
                $PublicationDb.LogReaderAgentProcessSecurity.Login = $LogReaderAgentLogin;
                $PublicationDb.LogReaderAgentProcessSecurity.Password = $LogReaderAgentPassword;
                $PublicationDb.LogReaderAgentPublisherSecurity.WindowsAuthentication = $True;
                $PublicationDB.EnabledTransPublishing = $True;  
                
                LogInfo "Creating LogReader agent for publication database $($PublicationDB.Name)...";
                $PublicatioNDB.CreateLogReaderAgent() | out-null;
                LogInfo "LogReader agent created for publication database $($PublicationDB.Name).";
            }
            else
            {
                LogWarning "LogReader agent already exists for publication database $($PublicationDB.Name)."
            }
            
        }
        else
        {
            throw "Cannot load properties on PublicationDB $($PublicationDB.name)."
        }        
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};


function GetPublication {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnectionn required.'),
    [string]$PublicationName = $(throw '$PublicationName required.'),
    [string]$PublicationDBName = $(throw '$PublicationDBName required.')
)
    try
    {   
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        $TransPublication = New-Object "Microsoft.SqlServer.Replication.TransPublication";
        $TransPublication.Name = $PublicationName;
        $TransPublication.DatabaseName = $PublicationDBName;
        $TransPublication.ConnectionContext = $ServerConnection;
           
        $TransPublication;
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function SetPublicationSecurity {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$ServerConnectionn required.'),
    [String]$SnapshotAgentLogin = $(throw '$SnapshotAgentLogin required.'),
    [String]$SnapshotAgentPassword = $(throw '$SnapshotAgentPassword required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        if ([string]::IsNullOrEmpty($SnapshotAgentLogin)) {throw '$SnapshotAgentLogin required.'};       
        if ([string]::IsNullOrEmpty($SnapshotAgentPassword)) {throw '$SnapshotAgentPassword required.'};       
        
        $TransPublication.CreateSnapshotAgentByDefault=$True;
        $TransPublication.Attributes = $TransPublication.Attributes -bor [Microsoft.SqlServer.Replication.PublicationAttributes]::AllowPull
        $TransPublication.Attributes = $TransPublication.Attributes -bor [Microsoft.SqlServer.Replication.PublicationAttributes]::AllowPush
        $TransPublication.Attributes = $TransPublication.Attributes -bor [Microsoft.SqlServer.Replication.PublicationAttributes]::IndependentAgent
        $TransPublication.SnapshotGenerationAgentProcessSecurity.Login = $SnapshotAgentLogin;
        $TransPublication.SnapshotGenerationAgentProcessSecurity.Password = $SnapshotAgentPassword;
        $TransPublication.SnapshotGenerationAgentPublisherSecurity.WindowsAuthentication = $True;
        
        $TransPublication.Status = "Active";
        
        $TransPublication
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function CreateTransPublication {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        
        $TransPublicationName = "$($TransPublication.DatabaseName):$($TransPublication.Name)";
        LogInfo "Creating publication $TransPublicationName on server $($TransPublication.SqlServerName)...";
        
        if (!($TransPublication.IsExistingObject))
        {     
            $TransPublication.Create() | out-null;
            LogInfo "Publication $TransPublicationName created.";
            return $True;
        }
        else
        {
            LogWarning "Publication $TransPublicationName already exists."
            return $False;
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function GetTransactionPublication {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.')
)   
    try
    { 
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
    
        # Set the required properties for the transactional publication.
        $TransPublication = New-Object “Microsoft.SqlServer.Replication.TransPublication”;
        $TransPublication.ConnectionContext = $ServerConnection;
        
        $TransPublication
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};   

function SetTransactionPublication {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.'),
    [string]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [string]$PublicationName = $(throw '$PublicationName required.')
)   
    try
    { 
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
    
        # Set the required properties for the transactional publication.
        $TransPublication.Name = $PublicationName;
        $TransPublication.DatabaseName = $PublicationDBName
        
        $TransPublication
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};   

function AddArticles {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.'),
    [string]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [string]$PublicationName = $(throw '$PublicationName required.'),
    [System.Xml.XmlElement]$ArticleInfo = $(throw '$ArticleInfo required.'),
    [switch]$Verbose=$False
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
        #if ([string]::IsNullOrEmpty($Articles)) {throw '$Articles required.'};       
        #TODO: check for null xml
    
        $NumArticlesAdded = 0
        
        $PublisherSMOServer = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ServerConnection.ServerInstance
        $BadArticles = Test-Articles -SMOServer $PublisherSMOServer -DBName $PublicationDBName -ArticleInfo $ArticleInfo
        
        LogInfo "Creating Articles ($(switch($Verbose){$True{'Verbose'} $false{'Brief'}}))"
        foreach ($Article in $ArticleInfo.Articles.Article)
        {
            $Schema = $Article.Name.split('.')[0]
            $TableName = $Article.Name.split('.')[1]
            
            $NewArticle = new-object "Microsoft.SqlServer.Replication.TransArticle";
            $NewArticle.ConnectionContext = $ServerConnection;
            
            $NewArticle.Name = $TableName;
            $NewArticle.DatabaseName = $PublicationDBName;
            $NewArticle.SourceObjectName = $TableName;
            $NewArticle.SourceObjectOwner = $Schema;
            $NewArticle.PublicationName = $PublicationName;
            $NewArticle.Type = 'LogBased';

            
            if (!($NewArticle.IsExistingObject))
            {
                #set options on articles
                foreach ($ArticleOption in $ArticleInfo.ArticleOptions.Split(','))
                {
                    $NewArticle.SchemaOption = $NewArticle.SchemaOption -bor [Microsoft.SqlServer.Replication.CreationScriptOptions]::$ArticleOption
                };                
                
                #add columns for article.
                if ($Article.AddReplicatedColumns.Length -gt 0)
                {
                    $NewArticle.AddReplicatedColumns($Article.AddReplicatedColumns.Split(','));
                    if ($Verbose) {LogInfo "$TableName - Specifying article columns: $($Article.AddReplicatedColumns)."};
                };
                
                #remove columns for article.
                if ($Article.RemoveReplicatedColumns.Length -gt 0)
                {
                    $NewArticle.RemoveReplicatedColumns($Article.RemoveReplicatedColumns.Split(','));
                    if ($Verbose) {LogInfo "$TableName - Removing article columns: $($Article.RemoveReplicatedColumns)."};
                };
                
                #change the name of the DestinationObjectName?
                if ($Article.DestinationObjectOptions.PrefixType -eq 'database_name')
                {
                    $NewArticle.DestinationObjectName = $PublicationDBName + '_' + $TableName;
                    if ($Verbose) {LogInfo "$TableName - Renaming destination table name to: $($NewArticle.DestinationObjectName)."};
                }
                elseif ($Article.DestinationObjectOptions.SuffixType -eq 'database_name')
                {
                    $NewArticle.DestinationObjectName = $TableName + '_' + $PublicationDBName + '_';
                    if ($Verbose) {LogInfo "$TableName - Renaming destination table name to: $($NewArticle.DestinationObjectName)."};
                }
                else
                {
                    $NewArticle.DestinationObjectName = $TableName;
                    if ($Verbose) {LogInfo "$TableName - same as original object."};
                }
                ;
                
                #Set the names of the ins,del,upd stored procs
                $NewArticle.InsertCommand = "CALL sp_MSins_$($NewArticle.DestinationObjectName)";
                $NewArticle.DeleteCommand = "CALL sp_MSdel_$($NewArticle.DestinationObjectName)";
                $NewArticle.UpdateCommand = "SCALL sp_MSupd_$($NewArticle.DestinationObjectName)";
                    
                # Create the article.
                $NewArticle.Create() | out-null;
                if ($Verbose) {LogInfo "Article $($NewArticle.Name) created"};
                $NumArticlesAdded += 1
                #$NewArticle.CheckValidCreation()
            }
            else
            {
            if ($Verbose) {LogWarning "The article $($NewArticle.Name) already exists in publication $($PublicationName)."};
            }
        }  
        return $NumArticlesAdded        
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function RegisterSubscriber {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.'),
    [String]$SubscriberName = $(throw '$SubscriberName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        if ([string]::IsNullOrEmpty($SubscriberName)) {throw '$SubscriberName required.'};       
    
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};
        if ([string]::IsNullOrEmpty($SubscriberName)) {throw '$SubscriberName required.'};
        
        $Subscriber = new-object "Microsoft.SqlServer.Replication.RegisteredSubscriber" $SubscriberName, $ServerConnection;
        if (!($Subscriber.IsExistingObject))
        {
            LogInfo "Registering subscriber $SubscriberName on $($ServerConnection.ServerInstance )...";
            $Subscriber.Create() | out-null;
            LogInfo  "Subscriber $SubscriberName registered on $($ServerConnection.ServerInstance )...";
        }
        else
        {
            LogInfo "Subscriber $SubscriberName already registered on $($ServerConnection.ServerInstance )";
        }        
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function GetTransSubscription {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
    
        $TransSubscription = New-Object “Microsoft.SqlServer.Replication.TransSubscription”;
        $TransSubscription.ConnectionContext = $ServerConnection;
        
        $TransSubscription
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }  
};

function SetTransSubscription {
param (
    [Microsoft.SqlServer.Replication.TransSubscription]$TransSubscription = $(throw '$TransSubscription required.'),
    [string]$PublicationName = $(throw '$PublicationName required.'),
    [string]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [string]$SubscriberName = $(throw '$SubscriberName required.'),
    [string]$SubscriptionDBName = $(throw '$SubscriptionDBName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransSubscription)) {throw '$TransSubscription required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        if ([string]::IsNullOrEmpty($SubscriberName)) {throw '$SubscriberName required.'};
        if ([string]::IsNullOrEmpty($SubscriptionDBName)) {throw '$SubscriptionDBName required.'};       
    
        $TransSubscription.SubscriberName = $SubscriberName;
        $TransSubscription.PublicationName = $PublicationName;
        $TransSubscription.DatabaseName = $PublicationDBName;
        $TransSubscription.SubscriptionDBName = $SubscriptionDBName;
        
        $TransSubscription
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }  
};

function SetTransSubscriptionSecurity {
param (
    [Microsoft.SqlServer.Replication.TransSubscription]$TransSubscription = $(throw '$TransSubscription required.'),
    [String]$DistributionAgentLogin = $(throw '$DistributionAgentLogin required.'),
    [String]$DistributionAgentPassword = $(throw '$DistributionAgentPassword required.'),
    [Bool]$WindowsAuthentication = $True,
    [String]$SqlStandardLogin,
    [String]$SqlStandardPassword
)
    try
    {
        if ([string]::IsNullOrEmpty($TransSubscription)) {throw '$TransSubscription required.'};       
        #if ([string]::IsNullOrEmpty($DistributionAgentLogin)) {throw '$DistributionAgentLogin required.'};       
        #if ([string]::IsNullOrEmpty($DistributionAgentPassword)) {throw '$DistributionAgentPassword required.'};       
        #if ([string]::IsNullOrEmpty($WindowsAuthentication)) {throw '$WindowsAuthentication required.'};       
    
        if (!$WindowsAuthentication)
        {
            if (!($SqlStandardLogin -and $SqlStandardPassword)) {throw "Missing subscriber SQL login credentials."};
            $TransSubscription.SubscriberSecurity.SqlStandardLogin = $SqlStandardLogin
            $TransSubscription.SubscriberSecurity.SqlStandardPassword = $SqlStandardPassword
        };
        
        if ($DistributionAgentLogin) {$TransSubscription.SynchronizationAgentProcessSecurity.Login = $DistributionAgentLogin};
        if ($DistributionAgentPassword) {$TransSubscription.SynchronizationAgentProcessSecurity.Password = $DistributionAgentPassword};
        $TransSubscription.SubscriberSecurity.WindowsAuthentication = $WindowsAuthentication
        
            
        $TransSubscription
        
    }        
    catch
    {
        LogErrorObject $_;throw $_;
    }  
};

function CreateTransSubscription {
param (
    [Microsoft.SqlServer.Replication.TransSubscription]$TransSubscription = $(throw '$TransSubscription required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransSubscription)) {throw '$TransSubscription required.'};       
        
        $TransSubscription.LoadProperties() | out-null;
        
        $TranscriptionName = "$($TransSubscription.SubscriberName):$($TransSubscription.SubscriptionDBName)";
        LogInfo "Creating subscription $TranscriptionName on server $($TransSubscription.SqlServerName)...";

        if (!($TransSubscription.IsExistingObject))
        {
            $TransSubscription.Create() | out-null;
            LogInfo "Subscription $TranscriptionName created.";
            return $true;
        }
        else
        {
            LogWarning "Subscription $TranscriptionName already exists."
            return $false;
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};           

function RemoveTransSubscription {
param (
    [Microsoft.SqlServer.Replication.TransSubscription]$TransSubscription = $(throw '$TransSubscription required.')
)
    try
    {
        $TranscriptionName = "$($TransSubscription.SubscriberName):$($TransSubscription.SubscriptionDBName)";
        $TransPublicationName = "$($TransSubscription.DatabaseName):$($TransSubscription.PublicationName)";
        
        LogInfo "Deleting subscription $TranscriptionName from publication $TransPublicationName on server $($TransSubscription.SqlServerName)..."
        
        if ([string]::IsNullOrEmpty($TransSubscription)) {throw '$TransSubscription required.'};       
        if (!$TransSubscription.IsExistingObject) 
        {
            LogWarning "Subscription $TranscriptionName does not exist."
            return;
        };
        
        if ($TransSubscription.LoadProperties())
        {
            if ($TransSubscription.IsExistingObject)
            {
                $TransSubscription.Remove();
                LogInfo "Subscription $($TransSubscription.Name) deleted."
            }
            else
            {
                LogWarning "Subscription for $($TransSubscription.Name) does not exist.";
            }        
        }
        else
        {
            throw "Could not load properties for subscription $($TransSubscription.Name)."
        }      
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function SubscriptionCleanUp {
param (
    [String]$SubscriberName = $(throw '$SubscriberName required.'),
    [String]$SubscriptionDBName = $(throw '$SubscriptionDBName required.'),
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [String]$PublicationName = $(throw '$PublicationDBName required.'),
    [String]$SubscriberWindowsAuthentication,
    [String]$SubscriberSQLLogin,
    [String]$SubscriberSQLPassword
)
    try 
    {
        Test-Server -ServerName $SubscriberName
        
        if ($SubscriberWindowsAuthentication) 
        {
            $ConnString = "Server=$SubscriberName; Database=$SubscriptionDBName; Integrated Security=SSPI"
        }
        elseif ($SubscriberSQLLogin -and $SubscriberSQLPassword)
        {
            $ConnString = "Server=$SubscriberName; Database=$SubscriptionDBName; Uid=$SubscriberSQLLogin; Pwd=$SubscriberSQLPassword"
        }
            
        $ProcName = 'sp_subscription_cleanup'         
    	
    	#Connection object creation.
        $conn = new-object System.Data.SQLClient.SQLConnection
        $conn.ConnectionString = $ConnString
        $conn.Open();

        #SQL Command objection creation to get servers to poll.
        $cmd = new-object System.Data.SqlClient.SqlCommand("$ProcName", $conn)
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandTimeout = 0
        $cmd.Parameters.Add("@publisher", $PublisherName) | out-null
        $cmd.Parameters.Add("@publisher_db", "erp") | out-null
        $cmd.Parameters.Add("@publication", $PublicationName) | out-null
        $cmd.Parameters.Add("@ReturnValue", [System.Data.SqlDbType]"Int") | out-null
        $cmd.Parameters["@ReturnValue"].Direction = [System.Data.ParameterDirection]"ReturnValue"
        	
        LogInfo "Calling sp_subscription_cleanup on $SubscriberName..."
        $cmd.ExecuteNonQuery() | Out-Null;
        $ReturnValue = [int]$cmd.Parameters["@ReturnValue"].Value
        $conn.Close();
        if ($ReturnValue -ne 0) {throw "$ProcName returned"}
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };
};      
    


function MarkSubscriptionForReinitialize {
param (
    [Microsoft.SqlServer.Replication.TransSubscription]$TransSubscription = $(throw '$TransSubscription required.'),
    [Bool]$InvalidateSnapshot = $(throw '$InvalidateSnapshot required.')
)
    if ([string]::IsNullOrEmpty($TransSubscription)) {throw '$TransSubscription IsNullOrEmpty.'};       
    
    LogInfo "Marking subscription $($TransSubscription.Name) for reinit...";
    LogInfo "InvalidateSnap shot set to $InvalidateSnapshot.";
    $TransSubscription.Reinitialize($InvalidateSnapshot)
    LogInfo "Subscription $($TransSubscription.Name) marked for reinit.";

};

function VerifyDB {
param (
    [String]$ServerName = $(throw '$ServerName required.'),
    [String]$DBName = $(throw '$DBName required.')
)
    try
    {    
        if (Test-DB -ServerName $ServerName -DBName $DBName)
        {
            return $True
        }
        else
        {
            throw "Database $DBName not found on server $Servername"
        }              
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };
};   
    
function CreateSubscriptionDBFromConfig {
param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.')
)
    try
    {
       LogInfo "Creating subscription database $SubscriptionDBName on subscriber $SubscriberName..."
        if (!(Test-Path $config)) {throw "Cannot find file $config"}
    	$subdb_xml = [xml](Get-Content $config)
    	$subdb_type = $subdb_xml.setup.type | Where-Object {$_.name -eq $ConfigType}
        if(!$subdb_type)
    	{
    		$errorMessage = "$ConfigType is not a valid type in the $config file." 
    		throw $errorMessage
    	}
        
        $SubConfig = $subdb_type.Replication.Publication.Subscription.SubscriptionDBInfo.Config
        $SubType = $subdb_type.Replication.Publication.Subscription.SubscriptionDBInfo.Type
        if (!$SubConfig -or !$SubType) {throw "Missing Subscription database config info."}
        else
        {
            & $scriptpath\twn_setup_gamedb.ps1 `
                -i $Subscribername `
                -pfx $SubscriptionDBName `
                -sc $SubType `
                -config $SubConfig `
                -key $key
            
            LogInfo "Subscription database $SubscriptionDBName created on subscriber $SubscriberName..."
        };
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };
};  
 
#this doesn't work. 
function TestSubscriberWithDistributorCredentials {
param (
    [String]$SubscriberName = {throw '$SubscriberName required.'},
    [String]$SubscriberLogin = {throw '$SubscriberLogin required.'},
    [String]$SubscriberPassword = {throw '$SubscriberPassword required.'},
    [String]$SubscriberWindowsAuthentication = {throw '$SubscriberWindowsAuthentication required.'}
    
)
    try
    {
        $SubscriberConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection;   
        $SubscriberConnection.ServerInstance = $SubscriberName;
    
        if ($SubscriberWindowsAuthentication)
        {
            $SubscriberConnection.ConnectAsUser = $True;            
            $SubscriberConnection.ConnectAsUserName = $SubscriberLogin;
            $SubscriberConnection.ConnectAsUserPassword = $SubscriberPassword;
        }
        else
        {
            $SubscriberConnection.LoginSecure = $False;
            $SubscriberConnection.Login = $SubscriberLogin;
            $SubscriberConnection.Password = $SubscriberPassword;
        };
        $SubscriberConnection.Connect()
        $TestSubscriberSMOServer = New-Object Microsoft.SqlServer.Management.Smo.Server($SubscriberConnection);
        
        if (!($TestSubscriberSMOServer.Information.Version)) {$False} else {$True};
    }
    catch
    {
        throw $_;
    };
};    
 
function StartSnapshotGenerationAgentJob {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        
        if ($TransPublication.LoadProperties())
        {
            LogInfo "Starting Snapshot Agent Job for publication $($TransPublication.Name)..."
            $TransPublication.StartSnapshotGenerationAgentJob();
            LogInfo  "Snapshot Agent Job started for publication $($TransPublication.Name)."
        }
        else
        {
            throw "Could not load properties for publication $($TransPublication.Name)."

        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }  
};

function GetSnapshotAgent {
param (
    [string]$DistributorName = $(throw '$DistributorName required.'),
    [string]$Publisher = $(throw '$Publisher required.'),
    [string]$PublisherSecurityMode = $(throw '$PublisherSecurityMode required.'),
    [string]$PublicationName = $(throw '$PublicationName required.'),
    [string]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [string]$DistributorSecurityMode = $(throw '$DistributorSecurityMode required.')
    
)
    try
    {
        if ([string]::IsNullOrEmpty($DistributorName)) {throw '$DistributorName required.'};       
        if ([string]::IsNullOrEmpty($Publisher)) {throw '$Publisher required.'};       
        if ([string]::IsNullOrEmpty($PublisherSecurityMode)) {throw '$PublisherSecurityMode required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        if ([string]::IsNullOrEmpty($DistributorSecurityMode)) {throw '$DistributorSecurityMode required.'};       
    
        $SnapshotAgent = new-object "Microsoft.SqlServer.Replication.SnapshotGenerationAgent";
        
        $SnapshotAgent.Distributor = $DistributorName;
        $SnapshotAgent.DistributorSecurityMode = $DistributorSecurityMode;
        $SnapshotAgent.Publisher = $Publisher;
        $SnapshotAgent.PublisherSecurityMode = $PublisherSecurityMode;
        $SnapshotAgent.Publication = $PublicationName;
        $SnapshotAgent.PublisherDatabase = $PublicationDBName;
        $SnapshotAgent.ReplicationType = 'Transactional';
        
        $SnapshotAgent
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }  
}
    
function GenerateSnapshot {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.'),
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$PublicationName = $(throw '$PublicationName required.'),
    [String]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [String]$DistributorName = $(throw '$DistributorName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        if ([string]::IsNullOrEmpty($PublisherName)) {throw '$PublisherName required.'};       
        if ([string]::IsNullOrEmpty($PublicationName)) {throw '$PublicationName required.'};       
        if ([string]::IsNullOrEmpty($PublicationDBName)) {throw '$PublicationDBName required.'};       
        if ([string]::IsNullOrEmpty($DistributorName)) {throw '$DistributorName required.'};       
    
        $SnapshotGenerationAgent = new-object "Microsoft.SqlServer.Replication.SnapshotGenerationAgent";
        $SnapshotGenerationAgent.Publisher = $PublisherName;
        $SnapshotGenerationAgent.PublisherDatabase = $PublicationDBName;
        $SnapshotGenerationAgent.Publication = $PublicationName;
        $SnapshotGenerationAgent.Distributor = $DistributorName;
        $SnapshotGenerationAgent.PublisherSecurityMode = [Microsoft.SqlServer.Replication.SecurityMode]::Integrated;
        $SnapshotGenerationAgent.DistributorSecurityMode = [Microsoft.SqlServer.Replication.SecurityMode]::Integrated;
        $SnapshotGenerationAgent.ReplicationType = [Microsoft.SqlServer.Replication.ReplicationType]::Transactional;
        $SnapshotGenerationAgent.GenerateSnapshot();
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function CreateSnapshotAgentJob {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        
        if (!($TransPublication.SnapshotAgentExists))
        {
            LogInfo "Creating Snapshot Agent job for $($TransPublication.Name) ...";
            $TransPublication.CreateSnapshotAgent();
            LogInfo "Snapshot Agent job created for $($TransPublication.Name).";
            
            $TransPublication;
        }
        else
        {
            LogWarning "Snapshot Agent job for $($TransPublication.Name) already exists."
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function RunSnapshotAgentJob {
param (
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};       
        
        LogInfo "Starting Snapshot Agent job for $($TransPublication.Name)...";
        $Publication.StartSnapshotGenerationAgentJob();
        LogInfo "Snapshot Agent job started for $($TransPublication.Name).";
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};
#----------------------------------------------------------
function GetServerConnection {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};       
        New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $ServerName;   
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
};

function GetReplicationServer {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        new-object "Microsoft.SqlServer.Replication.ReplicationServer" $ServerConnection
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function GetDistributionDB {
param (
    [Microsoft.SqlServer.Management.Common.ServerConnection]$ServerConnection = $(throw '$ServerConnection required.'),
    [string]$DistributionDBName = $(throw '$DistributionDBName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerConnection)) {throw '$ServerConnection required.'};       
        New-Object “Microsoft.SqlServer.Replication.DistributionDatabase” $DistributionDBName,$ServerConnection;
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function DisablePublishingOnDB {
param (
    [Microsoft.SqlServer.Replication.ReplicationDatabase]$PublicationDatabase = $(throw '$PublicationDatabase required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($PublicationDatabase)) {throw '$PublicationDatabase required.'};       
        if ($PublicationDatabase.LoadProperties())
        {
            if ($PublicationDatabase.EnabledTransPublishing)
            {
                LogInfo "Disabling transactional replication on database $($PublicationDatabase.Name)..."
                $PublicationDatabase.EnabledTransPublishing  = $False;
                $ReplicationDatabase.CommitPropertyChanges() | out-null;
                LogInfo "Transactional replication disabled on database $($PublicationDatabase.Name)."
            }
            else
            {
                LogInfo "Database $($PublicationDatabase.Name) is not enabled for transactional replication."
            }
        }
        else
        {
            LogWarning "Database $($PublicationDatabase.Name) does not exist"
        }
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function Test-Articles {
param (
    [Microsoft.SqlServer.Management.Smo.Server]$SMOServer = $(throw '$SMOServer required.'),
    [String]$DBName = $(throw '$DBName required.'),
    [System.Xml.XmlElement]$ArticleInfo = $(throw '$ArticleInfo required.')
)
    if ([string]::IsNullOrEmpty($SMOServer)) {throw '$SMOServer required.'};       
    if ([string]::IsNullOrEmpty($DBName)) {throw '$DBName required.'};       
#Returns a list of tables that do not exists.  null if all is good.
    [string[]]$x=$Null
    
    foreach ($Article in $ArticleInfo.Articles.Article)
    {
        $ArticleName = $Article.Name;
        if ($ArticleName.Split('.').length -ne 2) {throw "Article must be in the format <schema>.<table>"}
        $Schema = $ArticleName.Split('.')[0]
        $TableName = $ArticleName.Split('.')[1]
        
        if (!(Test-Table -SMOServer $SMOServer -DBName $DBName -Schema $Schema -Table $TableName)) 
        {
        $x += $TableName,": invalid"
        }
        elseif (!(Test-TablePK -SMOServer $SMOServer -DBName $DBName -Schema $Schema -Table $TableName)) 
        {
        $x += $TableName,": No Primary Key"
        }
    }
    if($x)
    {
    LogError "Invalid Articles:"
    LogError $x 
    LogCallStack;throw "Invalid Articles"
    }
};

function PublicationAddPostSnapshotScript {
param (
    [Microsoft.SqlServer.Replication.ReplicationServer]$Publisher = $(throw '$Publisher required.'),
    [Microsoft.SqlServer.Replication.TransPublication]$TransPublication = $(throw '$TransPublication required.'),
    [System.Xml.XmlElement]$ArticlesFromConfig = $(throw '$ArticlesFromConfig required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($TransPublication)) {throw '$TransPublication required.'};
        
        #the working directory is on the distributor
        $UNCWorkingDirectory = '\\' + $Publisher.DistriButionServer + '\' + $Publisher.WorkingDirectory.Replace(':','$') 
        $FullPublicationName = "$($Publication.DatabaseName)-$($Publication.Name)";
        $PostScriptFileName = "$FullPublicationName.sql"
        $LocalPostScriptFileFull = $Publisher.WorkingDirectory + '\' + $PostScriptFileName;
        $UNCPostScriptFileFull = $UNCWorkingDirectory + '\' + $PostScriptFileName;
        
        $null | out-file $UNCPostScriptFileFull;
        $FileWritten = $false;
        
        foreach ($Article in $Publication.EnumArticles())
        {
            #for each article, find it in the config and see if it has any PostSnapshotScripts
            $ThisArticleFromConfig = $ArticlesFromConfig.Article | ?{$_.Name -eq "$($Article.SourceObjectOwner).$($Article.Name)"}
            $Scripts = $ThisArticleFromConfig.DestinationObjectOptions.PostSnapshotScripts.Script;        
            
            #set values for sql script replacement
            $SqlReplace = @{
                TableName= $Article.DestinationObjectName;
                SchemaName = $Article.SourceObjectOwner;
            };
        
            
            foreach($Script in $Scripts)
            {
                $Sql = BuildSQLString -InputSql $Script -SqlReplace $SqlReplace
                $Sql | out-file $UNCPostScriptFileFull -append;
                $FileWritten = $true;
            };
            
            if ($FileWritten) {LogInfo  "PostSnapshotScript file $UNCPostScriptFileFull created."};
            
            if ($FileWritten)
            {
                #set the PostSnapshotScript property of the publication to the just created sql file.
                $Publication.PostSnapshotScript = $LocalPostScriptFileFull;
                LogInfo  "PostSnapshotScript file $LocalPostScriptFileFull added to publication."
                
            } else
            {
                LogInfo "PostSnapshotScript file not written.  Could be a problem."
            };
            
        };
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};    

function SetDelayBetweenResponses {
param (
    [String]$ServerName = $(throw '$ServerName required.'),
    [int]$DelayBetweenResponses = $(throw '$DelayBetweenResponses required.')
)
    if ($DelayBetweenResponses -eq $Null) {throw '$DelayBetweenResponses required.'}
    
    try
    {
        $SMOServer = new-object Microsoft.SqlServer.Management.Smo.Server($ServerName)
        $Alert = $SMOServer.JobServer.Alerts | ?{$_.Name -like '*Latency*'}
        if ($Alert -eq $Null) {throw "Can't find Latency alert on server $($SMOServer.Name)."};
        
        $Alert.DelayBetweenResponses = $DelayBetweenResponses;
        $Alert.Alter();
        LogInfo "Latency alert on $($SMOServer.Name) set to $DelayBetweenResponses seconds.";
    }
    catch
    {
        LogWarning "Could not set latency alert on $($SMOServer.Name) set to $DelayBetweenResponses seconds.";
    }        
    
};

#----------------------------------------------------------
function CreateDistributorFromConfig {
param (
    [String]$Key = $(throw '$Key required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$DistributorName,
    [String]$DistributionDBName,
    [String]$DistributorAdminEncryptedPassword,
    [String]$WorkingDirectory,
    [String]$VerifyDistributionDB,
    [String]$PublisherName
)
    try
    {
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
    Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking

    $ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
    $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
    $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
    #------------------Distributor------------------
    $DistributorName = CheckParam `
        -Name '$DistributorName' `
        -Value $DistributorName `
        -ConfigPath $XMLConfigSection.Replication.Distributor.DistributorName`
        -Required
    $DistributionDBName = CheckParam `
        -Name '$DistributionDBName' `
        -Value $DistributionDBName `
        -ConfigPath $XMLConfigSection.Replication.Distributor.DistributionDBName `
        -Required;
    $DistributorAdminEncryptedPassword = CheckParam `
        -Name '$DistributorAdminEncryptedPassword' `
        -Value $DistributorAdminEncryptedPassword `
        -ConfigPath $XMLConfigSection.Replication.Distributor.DistributorAdminEncryptedPassword `
        -Required;
    $DistributorAdminPassword = Decrypt-String `
        -Encrypted $DistributorAdminEncryptedPassword `
        -passphrase $key;
    $WorkingDirectory = CheckParam `
        -Name '$WorkingDirectory' `
        -Value $WorkingDirectory `
        -ConfigPath $XMLConfigSection.Replication.Distributor.WorkingDirectory -Required    							
    [bool]$SetupWorkingDirectory = [bool][int] (CheckParam `
        -Name '$SetupWorkingDirectory' `
        -Value $SetupWorkingDirectory `
        -ConfigPath $XMLConfigSection.Replication.Distributor.SetupWorkingDirectory)  							        
    $DistributionAgent = CheckParam `
        -Name '$DistributionAgent' `
        -Value $DistributionAgent `
        -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.DistributionAgent.Login -Required    							        
     
    [bool]$VerifyDistributionDB = [bool][int] (CheckParam `
        -Name '$VerifySubscriberDB' `
        -Value $VerifyDistributionDB `
        -ConfigPath $XMLConfigSection.Replication.Distributor.VerifyDistributionDB `
        -Required)
    $PublisherName = CheckParam `
        -Name '$PublisherName' `
        -Value $PublisherName `
        -ConfigPath $XMLConfigSection.Replication.Publisher.Name `
        -Required
    
    $DelayBetweenResponses = CheckParam `
        -Name '$DelayBetweenResponses' `
        -Value $DelayBetweenResponses `
        -ConfigPath $XMLConfigSection.Replication.Distributor.Alerts.Latency.DelayBetweenResponses `
      
        Test-Server -ServerName $DistributorName
        
        if ($VerifyDistributionDB)
        {
            LogInfo "Verifying distribution database $DistributionDBName on $DistributorName";
            Test-DB -SMOServer $DistributorName -DBName $DistributionDBName;
        }
        else
        {
           LogInfo "Bypassing verifiction of distribution database $DistributionDBName on $DistributorName";
        };
        
        #check and configure working directory
        if ($SetupWorkingDirectory)
        {
            SetupWorkingDirectory `
                -ServerName $DistributorName `
                -WorkingDirectory $WorkingDirectory `
                -UserName $DistributionAgent
        };

        
        $DistributorCreate = CreateDistributor `
            -DistributorName $DistributorName `
            -DistributionDBName $DistributionDBName `
            -DistributorAdminPassword $DistributorAdminPassword `
            -WorkingDirectory $WorkingDirectory `
            -PublisherName $PublisherName `
            -DataFolder $XMLConfigSection.Replication.Distributor.DatabaseConfig.DataFolder `
            -DataFileSize $XMLConfigSection.Replication.Distributor.DatabaseConfig.DataFileSize `
            -LogFolder $XMLConfigSection.Replication.Distributor.DatabaseConfig.LogFolder `
            -LogFileSize $XMLConfigSection.Replication.Distributor.DatabaseConfig.LogFileSize
    
    }
    catch        
    {
        LogErrorObject $_;throw $_;    
    }
};

function CreateDistributor {
param (
    [String]$DistributorName = $(throw '$DistributorName required'),
    [String]$DistributionDBName = $(throw '$DistributionDBName required'),
    [String]$DistributorAdminPassword = $(throw '$DistributorAdminPassword required'),
    [String]$WorkingDirectory = $(throw '$WorkingDirectory required'),
    [String]$PublisherName = $(throw '$PublisherName required'),
    [String]$DataFolder,
    [String]$DataFileSize,
    [String]$LogFolder,
    [String]$LogFileSize
)
    try
    {
        $DistributorConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $DistributorName;   
        $DistributorConnection.Connect();
    
        $Distributor = New-Object "Microsoft.SqlServer.Replication.ReplicationServer" $DistributorConnection;
        
        $IsLocalDistributor = CheckIsLocalDistributor -DistributorName $DistributorName -PublisherName $PublisherName
        
        #configure distribution db
        $DistributionDB = New-Object "Microsoft.SqlServer.Replication.DistributionDatabase" $DistributionDBName, $DistributorConnection;
        $DistributionDB = SetDistributorDB -DistributionDB $DistributionDB -DataFolder $DataFolder -DataFileSize $DataFileSize -LogFolder $LogFolder -LogFileSize $LogFileSize
        
        #install distributor
        $InstallDistributor = InstallDistributor -ReplicationServer $Distributor  -DistributionDB $DistributionDB -DistributorAdminPassword $DistributorAdminPassword;
        
        $DistributionPublisher = New-Object “Microsoft.SqlServer.Replication.DistributionPublisher” $PublisherName,$Distributor.ConnectionContext;
        $DistributorCreated = RegisterPublisherOnDistributor -DistributionPublisher $DistributionPublisher -PublisherName $PublisherName -DistributionDBName $DistributionDBName -WorkingDirectory $WorkingDirectory
        
        if ($DistributorCreated) {SetDelayBetweenResponses -ServerName $ServerName -DelayBetweenResponses $DelayBetweenResponses}
        
        if ($PublisherConnection) {$PublisherConnection.Disconnect()};
        if ($DistributorConnection) {$DistributorConnection.Disconnect()};
        
        return $DistributorCreated
    }
    catch        
    {
        LogErrorObject $_;throw $_;    
    }
};

function CheckIsLocalDistributor {
param (
    [String]$DistributorName = $(throw 'DistributorName required'),
    [String]$PublisherName = $(throw 'PublisherName required')
)
    try
    {
        if ($DistributorName -eq $PublisherName)
        {
            if (!$Distributor.IsDistributor -and $Distributor.DistributorInstalled)
            {
                LogWarning "$DistributorName already has a remote distributor, $($Distributor.DistributionServer), but the config wants a local distributor."
                throw "The config will not work in this situation.  Things are FUBAR"
            };
            return $True
        };
        return $False
    }
    catch
    {
        LogErrorObject $_;throw $_;        
    }

};


function SetDistributorDB {
param (
    [Microsoft.SqlServer.Replication.DistributionDatabase]$DistributionDB = $(throw '$DistributionDB required'),
    [String]$DataFolder,
    [String]$DataFileSize,
    [String]$LogFolder,
    [String]$LogFileSize
)
    try
    {
        if ($DataFolder) {$DistributionDB.DataFolder = $Datafolder}
        if ($DataFileSize) {$DistributionDB.DataFileSize = $DataFileSize}
        if ($LogFolder) {$DistributionDB.LogFolder = $LogFolder}
        if ($LogFileSize) {$DistributionDB.LogFileSize = $LogFileSize}
        
        return $DistributionDB
    }
    catch
    {
        LogErrorObject $_;throw $_;        
    }

};

function CreatePublicationFromConfig {
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
        Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
        
    	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
        $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
        $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType

         #------------------Publisher------------------
        $DistributorName = CheckParam `
            -Name '$DistributorName'`
            -Value $DistributorName `
            -ConfigPath $XMLConfigSection.Replication.Distributor.DistributorName`
            -Required
        $DistributorDBName = CheckParam `
            -Name '$DistributorName'`
            -Value $DistributorName `
            -ConfigPath $XMLConfigSection.Replication.Distributor.DistributorDBName`
            -Required
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
        $VerifyPublicationDB = CheckParam `
            -Name '$VerifyPublicationDB' `
            -Value $VerifyPublicationDB `
            -ConfigPath $XMLConfigSection.Replication.Publication.VerifyPublicationDB `
            -Required;        
            
        $DistributorAdminEncryptedPassword = CheckParam `
            -Name '$DistributorAdminEncryptedPassword' `
            -Value $DistributorAdminEncryptedPassword `
            -ConfigPath $XMLConfigSection.Replication.Distributor.DistributorAdminEncryptedPassword `
            -Required;
        $DistributorAdminPassword = Decrypt-String `
            -Encrypted $DistributorAdminEncryptedPassword `
            -passphrase $key;
        $SnapshotAgentLogin = CheckParam `
            -Name '$SnapshotAgentLogin' `
            -Value $SnapshotAgentLogin `
            -ConfigPath $XMLConfigSection.Replication.Distributor.Security.SnapshotAgent.Login `
            -Required;
        $SnapshotAgentEncryptedPassword = CheckParam `
            -Name '$SnapshotAgentEncryptedPassword' `
            -Value $SnapshotAgentEncryptedPassword `
            -ConfigPath $XMLConfigSection.Replication.Distributor.Security.SnapshotAgent.EncryptedPassword `
            -Required;
        $SnapshotAgentPassword = Decrypt-String `
            -Encrypted $SnapshotAgentEncryptedPassword `
            -passphrase $key;   
        $LogReaderAgentLogin = CheckParam `
            -Name '$LogReaderAgentLogin' `
            -Value $LogReaderAgentLogin `
            -ConfigPath $XMLConfigSection.Replication.Distributor.Security.LogReaderAgent.Login `
            -Required;
        
        $PostSnapshotScript = CheckParam `
            -Name '$PostSnapshotScript' `
            -Value $PostSnapshotScript `
            -ConfigPath $XMLConfigSection.Replication.Publication.PostSnapshotScript;
        $PreSnapshotScript = CheckParam `
            -Name '$PreSnapshotScript' `
            -Value $PreSnapshotScript `
            -ConfigPath $XMLConfigSection.Replication.Publication.PreSnapshotScript;        
            
        $LogReaderEncryptedPassword = CheckParam `
            -Name '$LogReaderEncryptedPassword' `
            -Value $LogReaderEncryptedPassword `
            -ConfigPath $XMLConfigSection.Replication.Distributor.Security.LogReaderAgent.EncryptedPassword `
            -Required;
        $LogReaderAgentPassword = Decrypt-String `
            -Encrypted $LogReaderEncryptedPassword `
            -passphrase $key;        
        #------------------/Publisher------------------
        Test-Server -ServerName $PublisherName
        Test-Server -ServerName $DistributorName
        
        #test agent logins at publisher
        if (!(Test-Login -ServerName $PublisherName -Login $LogReaderAgentLogin)) {throw "Login $LogReaderAgentLogin does not exist on publisher $PublisherName."};
        if (!(Test-Login -ServerName $PublisherName -Login $SnapshotAgentLogin)) {throw "Login $SnapshotAgentLogin does not exist on publisher $PublisherName."};
        
        #test agent logins at distributor
        if (!(Test-Login -ServerName $DistributorName -Login $LogReaderAgentLogin)) {throw "Login $LogReaderAgentLogin does not exist on distributor $DistributorName."};
        if (!(Test-Login -ServerName $DistributorName -Login $SnapshotAgentLogin)) {throw "Login $SnapshotAgentLogin does not exist on distributor $DistributorName."};
        
        #verify publication db exists?
        if ($VerifyPublicationDB)
        {
            VerifyDB -ServerName $PublisherName -DBName $PublicationDBName
        };
        
        $Publication = CreatePublication `
            -PublisherName $PublisherName `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName `
            -DistributorName $DistributorName `
            -DistributionDBName $DistributionDBName `
            -DistributorAdminPassword $DistributorAdminPassword `
            -LogReaderAgentLogin $LogReaderAgentLogin `
            -LogReaderPassword $LogReaderPassword `
            -SnapshotAgentLogin $SnapshotAgentLogin `
            -SnapshotAgentPassword $SnapshotAgentPassword
            
        #connection to publisher
        $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;   
        $PublisherConnection.Connect();
        $Publisher = New-Object "Microsoft.SqlServer.Replication.ReplicationServer" $PublisherConnection
        
        #add articles
        $ArticleInfo = $XMLConfigSection.Replication.Publication.ArticleInfo
        #TODO: use PublicationExists to skip or not
        $NumArticlesAdded = AddArticles -ServerConnection $PublisherConnection -PublicationDBName $PublicationDBName -PublicationName $PublicationName -ArticleInfo $ArticleInfo
        
        #add PostSnapshotScripts if necessary
        
        if ($XMLConfigSection.Replication.Publication.PostSnapshotScripts -eq 1 -and $PublicationCreated)
        {
            PublicationAddPostSnapshotScript -Publisher $Publisher -TransPublication $Publication -ArticlesFromConfig $XMLConfigSection.Replication.Publication.ArticleInfo.Articles;
        };
        
        if ($PublisherConnection) {$PublisherConnection.Disconnect()};            
            
        return $PublicationCreated
    }    
    catch
    {
        LogErrorObject $_;throw $_;        
    }

};    

function CreatePublication {
param (
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$PublicationName = $(throw '$PublicationName required.'),
    [String]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [String]$DistributorName = $(throw '$DistributorName required.'),
    [String]$DistributionDBName = $(throw '$DistributionDBName required.'),
    [String]$DistributorAdminPassword = $(throw '$DistributorAdminPassword required.'),
    [String]$LogReaderAgentLogin = $(throw '$LogReaderAgentLogin required.'),
    [String]$LogReaderPassword = $(throw '$LogReaderPassword required.'),
    [String]$SnapshotAgentLogin = $(throw '$SnapshotAgentLogin required.'),
    [String]$SnapshotAgentPassword = $(throw '$SnapshotAgentPassword required.')
)
    try
    {
        Test-Server -ServerName $PublisherName
        Test-Server -ServerName $DistributorName
        
        $IsLocalDistributor = CheckIsLocalDistributor -DistributorName $DistributorName -PublisherName $PublisherName
        
        #test agent logins at publisher
        if (!(Test-Login -ServerName $PublisherName -Login $LogReaderAgentLogin)) {throw "Login $LogReaderAgentLogin does not exist on publisher $PublisherName."};
        if (!(Test-Login -ServerName $PublisherName -Login $SnapshotAgentLogin)) {throw "Login $SnapshotAgentLogin does not exist on publisher $PublisherName."};
        #test agent logins at distributor
        if (!(Test-Login -ServerName $DistributorName -Login $LogReaderAgentLogin)) {throw "Login $LogReaderAgentLogin does not exist on distributor $DistributorName."};
        if (!(Test-Login -ServerName $DistributorName -Login $SnapshotAgentLogin)) {throw "Login $SnapshotAgentLogin does not exist on distributor $DistributorName."};
        
        #connection to publisher
        $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;   
        $PublisherConnection.Connect();
        $Publisher = New-Object "Microsoft.SqlServer.Replication.ReplicationServer" $PublisherConnection
        
        #if remote distributor 
        if (!$IsLocalDistributor)
        {
            RegisterRemoteDistributorOnPublisher -ReplicationServer $Publisher  -DistributorName $DistributorName -DistributorAdminPassword $DistributorAdminPassword;
        };
        
        #get publication database
        $PublicationDB = GetPublicationDB -ServerConnection $PublisherConnection -PublicationDBName $PublicationDBName
        #enable it for publishing and set logreader agent security
        CreateLogReaderAgent -PublicatioNDB $PublicatioNDB -LogReaderAgentLogin $LogReaderAgentLogin -LogReaderAgentPassword $LogReaderAgentPassword
        
        #create publication
        $Publication = GetPublication -ServerConnection $PublisherConnection -PublicationName $PublicationName -PublicationDBName $PublicationDBName;
        $Publication = SetPublicationSecurity -TransPublication $Publication -SnapshotAgentLogin $SnapshotAgentLogin -SnapshotAgentPassword $SnapshotAgentPassword;
        $PublicationCreated = CreateTransPublication -TransPublication $Publication;
        
        if ($PublisherConnection) {$PublisherConnection.Disconnect()};
        
        return $Publication
    }
    catch
    {
        LogErrorObject $_;throw $_;   
    }        

};

function CreateSubscriptionFromConfig {
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
        Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
        
    	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
        $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
        $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
    
         #------------------Subscriber------------------
        $SubscriberName = CheckParam `
            -Name '$SubscriberName' `
            -Value $SubscriberName `
            -ConfigPath $XMLConfigSection.Replication.Subscriber.SubscriberName `
            -Required;
        $SubscriptionDBName = CheckParam `
            -Name '$SubscriptionDBName' `
            -Value $SubscriptionDBName `
            -ConfigPath $XMLConfigSection.Replication.Subscriber.SubscriptionDBName `
            -Required;
        $DistributionAgentLogin = CheckParam `
            -Name '$DistributionAgentLogin' `
            -Value $DistributionAgentLogin `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.DistributionAgent.Login `
            -Required;
        $DistributionAgentPasswordEncrypted = CheckParam `
            -Name '$DistributionAgentPasswordEncrypted' `
            -Value $DistributionAgentPasswordEncrypted `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.DistributionAgent.EncryptedPassword `
            -Required;
        $DistributionAgentPassword = Decrypt-String `
            -Encrypted $DistributionAgentPasswordEncrypted `
            -passphrase $key;
        [Bool] $SubscriberWindowsAuthentication = [Bool][Int] (CheckParam `
            -Name '$SubscriberWindowsAuthentication' `
            -Value $SubscriberWindowsAuthentication `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.WindowsAuthentication `
            -Required);
            
        if (!($SubscriberWindowsAuthentication))
        {
            $SubscriberSQLLogin = CheckParam `
                -Name '$SubscriberSQLLogin' `
                -Value $SubscriberSQLLogin `
                -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.SqlStandardLogin `
                -Required;
            $SubscriberSQLPasswordEncrypted = CheckParam `
                -Name '$SubscriberSQLPasswordEncrypted' `
                -Value $SubscriberSQLPasswordEncrypted `
                -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.SqlStandardPasswordEncrypted `
                -Required;
            $SubscriberSQLPassword = Decrypt-String `
                -Encrypted $SubscriberSQLPasswordEncrypted `
                -passphrase $key;
        }
        $VerifySubscriptionDB = CheckParam `
            -Name '$VerifySubscriptionDB' `
            -Value $VerifySubscriptionDB `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.VerifySubscriptionDB;
            
        $CreateSubscriptionDB = CheckParam `
            -Name '$CreateSubscriptionDB' `
            -Value $CreateSubscriptionDB `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.CreateSubscriptionDB;        
        
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
        Test-Server -ServerName $SubscriberName
        
        #subscriber database?
        if ($VerifySubscriptionDB)
        {
            $SubscriptionDBExists = VerifyDB -ServerName $SubscriberName -DBName $SubscriptionDBName
        };   
        
        $SubscriptionCreated = CreateSubscription `
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
            -SubscriberSQLPassword $SubscriberSQLPassword
        
        return $SubscriptionCreated
        
    }
    catch
    {
        LogErrorObject $_;throw $_;   
    }        

};

function CreateSubscription {
param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName = $(throw '$PublisherName required.'),
    [String]$PublicationName = $(throw '$PublicationName required.'),
    [String]$PublicationDBName = $(throw '$PublicationDBName required.'),
    [String]$SubscriberName = $(throw '$SubscriberName required.'),
    [String]$SubscriptionDBName = $(throw '$SubscriptionDBName required.'),
    [Bool]$SubscriberWindowsAuthentication = $(throw '$SubscriberWindowsAuthentication required.'),
    [String]$SubscriberSQLLogin,
    [String]$SubscriberSQLPassword
)
    try
    {
         #connection to publisher
        $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;   
        $PublisherConnection.Connect();
        
        #register subscriber
        RegisterSubscriber -ServerConnection $PublisherConnection -SubscriberName $SubscriberName
        
        #create subscription
        $TransSubscription = GetTransSubscription -ServerConnection $PublisherConnection
        
        $TransSubscription = SetTransSubscription `
            -TransSubscription $TransSubscription `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName `
            -SubscriberName $SubscriberName `
            -SubscriptionDBName $SubscriptionDBName 
        
        $TransSubscription = SetTransSubscriptionSecurity `
            -TransSubscription $TransSubscription `
            -DistributionAgentLogin $DistributionAgentLogin `
            -DistributionAgentPassword $DistributionAgentPassword `
            -WindowsAuthentication $SubscriberWindowsAuthentication `
            -SqlStandardLogin $SubscriberSQLLogin `
            -SqlStandardPassword $SubscriberSQLPassword
        
        $SubscriptionCreated = CreateTransSubscription -TransSubscription $TransSubscription
        $PublisherConnection.Disconnect() | Out-Null;
        
        return $SubscriptionCreated
    }
    
    catch
    {
        LogErrorObject $_;throw $_;   
    }        
};

function StartSnapshotAgentJobFromConfig {
param (
    [String]$Key = $(throw '$Key required.'),
    [String]$ConfigType = $(throw '$ConfigType required.'),
    [String]$Config = $(throw '$Config required.'),
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName
)
    try
    {
        Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
        
    	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
        $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
        $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
        
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
};

function RemoveSubscriptionFromConfig {
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
        Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
        
    	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
        $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
        $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
        
         $HelpMsg = @'
        All parameters are required.  A config file can be used.  An * indicates the parameters that must be passed on the command line.
         
        [String]$Key,							      *Key to decrypt passwords
        [String]$ConfigType                           *Config type to use, e.g. dal,ams,dev,blah, etc.
        [String]$Config,                              *Path to the config file
        [String]$PublisherName                        *Name of Publisher
        [String]$PublicationName,                     Name of publication
        [String]$PublicationDBName,                   Database for publication
        [String]$SubscriberName,                      Server for the subscriber
        [String]$SubscriptionDBName,                  Database on subscriber for subscription database
        [Bool]$SubscriberWindowsAuthentication,		  1 = windows auth. 0 = sql login.
        [String]$SubscriberSQLLogin,				  Login used by distributor agent connect to the subscriber
        [String]$SubscriberSQLPasswordEncrypted,	  Encrypted password for distributor agent
        [Switch]$SubscriptionCleanup                  To clean up the subscriber.  Doesn't work cross domain.
'@      

         #------------------Subscriber------------------
        $SubscriberName = CheckParam `
            -Name '$SubscriberName' `
            -Value $SubscriberName `
            -ConfigPath $XMLConfigSection.Replication.Subscriber.SubscriberName `
            -Required;
        $SubscriptionDBName = CheckParam `
            -Name '$SubscriptionDBName' `
            -Value $SubscriptionDBName `
            -ConfigPath $XMLConfigSection.Replication.Subscriber.SubscriptionDBName `
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
        [bool]$SubscriberWindowsAuthentication = [bool][int] (CheckParam `
            -Name '$SubscriberWindowsAuthentication' `
            -Value $SubscriberWindowsAuthentication `
            -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.WindowsAuthentication `
            -Required);

        if (!($SubscriberWindowsAuthentication))
        {
            $SubscriberSQLLogin = CheckParam `
                -Name '$SubscriberSQLLogin' `
                -Value $SubscriberSQLLogin `
                -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.SqlStandardLogin `
                -Required;
            $SubscriberSQLPasswordEncrypted = CheckParam `
                -Name '$SubscriberSQLPasswordEncrypted' `
                -Value $SubscriberSQLPasswordEncrypted `
                -ConfigPath $XMLConfigSection.Replication.Publication.Subscription.Security.SubscriberSecurity.SqlStandardPasswordEncrypted `
                -Required;
            $SubscriberSQLPassword = Decrypt-String `
                -Encrypted $SubscriberSQLPasswordEncrypted `
                -passphrase $key;
        }            
        
        Test-Server -ServerName $PublisherName
        Test-Server -ServerName $SubscriberName
        
        RemoveSubscription `
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
};

function RemoveSubscription {
param (
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [String]$SubscriberName,
    [String]$SubscriptionDBName,
    [String]$SubscriberWindowsAuthentication,
    [String]$SubscriberSQLLogin,
    [String]$SubscriberSQLPassword,
    [Switch]$SubscriptionCleanup
)
    try
    {
        Test-Server -ServerName $PublisherName
        Test-Server -ServerName $SubscriberName
        
        #connection to publisher
        $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;
        $PublisherConnection.Connect();
        
        #create subscription
        $TransSubscription = GetTransSubscription -ServerConnection $PublisherConnection
        
        $TransSubscription = SetTransSubscription `
            -TransSubscription $TransSubscription `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName `
            -SubscriberName $SubscriberName `
            -SubscriptionDBName $SubscriptionDBName 
        
        RemoveTransSubscription -TransSubscription $TransSubscription;
        
        if ($SubscriptionCleanup)
        {
            SubscriptionCleanUp `
                -SubscriberName $SubscriberName `
                -SubscriptionDBName $SubscriptionDBName `
                -PublisherName $PublisherName `
                -PublicationDBName $PublicationDBName `
                -PublicationName $PublicationName `
                -SubscriberWindowsAuthentication $SubscriberWindowsAuthentication `
                -SubscriberSQLLogin $SubscriberSQLLogin `
                -SubscriberSQLPassword $SubscriberSQLPassword;
        };
    }
    catch
    {
        LogErrorObject $_;throw $_;   
    }         
};

function RemovePublicationFromConfig {
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
        Import-Module $GLOBAL:_XMLConfigModule -DisableNameChecking
        
    	$ConfigFile = SetXMLConfigFile -XMLConfig $Config -ConfigDir $GLOBAL:_ConfigDir
        $XMLConfig = GetXMLConfigFile -XMLConfigFile $ConfigFile
        $XMLConfigSection = GetXMLConfigSection -XML $XMLConfig -ConfigType $ConfigType
        
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

        #does server exists?
        Test-Server -ServerName $PublisherName

        #------------------Publisher------------------
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
        $PublicationName = CheckParam `
            -Name '$PublicationName' `
            -Value $PublicationName `
            -ConfigPath $XMLConfigSection.Replication.Publisher.PublicationName `
            -Required;            
        #------------------/Publisher------------------
        
        RemovePublication `
            -PublisherName $PublisherName `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName `
            -DisablePublishing:$DisablePublishing
        
    
    }
    
    catch
    {
        LogErrorObject $_;throw $_;   
    }         
};

function RemovePublication {
param (
    [String]$PublisherName,
    [String]$PublicationName,
    [String]$PublicationDBName,
    [Switch]$DisablePublishing
)
    try
    {
        #connection to publisher
        $PublisherConnection = New-Object “Microsoft.SqlServer.Management.Common.ServerConnection” $PublisherName;   
        $PublisherConnection.Connect();
        
        $Publication = GetPublication `
            -ServerConnection $PublisherConnection `
            -PublicationName $PublicationName `
            -PublicationDBName $PublicationDBName
        
        RemoveTransPublication -TransPublication $Publication -DisablePublishing:$DisablePublishing;
    }    
    catch
    {
        LogErrorObject $_;throw $_;   
    }         
};