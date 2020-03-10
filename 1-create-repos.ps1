param (
	[Parameter(Mandatory=$true)] 
    [string] $organisationName,
	[Parameter(Mandatory=$true)] 
    [string] $projectName
)

$backgroundColor = $Host.UI.RawUI.BackgroundColor
$foregroundColor = $Host.UI.RawUI.ForegroundColor
  
function Reset-UI {
	$Host.UI.RawUI.BackgroundColor = $backgroundColor
	$Host.UI.RawUI.ForegroundColor = $foregroundColor
}

$settingsFile = '.\bootstrap.json'
$config = ( Get-Content -Raw $settingsFile | Out-String | ConvertFrom-Json )

if ($config -eq $null)
{
	Write-Host "error loading the config file - quitting process"
	return $false
}

Write-Host ""
Write-Host "------------------------------------"
Write-Host "Please confirm your account details."
Write-Host "------------------------------------"

az account show

Write-Host ""

$confirmationMessage = "are you sure you want to proceed: Y(Yes): N(No)"
$confirmation = Read-Host $confirmationMessage

if ($confirmation -ne "Y")
{
	Write-Host "stopping execution..."
	return $false
}

$organisationPath = $config.project.orgPath + $organisationName

Write-Host ""

Write-Host "---------------------------------------------------------"
Write-Host "Please confirm organisation and project exists in devops."
Write-Host "---------------------------------------------------------"
Write-Host ""
Write-Host "projectName: $projectName"
Write-Host "organisationPath: $organisationPath"
Write-Host ""

$confirmation = Read-Host $confirmationMessage

if ($confirmation -ne "Y")
{
	Write-Host "stopping execution..."
	return $false
}

Write-Host "proceeding to set the project and organisation"
az devops configure --defaults organization=$organisationPath project=$projectName
Reset-UI

Write-Host "attempting to retrieve project id for project name: $projectName"
$projectId = az devops project show --project $projectName --query id --output TSV
Reset-UI

if ($projectId -eq $null) {
	Write-Host "project name: $projectName not found in organisation - please check and try again..."
	return $false
}

$config.project.repos | foreach {
	$repo = $_
	$repoName = $repo.name
	$branchName = $repo.branch
	$bootstrapUrl = $repo.bootstrapUrl
	
	$repoId = az repos show --repository $repoName --project $projectName --query id --output TSV
	Reset-UI	
	
	if ($repoId -eq $null) {
		Write-Host "creating repo: $repoName in project: $projectName"
		az repos create --name $repoName --project $projectName
		Reset-UI
		
		Write-Host "Initialising repo with source from: $bootstrapUrl"
		az repos import create --git-source-url $bootstrapUrl --project $projectName --repository $repoName 
		Reset-UI
		
		$repoId = az repos show --repository $repoName --project $projectName --query id --output TSV
		Reset-UI	
		
		Write-Host "Initialising branch policy on repo master branch"
		az repos policy merge-strategy create --blocking $true --branch $branchName --enabled $true --repository-id $repoId --allow-squash $true
		Reset-UI	
	}
	else {
		Write-Host "repo: $repoName already exists with id: $repoId - skipping creation"
	}
}