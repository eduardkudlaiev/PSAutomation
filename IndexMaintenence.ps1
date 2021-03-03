workflow IndexMaintenence
{

    function Execute-Index-Maintenance
{
	param(
        [parameter(Mandatory=$False)]
        [int] $SqlServerPort = 1433,

        [parameter(Mandatory=$True)]
        [string] $Database
    )
	#add some change
    #Get user name for database 
    $UserNameForEnv = Get-AutomationVariable -Name SqlServerCredential
    $SqlServer = Get-AutomationVariable -Name DbServer

	# Get the username and password from the SQL Credential

	$SqlCredential = Get-AutomationPSCredential -Name $UserNameForEnv
   
    if ($SqlCredential -eq $null) 
    { 
        throw "Could not retrieve 'SqlServer' credential asset. Check that you created this first in the Automation service." 
    }   
    
    $SqlUsername = $SqlCredential.UserName 
    $SqlPass = $SqlCredential.GetNetworkCredential().Password 
    
	$Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$SqlServer,$SqlServerPort;Database=$Database;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")
	
    # Open the SQL connection
	$Conn.Open()

	# Define the SQL command to run. In this case we are getting the number of rows in the table
	$sql = "
        EXECUTE dbo.IndexOptimize
        @FragmentationLow = NULL,
        @FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
        @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
        @FragmentationLevel1 = 5,
        @FragmentationLevel2 = 30,
        @UpdateStatistics = 'ALL',
        @OnlyModifiedStatistics = 'Y'
	"

	$Cmd=new-object system.Data.SqlClient.SqlCommand($sql, $Conn)
	$Cmd.CommandTimeout=0

	# Execute the SQL command
    $Cmd.ExecuteScalar()

	# Close the SQL connection
	$Conn.Close()
}
    #Setup values for variables
    $scrub_scraping = Get-AutomationVariable -Name scrubScrapping
    $scrub_identity = Get-AutomationVariable -Name scrubIdentity
    $scrub_crm = Get-AutomationVariable -Name scrumCRMDB
    $scrub = Get-AutomationVariable -Name scrubDB

    #Start execution in parallel
    Parallel
    {    
        Execute-Index-Maintenance -Database $scrub
        Execute-Index-Maintenance -Database $scrub_crm
        Execute-Index-Maintenance -Database $scrub_identity
        Execute-Index-Maintenance -Database $scrub_scraping
    }

    Write-Output "Maintenance done."
}
