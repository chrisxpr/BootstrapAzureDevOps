# BootstrapAzureDevOps
This project automates creating repos in an Azure DevOps project using the az devops extension.

**Goal 1**

To streamline the creation of Azure DevOps Repos for a new project by:
* Creating some common repos
* Initialising the code structure
* Enforcing pull requests by a creating a merge policy on the new repo master branch

**Assumptions:**

* DevOps Organisation exists with an active project
* DevOps account is an administrator
* Azure CLI is installed

**How to run:**

To create the starter repos for your project follow the instructions below:

1. Clone the BootstrapAzureDevOps repo to your local machine. 
2. Open a powershell prompt

If you do not have an active cli session please run the command:

*az login*

If this is the first time running the devops extension please run the command:

*az extension add --name azure-devops*

3. Run 1-create-repos.ps1

3.1 Enter the name of your organisation

3.2 Enter the name of your project

Assuming both are valid the script will continue to create the 3 repos defined in bootstrap.json

**So what happened ?**

Assuming you now have three initialised repos lets dissect what happened:

The file bootstrap.json defines three repos to be created:
```
{
	"project" : {
		"description" : "json for bootstrapping repos in azure devops",
		"orgPath" : "https://dev.azure.com/",
		"repos" : [
			{
				"name" : "PlatformServices",
				"bootstrapUrl" : "https://github.com/chrisxpr/PlatformServicesTemplate"
			}
			{
				"name" : "AppLayer",
				"bootstrapUrl" : "https://github.com/chrisxpr/AppLayerTemplate"
			},
			{
				"name" : "BuildDefinition",
				"bootstrapUrl" : "https://github.com/chrisxpr/BuildDefinitionTemplate"
			}
		]
	}
}
```
The file 1-create-repos.ps1 contains the logic to:

**Set the organisation and project context to run under:**

*az devops configure --defaults organization=$organisationPath project=$projectName*

**Perform a check before running to make sure the id of the project exists**

*$projectId = az devops project show --project $projectName --query id --output TSV*

**Loop through the repo collection in the settings file**

*$config.project.repos | foreach {*

**Checks to make sure that the repo does not already exist**

*$repoId = az repos show --repository $repoName --project $projectName --query id --output TSV*
	
**If the repo is not found then proceed to create**

*az repos create --name $repoName --project $projectName*
		
**Initialise the repo with the code from the bootstrap git repo url**

*az repos import create --git-source-url $bootstrapUrl --project $projectName --repository $repoName*

**Finally create a policy on the master branch in the new repo**

*az repos policy merge-strategy create --blocking $true --branch $branchName --enabled $true --repository-id $repoId --allow-squash $true*

E-volia we have 3 repos ready to clone.

Please feel free to have a play and please any comments and suggestions much appreciated.

Enjoy 

**Additional documentation can be found here:**
https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops
https://docs.microsoft.com/en-us/cli/azure/ext/azure-devops/devops/project?view=azure-cli-latest

**Install Azure CLI**
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
