$_INFO = 'INFO'
$_WARNING = 'WARN'
$_ERROR = 'ERROR'
$_DEBUG = 'DEBUG'
$LogSubDir = Get-Date –f 'yyyy-MM-dd-HH-mm'
$LogStampFormat = 'yyyy-MM-dd HH:mm:ss'

if (!$GLOBAL:_LogCreateTimeStampSubDir) {$LogCreateTimeStampSubDir = $False} else {$LogCreateTimeStampSubDir = $GLOBAL:_LogCreateTimeStampSubDir}
if (!$GLOBAL:_LoggingLevel) {$LoggingLevel = 3} else {$LoggingLevel = $GLOBAL:_LoggingLevel}
if (!$GLOBAL:_LogFileName) {$LoggingLevel = 1}
if (!$GLOBAL:_LogDir) {$LogDir = '.'} else {$LogDir = $GLOBAL:_LogDir}
if (!$GLOBAL:_LogFileName) {$LogFileName = "$LogSubDir_logfile.txt"} else {$LogFileName = $GLOBAL:_LogFileName}

if ($_LogCreateTimeStampSubDir) 
{
    $LogFileFullPath = "$LogDir\$LogSubDir\$LogFileName"
    $LogSubDirFullPath = "$LogDir\$LogSubDir"
} 
else 
{
    $LogFileFullPath = "$LogDir\$LogFileName"
    $LogSubDirFullPath = $LogDir
}


function StackDebug {
param (
    [Switch]$Enter,
    [Switch]$Exit
)
    try
    {
        if ($Debug)
        {
            $Msg = "`t$((Get-PSCallStack)[1].Command)"
            if ($Enter) {$Msg = "ENTER: $Msg | $((Get-PSCallStack)[1].Arguments)"}
            elseif ($Exit) {$Msg = "EXIT: $Msg"}
            else {$Msg = "UNKNOWN SWITCH"}
            LogMsg -Msg $Msg -Type $_DEBUG
        }
    }
    catch
    {
		throw $_;
    }    
};

function LogDebug {
param (
    [String]$Msg = $(throw '$Msg required.')
)
    try
    {
        if ($Debug)
        {
            LogMsg -Msg $Msg -Type $_DEBUG
        }
    }
    catch
    {
        throw $_;
    }      

};

function LogInfo {
param (
    [String]$Msg = $(throw '$Msg required.')
)
    try
    {
        LogMsg -Msg $Msg -Type $_INFO              
    }
    catch
    {
        throw $_;
    }          
};

function LogWarning {
param (
    [String]$Msg = $(throw '$Msg required.')
)
    try
    {
        LogMsg -Msg $Msg -Type $_WARNING
    }
    catch
    {
        throw $_;
    }      
};

function LogError {
param (
    [String]$Msg = $(throw '$Msg required.')
)
    try
    {
        LogMsg -Msg $Msg -Type $_ERROR
    }
    catch
    {
        throw $_;
    }      
};

function LogErrorObject {
param (
    $ErrorObject = $(throw '$Error required.')
)
    try
    {
        LogError "CALLSTACK: COMMAND:$((Get-PSCallStack)[1].Command) LOCATION:$((Get-PSCallStack)[1].Location)"
        $ErrorCount = 0
        
        #check to see if this is the "last" calling program.  If not, return.
        if (!(((Get-PSCallStack)[2].Command -eq 'prompt') -or ((Get-PSCallStack)[2].Command -ne 'prompt' -and (Get-PSCallStack).length -eq 2)))
        {
            return
        }
        LogError "Error Info:"
        LogError "Line: $($ErrorObject.InvocationInfo.Line.Trim())"
        LogError "LineNumber: $($ErrorObject.InvocationInfo.ScriptLineNumber)"
        LogError "OffsetInLine: $($ErrorObject.InvocationInfo.OffsetInLine)"
        
        #while loop to iterate through the inner exceptions
        $ThisException = $ErrorObject.Exception
        while ($ThisException.InnerException -ne $Null)
        {
            LogError $ThisException.Message
            $ThisException = $ThisException.InnerException
        }
        
       
        
        #sql exception?
        if ($ThisException.GetType().Name -eq 'SqlException')
        {
            LogError "Exception Type: $($ThisException.GetType().Name)"
            LogError "Errors: $(($ThisException.Errors).Count)"
            foreach($SqlError in $ThisException.Errors)
            {
                $ErrorCount += 1
                LogError "Error: $ErrorCount"
                LogError "Source: $($SqlError.Source)"
                LogError "Server: $($SqlError.Server)"
                LogError "Msg: $($SqlError.Number), Level $($SqlError.Class), State $($SqlError.State), Line $($SqlError.LineNumber)"
                LogError "Message: $($SqlError.Message)"
                LogError "Procedure: $($SqlError.Procedure)"
                
            }
        }    
        else
        {
            LogError $ThisException.Message
        }      
        
    }
    catch
    {
        throw $_;
    }      
};

function LogMsg {
param (
    [String]$Msg = $(throw '$Msg required.'),
    [String]$Type = 'INFO'
)
    try
    {
        CheckCreateLogDir $GLOBAL:_LogDir
        
        if ($LogCreateTimeStampSubDir)
        {
            CheckCreateLogDir -LogDir $LogSubDirFullPath 
        }
        
        [String]$LogDateStamp = (Get-Date –f $LogStampFormat) + "`t"
    
        $Cmd = "Write-Output"
        
        $Type = $Type + "`t"
        
        $Output = $LogDateStamp + $Type + $Msg
        
        if ($LoggingLevel -eq 1) #screen
        {
            Write-Host $Output
        } elseif ($LoggingLevel -eq 2)
        {
            $Output | Out-File $LogFileFullPath -append 
        } elseif ($LoggingLevel -eq 3)
        {
            Write-Host $Output
            $Output | Out-File $LogFileFullPath -append 
        }
    }
    catch
    {
	   throw $_;
    }      

};

function SetLogFile {
try
    {
        if ($LogCreateDir) 
        {
            return "$_LogDir\$LogSubDir\$_LogFileName"
        } 
        else 
        {
            return "$_LogDir\$_LogFileName"
        }
    }        
    catch
    {
	   throw $_;
    }   
};

function CheckCreateLogDir {
param (
    [String]$LogDir = $(throw '$LogDir required.')
)
try
    {
        if (!(test-path -Path $LogDir)) 
        {
            New-Item -Path $LogDir -ItemType directory | Out-Null
        }
    }
catch
    {
        throw $_;
    }      
};

function LogCallStack {
    try
    {
        LogError "CALLSTACK: COMMAND:$((Get-PSCallStack)[1].Command) LOCATION:$((Get-PSCallStack)[1].Location)"
    }
    catch
    {
        throw $_;
    }                    
};