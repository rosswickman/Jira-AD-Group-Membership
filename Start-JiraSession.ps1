## Set Session and Connection information
## ###########################################
$jiraServer = 'https://jira-server:8080'
$username = 'username'
$password = 'password'
## ###########################################

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$secpasswd
Set-JiraConfigServer $jiraServer
$jiraSession = New-JiraSession -Credential (Get-Credential $mySecureCreds)
