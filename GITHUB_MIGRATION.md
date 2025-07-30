# GitLab to GitHub Migration Guide

## Overview
This guide helps you migrate your Transaction Management API from GitLab to GitHub while maintaining all CI/CD functionality.

## Migration Steps

### 1. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it `transaction-management-api` (or your preferred name)
3. Make it private/public as needed
4. **Do not** initialize with README, .gitignore, or license (we'll push existing content)

### 2. Update Remote Repository

```bash
# Remove GitLab remote
git remote remove origin

# Add GitHub remote (replace USERNAME/REPO with your details)
git remote add origin https://github.com/USERNAME/transaction-management-api.git

# Verify remote
git remote -v
```

### 3. Push Code to GitHub

```bash
# Push all branches
git push -u origin main
git push origin --all
git push origin --tags
```

### 4. Configure GitHub Secrets and Variables

#### Required Secrets (Repository Settings → Secrets and variables → Actions)

**Secrets:**
- `STAGING_DEPLOY_WEBHOOK` - Your staging deployment webhook URL
- `PRODUCTION_DEPLOY_WEBHOOK` - Your production deployment webhook URL

**Variables:**
- `STAGING_URL` - Your staging environment URL
- `PRODUCTION_URL` - Your production environment URL  
- `HEALTH_CHECK_URL` - URL for health checks

#### To add secrets:
1. Go to your GitHub repository
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the appropriate value

### 5. Configure GitHub Container Registry

The workflow automatically uses GitHub Container Registry (ghcr.io). Your Docker images will be stored at:
```
ghcr.io/USERNAME/transaction-management-api:latest
```

### 6. Set Up Environments (Optional but Recommended)

1. Go to Settings → Environments
2. Create environments: `staging` and `production`
3. Configure protection rules (e.g., require manual approval for production)

## Key Differences from GitLab

### CI/CD Features
| Feature | GitLab CI | GitHub Actions |
|---------|-----------|----------------|
| Pipeline file | `.gitlab-ci.yml` | `.github/workflows/ci-cd.yml` |
| Container Registry | GitLab Registry | GitHub Container Registry (ghcr.io) |
| Environments | Built-in | GitHub Environments |
| Secrets | CI/CD Variables | Repository Secrets |
| Artifacts | artifacts: | actions/upload-artifact |

### Workflow Differences

1. **Multi-platform builds**: GitHub Actions builds for both `linux/amd64` and `linux/arm64`
2. **Better caching**: Uses GitHub Actions cache for pip and Docker layers
3. **Codecov integration**: Automatic coverage reporting
4. **Matrix builds**: Can easily test multiple Python versions
5. **Manual deployment**: Production requires manual approval (safer)

### Container Registry

**GitLab:**
```bash
docker pull registry.gitlab.com/coretrading1/transaction-management-api:latest
```

**GitHub:**
```bash
docker pull ghcr.io/USERNAME/transaction-management-api:latest
```

## Webhook Configuration

If you're using the webhook deployment method, update your webhook receiver to expect images from GitHub Container Registry:

```bash
# Old GitLab image format
registry.gitlab.com/coretrading1/transaction-management-api:latest

# New GitHub image format  
ghcr.io/USERNAME/transaction-management-api:latest
```

## Testing the Migration

1. **Create a test branch:**
   ```bash
   git checkout -b test-github-actions
   git push origin test-github-actions
   ```

2. **Check Actions tab** in your GitHub repository to see the workflow run

3. **Test the workflow:**
   - Make a small change to `README.md`
   - Commit and push
   - Verify all jobs complete successfully

## Troubleshooting

### Common Issues

1. **Permission denied for GitHub Container Registry:**
   - Ensure `packages: write` permission is set in workflow
   - Check that `GITHUB_TOKEN` has correct permissions

2. **Workflow not triggering:**
   - Verify `.github/workflows/ci-cd.yml` is in the main branch
   - Check branch protection rules

3. **Docker build fails:**
   - GitHub Actions has different environment than GitLab
   - Check for any GitLab-specific configurations in Dockerfile

### Rollback Plan

If you need to rollback to GitLab:

```bash
# Add GitLab remote back
git remote add gitlab https://gitlab.com/coretrading1/transaction-management-api.git

# Push to GitLab
git push gitlab main
```

## Benefits of GitHub

1. **Better integration** with development tools
2. **Free private repositories** with generous CI/CD minutes
3. **GitHub Container Registry** included
4. **Advanced security features** (Dependabot, CodeQL)
5. **Better community** and marketplace integrations
6. **GitHub Copilot** integration
7. **Project management** tools (Issues, Projects, Discussions)

## Next Steps

1. **Update documentation** to reference GitHub instead of GitLab
2. **Configure branch protection** rules
3. **Set up Dependabot** for automatic dependency updates
4. **Enable CodeQL** for advanced security scanning
5. **Configure issue templates** for better project management

## Support

If you encounter issues during migration:
1. Check the Actions tab for detailed logs
2. Compare with working GitLab pipeline
3. Review GitHub Actions documentation
4. Consider GitHub community forums for help
