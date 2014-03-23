####################################################################################################
#  Script name:   	check_ms_sharepoint_health.ps1
#  Created on:    	17/03/2014																			
#  Author:        	D'Haese Willem
#  Version:			0.3.18
#  Purpose:       	Checks Microsoft SharePoint Heath. The plugin is still in testing phase. Tested on two different SharePoint farms and seems to work ok. Try at own risk.. ;)
#                 	
#  To do:			Try to integrate http://yuriburger.net/2012/04/03/get-sharepoint-health-score-using-powershell/
#
#					
#  History:       	17/03/2014 => First edit
#					18/03/2014 => Edit output
#  How to:			1) Put the script in the NSCP scripts folder
#					2) In the nsclient.ini configuration file, define the script like this:
#						check_ms_win_tasks=cmd /c echo scripts\check_ms_sharepoint_health.ps1 ; exit $LastExitCode | powershell.exe -command -
#					3) Make a command in Nagios like this:
#						check_ms_win_tasks => $USER1$/check_nrpe -H $HOSTADDRESS$ -p 5666 -t 60 -c check_ms_sharepoint_health
#					4) Configure your service like this:
#						- Make use of the above created command
#											
#
####################################################################################################

if ($PSVersionTable) {$Host.Runspace.ThreadOptions = 'ReuseThread'}

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$Status = 3
$ReportsList = [Microsoft.SharePoint.Administration.Health.SPHealthReportsList]::Local
$FormUrl = '{0}{1}?id=' -f $ReportList.ParentWeb.Url, $ReportsList.Forms.List.DefaultDisplayFormUrl

$ReportProblems = $ReportsList.Items | Where-Object {$_['Severity'] -ne '4 - Success'} | ForEach-Object {
    New-Object PSObject -Property @{
        Url = "<a href='$FormUrl$($_.ID)'>$($_['Title'])</a>"
        Severity = $_['Category']
        Explanation = $_['Explanation']
        Modified = $_['Modified']
        FailingServers = $_['Failing Servers']
        FailingServices = $_['Failing Services']
        Remedy = $_['Remedy']
    }
} 

if ($ReportProblems.count -gt "0") {
	Write-Host "SharePoint Health Analyzer detected problems:"
	foreach($ReportProblem in $ReportProblems) {
		if ($ReportProblem.FailingServers) {
			$ServerString = " on " + $ReportProblem.FailingServers -replace "(?m)[`n`r]+",""
		}
		else {
			$ServerString = ""
		}
		Write-Host "Service $($ReportProblem.FailingServices)$ServerString, modified $($ReportProblem.Modified)"
	}
	$Status = 2
}
else {
	Write-Host "No SharePoint health problems detected!"
	$Status = 0
}

exit $Status
