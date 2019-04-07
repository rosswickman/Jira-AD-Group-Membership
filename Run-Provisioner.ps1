## REQUIRED PARAMETERS FOR CONNECTING TO JIRA SERVER
Param(
    [parameter(Mandatory=$true, position=0)]
    [String]$server,
    [parameter(Mandatory=$true, position=1)]
    [String]$username,
    [parameter(Mandatory=$true, position=3)]
    [String]$password
)

## Takes Jira Ticket 'Reporter' field and finds user object in Active Directory
## Some AD user accounts may use the same email attribute value and Jira usernames may or maynot be an email address
function Get-ADsamAccountName {
    PARAM(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $reporter
    )

    ## Validate is reporter is email username or username
    try {
        $null = [mailaddress]$reporter
        $isEmail = $true
    }
    catch {
        $isEmail =  $false
    }

    ## Look for user in Active Directory
    try{ 
        if($isEmail) {
            $reporter = Get-ADUser -Filter { emailaddress -Like $reporter } -Properties emailaddress -ErrorAction Ignore
            ## UPN may be required if AD user has multiple accounts using the mail attribute.
            #$reporter = Get-ADUser -Filter { userPrincipalName -Like $reporter } -Properties userPrincipalName -ErrorAction Ignore
        }
        
        $user = Get-ADUser -Identity $reporter
        $user
        return

    } catch {
        ## ADD LOGGING FOR WHEN A USER IS NOT FOUND AND CONTINUE PROVISIONING
        Write-Warning "Could not find AD user for: $reporter"
        Write-Error $_ -ErrorAction Ignore
    }
} ## END Get-ADsamAccountName

## Loops through all issues returned matching configuration file
## Adds Jira issue Reporter to AD Security groups in config file
function Update-ADGroups {
    PARAM
    (
         [Parameter(Mandatory=$true, Position=0)]
         $issues,
         [Parameter(Mandatory=$true, Position=1)]
         $params
    )

    foreach($issue in $issues){
        $user = Get-ADsamAccountName -Reporter $issue.Reporter.Name

        $params.ActiveDirectory.Groups | % { 
            Add-ADGroupMember -Identity $_ -Members $user 
            Write-Verbose "User: $user added to AD Security Group: $_"
        }
       
        Update-Issue -IssueKey $issue.key -Params $params
    }
} ## END Update-ADGroups

## Update the current issue with tranistion details in configuration file
function Update-Issue {
    PARAM
    (
         [Parameter(Mandatory=$true, Position=0)]
         $issueKey,
         [Parameter(Mandatory=$true, Position=1)]
         $params
    )

    $parameters = @{
        ## Currently will only take a single label. Use 'Set-JiraIssueLabel' for more labels.
        Label = @("$($params.Transition.Labels)")
        AddComment = $params.Transition.Comment
    }

    Set-JiraIssue @parameters -Issue $issueKey

    $transition = Get-JiraIssue -Issue $issueKey | Select-Object -ExpandProperty Transition | ? {$_.Name -eq $params.Transition.Status}
    Invoke-JiraIssueTransition -Issue $issueKey -Transition $transition.ID

    Write-Verbose "Issue: $issueKey transitioned to Status: $($params.Transition.Status)"
} ## END Update-Issue

## Main Function
function Run-Provisioner {
    Param(
        [parameter(mandatory=$true, position=0)]
        [String]$server,
        [parameter(mandatory=$true, position=1)]
        [String]$username,
        [parameter(mandatory=$true, position=3)]
        [String]$password
    )

    BEGIN {
        ## Open Session with Jira Server 
        try{
            $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
            $mySecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$secpasswd
            Set-JiraConfigServer $server -ErrorAction Stop
            $jiraSession = New-JiraSession -Credential (Get-Credential $mySecureCreds)

            Write-Verbose "Connection to $server successful"

        } catch {
            Write-Warning "Could not authenticate to server. Please check connection details."
            Write-Error $_ -ErrorAction Stop
        }
    }

    ## Loops all configuration files to collect issues from respective projects that provision user access
    PROCESS{
        ## Gathers configuration files from working directory
        ## Each configuraiton file represents a unique subset of AD groups to be modified
        $configFiles = Get-ChildItem -Path .\Configs\ -Filter *.config -File -Name
        $CurrentLocation = Get-Location
        foreach($config in $configFiles){
            $params = (Get-Content $CurrentLocation\Configs\$config) | convertfrom-json 

            ## get all issues resulting from current configuration 
            $issueFilter = "project = '$($params.Issue.Project)' AND status = '$($params.Provision.Status)' AND issuetype = '$($params.Issue.Type)'"
            $issues = @()

            try{
                $issues = Get-JiraIssue -Query $issueFilter -ErrorAction Stop
                Update-ADGroups -Issues $issues -Params $params

            } catch {
                Write-Verbose "No issues in provision status for filter: $($params.Filter.Name)"
                Write-Error $_ -ErrorAction SilentlyContinue
            }

        }
        
    }

    END{
        Remove-JiraSession
        Write-Verbose "$jiraSession Closed"
    }
} ## END Run-Provisioner

Run-Provisioner -server $server -username $username -password $password
