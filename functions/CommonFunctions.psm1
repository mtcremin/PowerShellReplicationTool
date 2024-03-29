Import-Module $GLOBAL:_LogModule

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')| Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common') | Out-Null


#/#####################XML Stuff######################
function IsInstance {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};       
        $Servername -like '*\*';
    }
    catch
    {
		LogErrorObject $_;throw $_;
    }         
}

function GetInstanceServerName {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};       
        
        if (IsInstance -ServerName $ServerName)
        {
            $ServerName.Split('\')[0]
        }
        else
        {
            $ServerName;
        }
    }
    catch
    {
		LogErrorObject $_;throw $_;
    } 
};

function GetInstanceName {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};       
        
        if (IsInstance -ServerName $ServerName)
        {
            $ServerName.Split('\')[1]
        }
        else
        {
            $Null
        }
    }
    catch
    {
		throw $_;
    }         
};

function Test-SQLServer {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};
        $SMOServer = New-Object Microsoft.SQLServer.Management.Smo.Server $ServerName
        if ($SMOServer.Information) {$True} else {$False};
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }    
};

function Test-Server {
param (
    [string]$ServerName = $(throw '$ServerName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};
        if (!(test-connection -computername $(GetInstanceServerName -ServerName $ServerName) -Quiet -Count 1)) {throw "Cannot connect to $ServerName"};
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }    
};    


function Test-DB {
param (
    [String]$ServerName = $(throw '$ServerName required.'),
    [String]$DBName = $(throw '$DBName required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};
        if ([string]::IsNullOrEmpty($DBName)) {throw '$DBName required.'};
        $SMOServer = New-Object Microsoft.SQLServer.Management.Smo.Server $ServerName
        
        if ($SMOServer.Databases[$DBName].Name -eq $DBName) {$True} else {$False};
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }    
}    

function Test-Table {
param (
    [Microsoft.SqlServer.Management.Smo.Server]$SMOServer = $(throw '$SMOServer required.'),
    [string]$DBName = $(throw '$DBName required.'),
    [string]$Schema = $(throw '$Schema required.'),
    [string]$Table = $(throw '$Table required.')
)
    try 
    {
        if ([string]::IsNullOrEmpty($SMOServer)) {throw '$SMOServer required.'};       
        if ([string]::IsNullOrEmpty($DBName)) {throw '$DBName required.'};       
        if ([string]::IsNullOrEmpty($Schema)) {throw '$Schema required.'};       
        if ([string]::IsNullOrEmpty($Table)) {throw '$Table required.'};       
        
        if ($SMOServer.Databases[$DBName].Tables | ?{$_.name -eq $Table} | ?{$_.Name -eq $Table -and $_.Schema -eq $Schema}) {$True} else {$False}
    }        
    catch
    {
        LogErrorObject $_;throw $_;
    }    
}    


function Test-Login {
param (
    [String]$ServerName = $(throw '$ServerName required.'),
    [String]$Login = $(throw '$Login required.')
)
    try
    {
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$SMOServer required.'};       
        if ([string]::IsNullOrEmpty($Login)) {throw '$Login required.'};
        
        $SMOServer = New-Object Microsoft.SQLServer.Management.Smo.Server $ServerName
        
        if ($SMOServer.Logins | ?{$_.Name -eq $Login}) {$True} else {$False}
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }           
};

function Test-TablePK {
param (
    [Microsoft.SqlServer.Management.Smo.Server]$SMOServer = $(throw '$SMOServer required.'),
    [string]$DBName = $(throw '$DBName required.'),
    [string]$Schema = $(throw '$Schema required.'),
    [string]$Table = $(throw '$Table required.')
)
    try 
    {
        if ([string]::IsNullOrEmpty($SMOServer)) {throw '$SMOServer required.'};       
        if ([string]::IsNullOrEmpty($DBName)) {throw '$DBName required.'};       
        if ([string]::IsNullOrEmpty($Schema)) {throw '$Schema required.'};       
        if ([string]::IsNullOrEmpty($Table)) {throw '$Table required.'};       
        
        if ($SMOServer.Databases[$DBName].Tables | ?{$_.name -eq $Table} | %{$_.Indexes} | ?{$_.IndexKeyType -eq 'DriPrimaryKey'}) {$True} else {$False}
    }
    catch           
    {
        LogErrorObject $_;throw $_;
    }    
};    
#---------------------Stored Proces-------------------------------------
function killProcess {
    param (
        [string]$ServerName=$(throw "Missing ServerName"),
        [string]$DBName=$(throw "Missing DBName")
    )
    try
    {    
        if ([string]::IsNullOrEmpty($ServerName)) {throw '$ServerName required.'};       
        if ([string]::IsNullOrEmpty($DBName)) {throw '$DBName required.'};       
        
        Test-Server -ServerName $ServerName
        
    	$ConnString = "Server=$ServerName; Database=watchman; Integrated Security=SSPI"
    	
    	#Connection object creation.
        $conn = new-object System.Data.SQLClient.SQLConnection
        $conn.ConnectionString = $ConnString
        $conn.Open();

        #SQL Command objection creation to get servers to poll.
        $cmd = new-object System.Data.SqlClient.SqlCommand("[wp_killProcess]", $conn)
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandTimeout = 0
        $cmd.Parameters.Add("@DBname", $DBName) | out-null
        	
        write-host "killing sessions on $Servername.$DBName..."
        $r = $cmd.ExecuteNonQuery();
        $r
        $conn.Close();
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};
#----------------------------------------------------------
function BuildSQLString {
param (
    [string]$InputSql = $(throw '$InputSQL required.'),
    [hashtable]$SqlReplace = $(throw '$SqlReplace required.'),
    [string]$Indicator = '@'
)
    try
    {
        foreach($ToReplace in $SqlReplace.GetEnumerator())
        {
            $InputSql = $InputSql -replace "@$($ToReplace.key)",$ToReplace.Value;
        };

        $InputSql;
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};            



function CallRoboCopy {
param (
    [String]$Source = $(throw '$Source required.'),
    [String]$Dest = $(throw '$Destination required.'),
    [String]$What = '*.*',
    [Array]$Options = @("/COPY:DAT", "/S", "/Z", "/PURGE"),
    [Switch]$Verbose
)
$HelpMsg = @'
    $Source = "C:\FunkyBus"
    $Destination = "C:\dest"
    $What = "*.*"
    $Options = @("/COPY:DT", "/S", "/Z", "/PURGE")
'@
    try 
    {
        if (!(Test-Path $Dest))
        {
            New-Item $Dest -type directory -ea stop
        };
    
        $CmdArgs =  @($Source, $Dest, $What, $Options)
        if ($Verbose) {& robocopy @CmdArgs} else {& robocopy @CmdArgs | out-null};
        if ($LastExitCode -ge 4)
        {
            $Msg = "Robocopy returned erroor code: $LastExitCode"
            throw $Msg
        };
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }
};

function SetDirectoryACL {
param (
    [System.Security.AccessControl.FileSystemRights]$FileSystemRights = {throw '$FileSystemRights required'},
    [System.Security.AccessControl.AccessControlType]$AccessControlType = {throw '$AccessControlType required'},
    [System.Security.Principal.NTAccount]$NTAccount = {throw '$NTAccount required'},
    [String]$DirectorySecurityObjectName = {throw '$DirectorySecurityObjectName required'}
 )
    try 
    {
        $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
        
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($NTAccount, $FileSystemRights, $InheritanceFlag, $PropagationFlag, $AccessControlType) 
        $objACL = Get-ACL $DirectorySecurityObjectName
        $objACL.AddAccessRule($objACE) 
        Set-ACL $DirectorySecurityObjectName $objACL
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }
};

#ssis_job_set_config
function SetConfigSSISJob {
param (
    [String]$FileName = {throw '$FileName required.'},
    [String]$Dest = {throw '$Dest required.'},
    [String]$SearchString = {throw '$SearchString required.'}
)
    try
    {
        if(!(Test-Path $FileName)) {throw "Cannot find file $FileName"}
        $SearchString = $SearchString.replace('\','\\')
        
        $FileContents = gc $FileName
        
        $i=0
        foreach($Line in $FileContents)
        {
            if ($Line.toupper() -match '/FILE') {$found=$i}
            $i++
        };
        $file[$found] = $file[$found] -replace $SearchString,$Dest
        $file | out-file $FileName
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };        
};   

function GetUNCPath {
param (
    [String]$ServerName = {throw '$ServerName required.'},
    [String]$Path = {throw '$Path required.'}
)
    try
    {
        '\\' + $ServerName + '\' + $Path.Replace(':','$')
    }
    catch
    {
        LogErrorObject $_;throw $_;
    };
};     

function GetFileList {
param (
    [String]$Directory
)
    try
    {
        if (!$Directory) {throw '$Directory required.'}
        StackDebug -Enter
        
        LogInfo -Msg "Searching for files."
        $RetValue = @(Get-ChildItem "$Directory" -include *.sql -recurse | select @{Name="NameWithFolder";Expression={($_.FullName -replace $Directory.Replace('\','\\'),'') -replace ('^\\','')}}, Name, FullName)
        LogInfo -Msg "Found $($RetValue.length) file(s)."
        foreach($File in $RetValue)
        {
            LogInfo -Msg "$($File.NameWithFolder)"
        }
        return ,$RetValue
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};



function RunScriptsFromConfig {
param (
    $ServerName = $(throw '$ServerName required.'),
    $DatabaseName = 'master',
    $ConfigSection = $(throw '$FolderSection required.')
)
    try
    {
        foreach ($Script in $ConfigSection | ?{$_})
        {
            if (!($Script.SourceBase -and $Script.Source)) {throw 'Must supply both SourceBase and Source to run scripts'};
            $ScriptPath = $Script.SourceBase + '\' + $Script.Source
            LogInfo "Running scripts: $RunScriptPath"
            
    		if (!(Test-Path $ScriptPath)) {throw "Cannot find folder $ScriptPath"}
            if (!$Test)
            {
                RunScripts -ServerName $ServerName -DatabaseName $DatabaseName -ScriptPath $ScriptPath
            }               
        }
    }  
    catch
    {
        LogErrorObject $_;throw $_;
    }      
};

function RunScripts {
param (
    $ServerName = $(throw '$ServerName required.'),
    $DatabaseName = $(throw '$DatabaseName required.'),
    $ScriptPath = $(throw '$ScriptPath required.')
)
    try
    {
        if (!(Test-Path $ScriptPath)) {throw "Cannot find folder $ScriptPath"}
        $FileList = GetFileList -Directory $ScriptPath
        $ConnectionString = CreateConnectionString -ServerName $ServerName -DatabaseName master -IntegratedSecurity $True
        $SqlConnection = CreateConnection -ConnectionString $ConnectionString
        $SqlConnection.Open()
        
        foreach ($File in $FileList)
        {
            LogInfo "Running SQL script $($File.Name)"
            $SqlFileContents = ReadFile -FileName $File.FullName
            ExecuteSQL -SqlConnection $SqlConnection -Sql $SqlFileContents
        }
        CloseConnection -SqlConnection $SqlConnection
    }
    catch
    {
        LogErrorObject $_;throw $_;
    } 
};

function CreateSQLLinkedServer()
{
    param (
        [Parameter(Mandatory=$true)][string]$Instance,
        [Parameter(Mandatory=$true)][string]$DataSource,
        [Parameter(Mandatory=$true)][string]$RemoteUser,
        [Parameter(Mandatory=$true)][string]$RemotePassword,
        [switch]$Drop = $True
    )
    try 
    {
        $ProductName='SQL Server'
        
        $DataSource = $DataSource.ToUpper()
        $Server = New-Object Microsoft.SQLServer.Management.Smo.Server ($Instance)
        
        $CheckUser = $Server.LinkedServers | ?{$_.Name -eq $DataSource} | %{$_.LinkedServerLogins[0]}
        $CheckLinkedServer = $Server.LinkedServers | ?{$_.Name -eq $DataSource}
        
        if ($CheckLinkedServer -and $Drop)
        {
            if ($CheckUser) {$CheckUser.Drop()}
            if ($CheckLinkedServer) {$CheckLinkedServer.Drop()}
        } 
        elseif ($CheckLinkedServer -and !$Drop)
        {
            throw{"The linked server $Name already exists.  Pass -Drop to drop and recreate."};
        }
        
        $LinkedServer = New-Object Microsoft.SQLServer.Management.Smo.LinkedServer($Server, $DataSource)
        $LinkedServer.DataSource = $DataSource
        $LinkedServer.ProductName = "SQL Server"
        
        $LinkedServerLogin = New-Object Microsoft.SQLServer.Management.Smo.LinkedServerLogin
        $LinkedServerLogin.Name=''
        $LinkedServerLogin.Parent = $LinkedServer
        $LinkedServerLogin.Impersonate = $False
        $LinkedServerLogin.RemoteUser = $RemoteUser
        $LinkedServerLogin.SetRemotePassword($RemotePassword)
        
        LogInfo "Creating linked server $DataSource..."
        $LinkedServer.create() 
        $LinkedServerLogin.Create()
        LogInfo "Linked server $DataSource created."
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }
};    
#encrypts passwords to be stored in the config.xml file.
function Encrypt-String
{
	param (
	    $String = $(throw '$String required.'),
	    $Passphrase = $(throw '$Passphrase required.'),
	    $salt = $(throw 'sSalt required.'),
	    $init="XV_Password",
	    [switch]$arrayOutput
)

   $r = new-Object System.Security.Cryptography.RijndaelManaged
   $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase)
   $salt = [Text.Encoding]::UTF8.GetBytes($salt)

   $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
   $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]
   
   $c = $r.CreateEncryptor()
   $ms = new-Object IO.MemoryStream
   $cs = new-Object Security.Cryptography.CryptoStream $ms,$c,"Write"
   $sw = new-Object IO.StreamWriter $cs
   $sw.Write($String)
   $sw.Close()
   $cs.Close()
   $ms.Close()
   $r.Clear()
   [byte[]]$result = $ms.ToArray()
   if($arrayOutput) 
   {
      return $result
   } else
   {
     return [Convert]::ToBase64String($result)
   }
};

#decrypts passwords stored in the config.xml file.
function Decrypt-String
{
	param (
	    $Encrypted = $(throw '$Encrypted required.'),
	    $Passphrase = $(throw '$Passphrase required.'),
	    $salt = $(throw 'salt required.'),
	    $init="XV_Password"t
	)
    try
    {
       if($Encrypted -is [string]){
          $Encrypted = [Convert]::FromBase64String($Encrypted)
       }
     
       $r = new-Object System.Security.Cryptography.RijndaelManaged
       $pass = [System.Text.Encoding]::UTF8.GetBytes($Passphrase)
       $salt = [System.Text.Encoding]::UTF8.GetBytes($salt)
     
       $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
       $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]
     
       $d = $r.CreateDecryptor()
       $ms = new-Object IO.MemoryStream @(,$Encrypted)
       $cs = new-Object Security.Cryptography.CryptoStream $ms,$d,"Read"
       $sr = new-Object IO.StreamReader $cs
       Write-Output $sr.ReadToEnd()
       $sr.Close()
       $cs.Close()
       $ms.Close()
       $r.Clear()
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

function ReadFile {
param (
    [String]$FileName
)
    try
    {
        StackDebug -Enter
        
        if (!$FileName) {throw '$FileName required.'}
        
        $RetValue = Get-Content $FileName | Out-String
        StackDebug -Exit
        return $RetValue

    }
    catch
    {
    LogErrorObject $_;throw $_;
    }    
};

function ExecuteSQL {
param (
    [System.Data.SqlClient.SqlConnection]$SqlConnection,
    [String]$Sql
)
    try
    {
        StackDebug -Enter
        
        if (!$SqlConnection) {throw '$SqlConnection required.'}
        if (!$Sql) {throw '$Sql required.'}
        
        $Server = New-Object Microsoft.SqlServer.Management.Smo.Server($SqlConnection)
        return $Server.ConnectionContext.ExecuteNonQuery($Sql)
    }
    catch
    {
        LogErrorObject $_;throw $_;
    }        
};

function CreateConnectionString {
param (
    [String]$ServerName,
    [String]$DatabaseName,
    [Switch]$IntegratedSecurity,
    [String]$UserId,
    [String]$Password
)
    try
    {
        StackDebug -Enter
        if ($IntegratedSecurity)
        {
            $RetVal = "Server=$ServerName;Database=$Databasename;Integrated Security=True;"
        } else
        {
            $RetVal = "Server=$ServerName;Database=$DatabaseName;UID=$UserId;Pwd=$Password"    
        }
        
        Return $RetVal;
    }        
    catch
    {
        LogErrorObject $_;throw $_;
    }               
};

function CreateConnection {
param (
    [String]$ConnectionString
)
    try
    {
        StackDebug -Enter
        return New-Object System.Data.SqlClient.SqlConnection($ConnectionString);        
    }        
    catch
    {
        LogErrorObject $_;throw $_;
    }               
};

function CloseConnection {
param (
    [System.Data.SqlClient.SqlConnection]$SqlConnection
)
    try
    {
        StackDebug -Enter
        if ($SqlConnection.State -eq 'Open') {$SqlConnection.Close()}
    }        
    catch
    {
        LogErrorObject $_;throw $_;
    }               
};
