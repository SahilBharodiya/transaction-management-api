# GitLab to GitHub Migration Script (PowerShell)
# This script helps automate the migration process

param(
    [string]$GitHubUser,
    [string]$RepoName = "transaction-management-api",
    [switch]$Private
)

Write-Host "GitLab to GitHub Migration Script" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Function to prompt for user input
function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )
    
    if ($Default) {
        $userInput = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrEmpty($userInput)) {
            return $Default
        }
        return $userInput
    } else {
        do {
            $userInput = Read-Host $Prompt
            if ([string]::IsNullOrEmpty($userInput)) {
                Write-Host "This field is required." -ForegroundColor Yellow
            }
        } while ([string]::IsNullOrEmpty($userInput))
        return $userInput
    }
}

# Get GitHub repository details if not provided
Write-Host ""
Write-Host "GitHub Repository Configuration" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

if (-not $GitHubUser) {
    $GitHubUser = Get-UserInput "GitHub username"
}

if (-not $RepoName) {
    $RepoName = Get-UserInput "Repository name" "transaction-management-api"
}

if (-not $Private) {
    $privateInput = Get-UserInput "Make repository private? (y/n)" "n"
    $Private = $privateInput -eq "y"
}

# Construct GitHub URL
$GitHubUrl = "https://github.com/$GitHubUser/$RepoName.git"

Write-Host ""
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "---------------------" -ForegroundColor Cyan
Write-Host "GitHub URL: $GitHubUrl"
Write-Host "Private: $Private"

$confirm = Read-Host "Continue with migration? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting Migration Process" -ForegroundColor Cyan
Write-Host "---------------------------" -ForegroundColor Cyan

try {
    # Backup current remotes
    Write-Host "Backing up current remotes..." -ForegroundColor Yellow
    git remote -v | Out-File -FilePath ".git_remotes_backup.txt" -Encoding UTF8
    Write-Host "   Backup saved to .git_remotes_backup.txt"

    # Remove GitLab remote (if exists)
    try {
        git remote get-url origin 2>$null | Out-Null
        Write-Host "Removing GitLab remote..." -ForegroundColor Yellow
        git remote remove origin
    } catch {
        Write-Host "   No existing origin remote found"
    }

    # Add GitHub remote
    Write-Host "Adding GitHub remote..." -ForegroundColor Yellow
    git remote add origin $GitHubUrl

    # Verify remote
    Write-Host "Verifying remote..." -ForegroundColor Yellow
    git remote -v

    # Check if we have uncommitted changes
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "Warning: You have uncommitted changes" -ForegroundColor Yellow
        $commitChanges = Read-Host "   Commit them now? (y/n)"
        if ($commitChanges -eq "y") {
            git add .
            git commit -m "chore: Prepare for GitHub migration"
        }
    }

    # Push to GitHub
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    Write-Host "   Note: You may need to authenticate with GitHub" -ForegroundColor Cyan

    # Try to push main branch
    $branches = git branch
    if ($branches -match "main") {
        git push -u origin main
    } elseif ($branches -match "master") {
        git push -u origin master
    } else {
        throw "No main or master branch found"
    }

    # Push all branches
    Write-Host "Pushing all branches..." -ForegroundColor Yellow
    git push origin --all

    # Push tags
    Write-Host "Pushing tags..." -ForegroundColor Yellow
    try {
        git push origin --tags
    } catch {
        Write-Host "   No tags to push"
    }

    Write-Host ""
    Write-Host "Migration Complete!" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository successfully migrated to GitHub" -ForegroundColor Green
    Write-Host "GitHub URL: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to your GitHub repository: https://github.com/$GitHubUser/$RepoName"
    Write-Host "2. Configure repository secrets (Settings -> Secrets and variables -> Actions):"
    Write-Host "   - STAGING_DEPLOY_WEBHOOK"
    Write-Host "   - PRODUCTION_DEPLOY_WEBHOOK"
    Write-Host "3. Configure repository variables:"
    Write-Host "   - STAGING_URL"
    Write-Host "   - PRODUCTION_URL"
    Write-Host "   - HEALTH_CHECK_URL"
    Write-Host "4. Set up GitHub Environments (Settings -> Environments):"
    Write-Host "   - staging"
    Write-Host "   - production"
    Write-Host "5. Test the GitHub Actions workflow by making a commit"
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host "   - Migration Guide: GITHUB_MIGRATION.md"
    Write-Host "   - Deployment Guide: GITHUB_DEPLOYMENT.md"
    Write-Host "   - Updated README: README.md"
    Write-Host ""
    Write-Host "Need help? Check the troubleshooting section in GITHUB_MIGRATION.md" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Happy coding!" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "Migration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Rollback options:" -ForegroundColor Yellow
    Write-Host "1. Restore GitLab remote from backup:"
    Write-Host "   git remote remove origin"
    Write-Host "   # Add your GitLab remote back manually"
    Write-Host ""
    Write-Host "2. Check .git_remotes_backup.txt for previous remote configuration"
    exit 1
}
