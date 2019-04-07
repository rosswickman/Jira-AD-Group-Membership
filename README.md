# Jira Active Directory (AD) Group Access

This project uses JiraPS to automate AD Group membership by submitted and approved Jira Issues.

After a Jira issue passes into a particular status, the script will add the submitter/reporter of the issue to groups defined in specific configuration files.

This process works well for logging and subsequently provisioning access to a particular service. Access to different services can be provisioned by leveraging different Jira Projects and/or Issue Types.

## Getting Started

These instructions will get you a copy of the project up and running on your local domain. Also included in this project are example configuration files for deploying users into multiple groups per service request.

### Prerequisites

In order to successfully run this automation you will need the following.

* PowerShell PSVerion 5.1.x (Window Managment Framework 5.1)
* Jira Server accessible internal or external
* Jira user account with permissions to manipulate issues in all project used for automation
* Active Directory Administrative (Organizational Unit Level) Access in your domain structure
* Permissions to configure Windows scheduled tasks with AD Service account

### Installing

This project is built off of the [https://atlassianps.org](https://atlassianps.org) JiraPS PowerShell Module. 

Install the PowerShell module on the system running this script using: 

```
Install-Module JiraPS
```

Import the module with:

```
Import-Module JiraPS
```

And frequently update the module using:

```
Update-Module JiraPS
```

Additional details are very well documented here: [JiraPS](https://atlassianps.org/docs/JiraPS/)

## Running the script

The Script requires 3 parameters to run (server, username, & password)
These parameters can be hardcoded or passed at script execution:
```
.\Run-Provisioner.ps1 -server https://serveraddress:8080 -username username -password password
```
Use `-Verbose` for more details results while running the script.

## Configuration
Add additional configurations by duplicating \Configs\example.config and modifying Jira Project/Issue Details as well as the AD Groups being provided access to.

## Contributing
Please submit any issues or feature requests to this project for specific functionality.
New configurations and customizations are added frequently. Your feedback, recommendations, and support are highly encouraged.

## Authors
* **Ross Wickman** - *Initial work* - [Ross Wickman](https://rosswickman.com)

## License
This project is licensed under the MIT License
