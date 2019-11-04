"# PowerShellReplicationTool" 
I wrote these functions/scripts back in 2012 to assist with setting up replication in a multi server/db environment. I used it with another set of tools for database creation (that I haven't uploaded).
This is just the replication piece. It requires that publisher/distributor/subscriber database have been created and proper security configured. You really need a few more function calls - I can add these scripts
if anybody wants to try it. Can add more detailed documentation as well - it's been a few years.

.\config
This directory contains the config files that can be used to drive the scripts.
	ex: TestReplicationConfig.xml

	The global variable file is setup to work with this directory structure.
	ReplicationVariables.ps1

.\functions
This directory contains 4 function files used by the various scripts functions. They are loaded as modules,

	CommonFunctions.psm1
	Contains functions that are common to this and other tool kits. It has functions such as Test-DB, Test-Table, Test-Login, etc.

	LogFunctions.psm1
	Contains functions for logging messages

	XMLConfigFunctions.psm1
	Contains functions for accessing the XML config files.

	ReplicationFunctions.psm1
	Contains all functions that are replication specific.

.
These are implementation scripts. They are all suffixed with Config because they requrire a config file for attributes such as Server Name, Publication Name, etc.