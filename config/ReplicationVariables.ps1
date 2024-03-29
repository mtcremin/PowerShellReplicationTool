#USER_CONFIG
$GLOBAL:_LogDir = ".\Log\Replication"
$GLOBAL:_LogFileName = 'ReplicationLog.txt'
[Bool]$GLOBAL:_LogCreateTimeStampSubDir = $True
$GLOBAL:_LoggingLevel = 3
#/USER_CONFIG

#SYSTEM_CONFIG
$LOCAL:LogModuleDir = ".\Functions"
$LOCAL:LogModuleFile = 'LogFunctions.psm1'
$GLOBAL:_LogModule = $LOCAL:LogModuleDir + '\' + $LOCAL:LogModuleFile

$LOCAL:CommonModuleDir = ".\Functions"
$LOCAL:CommonModuleFile = 'CommonFunctions.psm1'
$GLOBAL:_CommonModule = $LOCAL:CommonModuleDir + '\' + $LOCAL:CommonModuleFile

$LOCAL:ReplicationModuleDir = ".\Functions"
$LOCAL:ReplicationModuleFile = "ReplicationFunctions.psm1"
$GLOBAL:_ReplicationModule = $LOCAL:ReplicationModuleDir + '\' + $LOCAL:ReplicationModuleFile

$LOCAL:XMLConfigModuleDir = ".\Functions"
$LOCAL:XMLConfigModuleFile = "XMLConfigFunctions.psm1"
$GLOBAL:_XMLConfigModule = $LOCAL:XMLConfigModuleDir + '\' + $LOCAL:XMLConfigModuleFile

$GLOBAL:_ConfigDir = ".\Config"
#/SYSTEM_CONFIG