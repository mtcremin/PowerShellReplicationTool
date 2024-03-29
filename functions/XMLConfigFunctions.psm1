Import-Module $GLOBAL:_LogModule

######################XML Stuff######################
function SetXMLConfigFile {
param (
    [String]$XMLConfig = $(throw '$XMLConfigFile required.'),
    [String]$ConfigDir = $(throw '$ConfigDir required.')
)
    try
    {
        if ($XMLConfig -notlike "*.xml") 
        {
    		return "$ConfigDir\$XMLConfig.xml"
    	}
        else
        {
            return $XMLConfig
        }
    }
    catch
    {
		LogErrorObject $_;throw $_;
    } 
};

function GetXMLConfigFile {
param (
    [String]$XMLConfigFile = $(throw '$XMLConfigFile required.')
)
    try
    {
        if (!(Test-Path $XMLConfigFile)) {throw "Cannot find file $XMLConfigFile"}
    
        return [xml](Get-Content $XMLConfigFile)
        
    }
    catch
    {
		LogErrorObject $_;throw $_;
    } 
};

function GetXMLConfigSection {
param (
    $XML = $(throw '$XML required.'),
    [String]$ConfigType = $(throw '$ConfigType required.')
)
    try
    {
        $XMLConfigSection = $XML.setup.type | Where-Object {$_.name -eq $ConfigType}
        if(!$XMLConfigSection)
    	{
    		$errorMessage = "$ConfigType is not a valid type in the $config file." 
    		throw $errorMessage
    	}
        
        return $XMLConfigSection
    }
    catch
    {
		LogErrorObject $_;throw $_;
    } 
};


function CopyFoldersFromConfig {
param (
    $ServerName = $(throw '$ServerName required.'),
    $ConfigSection = $(throw '$FolderSection required.')
)
    try
    {
        foreach ($Folder in $ConfigSection | ?{$_})
        {
            if ($Folder.Source -xor $Folder.Dest) {throw 'CopyFolder data is incomplete'};
            
            $Source = $Folder.SourceBase + '\' + $Folder.Source
            
            $Dest = $Folder.DestBase + '\' + $Folder.Dest
            $Dest = GetUNCPath (GetInstanceServerName $ServerName) $Dest
            
            LogInfo "Calling RoboCopy!!!..."
            CallRoboCopy $Source $Dest
            
            if ($FileSystemRights = ,$Folder.FileSystemRights)
            {
                foreach($User in $Folder.Users.User | ?{$_})
                {
                    LogInfo "Setting permissions on $Dest..."
                    SetDirectoryACL $FileSystemRights Allow $User $Dest
                };
            };
        };
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
};

function CreateServerAliasFromConfig {
param (
    $ServerName = $(throw '$ServerName required.'),
    $ConfigSection = $(throw '$FolderSection required.')
)
    try
    {
        foreach ($ServerAlias in $XMLConfigSection.ServerAliases.ServerAlias)
        {
            if (!($ServerAlias.TargetServer -or $ServerAlias.AliasName)) 
            {
            continue
            };
            if (!($ServerAlias.TargetServer -and $ServerAlias.AliasName)) {throw 'Config values for ServerAlias are incomplete.'};
            
            if (!(Test-SQLServer $ServerAlias.TargetServer)) {throw "Cannot reach TargetServer $($ServerAlias.TargetServer)"}
            
            & create-serveralias `
                    -parentserver (GetInstanceServerName $ServerName) `
                    -targetserver (GetInstanceServerName $ServerAlias.TargetServer) `
                    -aliasname $ServerAlias.AliasName `
                    -action 'create'
        }
    }  
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};    

function CreateLinkedServerFromConfig {
param (
    $ServerName = $(throw '$ServerName required.'),
    $ConfigSection = $(throw '$FolderSection required.'),
    $Key = $(throw '$Key required.')
)
    try
    {
        foreach ($LinkedServer in $ConfigSection)
        {
            if (!($LinkedServer.Name -or $LinkedServer.DataSource -or $LinkedServer.RemoteUser -or $LinkedServer.RemotePassword)) 
            {
            continue
            };
            if (!($LinkedServer.Name -and $LinkedServer.DataSource -and $LinkedServer.RemoteUser -and $LinkedServer.RemotePassword)) {throw 'Config values for LinkedServer are incomplete.'};
            
            $Password = Decrypt-String -Encrypted $LinkedServer.RemotePassword -passphrase $key;
            
            if (!(Test-SQLServer $LinkedServer.DataSource)) {throw "Cannot reach DataSource $($LinkedServer.DataSource)"}
            
            CreateSQLLinkedServer `
                    -Instance $ServerName `
                    -DataSource $LinkedServer.DataSource `
                    -RemoteUser $LinkedServer.RemoteUser `
                    -RemotePassword $Password `
                    -Drop
        }
    }  
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};    

function GetObjectFromXML {
param (
    $XML = $(throw '$XML required.'),
    [String]$ObjectToGet

)
    try
    {
        if ($ObjectToGet) 
        {
            $Object = $XML | ?{$_.Name -eq $ObjectToGet}
            if ($Object)
            {
                return $Object
            }
            else
            {
                $Object = @()
                return ,$Object
            }
        } 
        else
        {
            return $XML
        }
    }
    catch        
    {
        LogErrorObject $_;throw $_;
    }
};

function CheckParam {
param (
    [String]$Name,
    [String]$Value,
    [String]$ConfigPath,
    [Switch]$Required
)
    try
    {
        if ([string]::IsNullOrEmpty($Name)) {throw '$Name required.'};       
        #if ([string]::IsNullOrEmpty($ConfigPath)) {throw '$ConfigPath required.'};       
        
        if ([string]::IsNullOrEmpty($Value))
        {
            $Value = $ConfigPath;
        }

        if ([string]::IsNullOrEmpty($Value) -and $Required)
        {
            
            #throw "$((Get-PSCallStack)[0].Command): Missing $Name"
            throw "Missing $Name"
        }

        $Value
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }     
};