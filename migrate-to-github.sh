#!/bin/bash

# GitLab to GitHub Migration Script
# This script helps automate the migration process

set -e

echo "🚀 GitLab to GitHub Migration Script"
echo "====================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Function to prompt for user input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            echo "This field is required."
            read -p "$prompt: " input
        done
    fi
    
    eval "$var_name='$input'"
}

# Get GitHub repository details
echo
echo "📝 GitHub Repository Configuration"
echo "----------------------------------"
prompt_input "GitHub username" GITHUB_USER
prompt_input "Repository name" REPO_NAME "transaction-management-api"
prompt_input "Make repository private? (y/n)" IS_PRIVATE "n"

# Construct GitHub URL
GITHUB_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

echo
echo "🔍 Configuration Summary"
echo "-----------------------"
echo "GitHub URL: $GITHUB_URL"
echo "Private: $IS_PRIVATE"

read -p "Continue with migration? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Migration cancelled."
    exit 0
fi

echo
echo "🔄 Starting Migration Process"
echo "-----------------------------"

# Backup current remotes
echo "📋 Backing up current remotes..."
git remote -v > .git_remotes_backup.txt
echo "   Backup saved to .git_remotes_backup.txt"

# Remove GitLab remote (if exists)
if git remote get-url origin >/dev/null 2>&1; then
    echo "🗑️  Removing GitLab remote..."
    git remote remove origin
fi

# Add GitHub remote
echo "➕ Adding GitHub remote..."
git remote add origin "$GITHUB_URL"

# Verify remote
echo "✅ Verifying remote..."
git remote -v

# Check if we have uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes"
    read -p "   Commit them now? (y/n): " commit_changes
    if [ "$commit_changes" = "y" ]; then
        git add .
        git commit -m "chore: Prepare for GitHub migration"
    fi
fi

# Push to GitHub
echo "⬆️  Pushing to GitHub..."
echo "   Note: You may need to authenticate with GitHub"

# Try to push main branch
if git branch | grep -q "main"; then
    git push -u origin main
elif git branch | grep -q "master"; then
    git push -u origin master
else
    echo "❌ No main or master branch found"
    exit 1
fi

# Push all branches
echo "📤 Pushing all branches..."
git push origin --all

# Push tags
echo "🏷️  Pushing tags..."
git push origin --tags || echo "   No tags to push"

echo
echo "🎉 Migration Complete!"
echo "====================="
echo
echo "✅ Repository successfully migrated to GitHub"
echo "📍 GitHub URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo
echo "🔧 Next Steps:"
echo "1. Go to your GitHub repository: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "2. Configure repository secrets (Settings → Secrets and variables → Actions):"
echo "   - STAGING_DEPLOY_WEBHOOK"
echo "   - PRODUCTION_DEPLOY_WEBHOOK"
echo "3. Configure repository variables:"
echo "   - STAGING_URL"
echo "   - PRODUCTION_URL"
echo "   - HEALTH_CHECK_URL"
echo "4. Set up GitHub Environments (Settings → Environments):"
echo "   - staging"
echo "   - production"
echo "5. Test the GitHub Actions workflow by making a commit"
echo
echo "📚 Documentation:"
echo "   - Migration Guide: GITHUB_MIGRATION.md"
echo "   - Deployment Guide: GITHUB_DEPLOYMENT.md"
echo "   - Updated README: README.md"
echo
echo "🆘 Need help? Check the troubleshooting section in GITHUB_MIGRATION.md"
echo
echo "Happy coding! 🚀"
