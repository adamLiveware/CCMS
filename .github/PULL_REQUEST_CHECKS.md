# Pull Request Compilation Checks

## Overview

This repository is configured to automatically compile AL code on pull requests to the `main` branch using AL-Go for GitHub. The setup is intentionally minimal and focuses solely on:

1. **Compilation validation** - Ensuring the code compiles successfully
2. **Code analysis** - Running CodeCop, UICop, and PerTenantExtensionCop analyzers
3. **Fast feedback** - Using compiler folder mode for quick builds without containers

## What Runs on Pull Requests

When a pull request is created or updated targeting the `main` branch:

1. The workflow checks out the PR's merge commit
2. Downloads necessary dependencies using NuGet
3. Compiles the AL code using the compiler folder approach
4. Runs code analyzers (CodeCop, UICop, PTECop)
5. Uploads analysis results to GitHub Security tab
6. Reports success or failure

## What Does NOT Run

To keep builds fast and focused, the following are disabled:

- ❌ Running tests (doNotRunTests: true)
- ❌ Running BCPT tests (doNotRunBcptTests: true)
- ❌ Building and saving app artifacts long-term (shortLivedArtifactsRetentionDays: 1)
- ❌ Publishing apps to any environment
- ❌ Container-based builds (uses compiler folder instead)

## AL-Go Configuration

The key settings in `.github/AL-Go-Settings.json`:

```json
{
  "useCompilerFolder": true,              // Fast compilation without containers
  "doNotPublishApps": true,               // No publishing to environments
  "doNotRunTests": true,                  // Skip all tests
  "doNotRunBcptTests": true,              // Skip BCPT tests
  "enableCodeCop": true,                  // Run CodeCop analyzer
  "enableUICop": true,                    // Run UICop analyzer
  "enablePerTenantExtensionCop": true,    // Run PTECop analyzer
  "trackALAlertsInGitHub": true,          // Upload results to GitHub Security
  "shortLivedArtifactsRetentionDays": 1   // Keep artifacts for 1 day only
}
```

## Enforcing Successful Builds with Branch Protection

To block pull requests that don't compile successfully, you need to enable GitHub branch protection rules:

### Step-by-Step Instructions

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click on `Settings` (top right menu)
   - In the left sidebar, click on `Branches` under "Code and automation"

2. **Add Branch Protection Rule**
   - Click the `Add branch protection rule` button (or edit existing rule for `main`)
   - In the "Branch name pattern" field, enter: `main`

3. **Configure Required Status Checks**
   - ✅ Check `Require status checks to pass before merging`
   - ✅ Check `Require branches to be up to date before merging` (optional but recommended)
   - In the search box under "Status checks that are required", search for and select:
     - `Pull Request Status Check` (this is the final status check from the workflow)
     - Optionally also select individual build jobs like `Build CCMS (Default)`

4. **Additional Recommended Settings**
   - ✅ Check `Require a pull request before merging`
   - ✅ Check `Require approvals` (set to at least 1)
   - ✅ Check `Dismiss stale pull request approvals when new commits are pushed`
   - ✅ Check `Do not allow bypassing the above settings`

5. **Save Changes**
   - Scroll to the bottom and click `Create` or `Save changes`

### What This Does

Once branch protection is enabled:

- ✅ Pull requests cannot be merged until the `Pull Request Status Check` passes
- ✅ The PR merge button will be disabled if compilation fails
- ✅ Code analysis alerts will appear in the PR's "Checks" tab and Security tab
- ✅ Contributors get immediate feedback on compilation errors

## Workflow File

The PR build workflow is located at: `.github/workflows/PullRequestHandler.yaml`

## Troubleshooting

### Build Fails with Missing Dependencies

If the build fails because of missing dependencies:
- Check that the `app.json` file has the correct dependency versions
- Ensure the `artifact` setting in AL-Go-Settings.json points to the correct BC version

### Code Analysis Warnings Block PR

Code analysis warnings (CodeCop, UICop, PTECop) are reported but don't block the PR by default. Only compilation errors block PRs.

If you want to treat warnings as errors, you can configure custom rulesets.

### Workflow Doesn't Trigger

Ensure that:
- The workflow file is in the `main` branch
- The PR is targeting the `main` branch
- GitHub Actions are enabled for the repository

## Additional Resources

- [AL-Go for GitHub Documentation](https://github.com/microsoft/AL-Go)
- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
