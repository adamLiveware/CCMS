# CCMS - Copilot Instructions

## Project Overview

**CCMS (Cloud Customer Management Solution)** is an open-source Business Central extension (AL) designed to help Microsoft Dynamics 365 Business Central partners manage and support their customers at scale. The solution enables partners to administer customer environments without requiring direct access, improving security and operational efficiency.

- **Repository**: https://github.com/directions4partners/ccms
- **Language**: AL (Application Language for Business Central)
- **Platform**: Microsoft Dynamics 365 Business Central (Cloud only)
- **Build System**: AL-Go for GitHub
- **License**: MIT

## Development Environment

### Technology Stack
- **AL Runtime**: 16.0
- **Business Central Application**: 27.0.0.0
- **Platform**: 1.0.0.0
- **Object ID Range**: 62000-62049
- **Namespace Convention**: `D4P.CCMS.<FeatureArea>`

### Build and CI/CD
- Uses **AL-Go for GitHub** for build automation and CI/CD
- Configuration file: `.github/AL-Go-Settings.json`
- Main workflow: `.github/workflows/CICD.yaml`
- Runs on: `ubuntu-latest` runners
- For AL-Go settings questions, consult `.github/.agents/algo-settings.agent.md`

### Project Structure
```
CCMS/
├── src/
│   ├── Auth/           # Authentication and authorization
│   ├── Backup/         # Environment backup management
│   ├── Capacity/       # Capacity and storage tracking
│   ├── Customer/       # Customer management
│   ├── Environment/    # Environment operations
│   ├── Extension/      # Extension/app management
│   ├── Features/       # Feature modules
│   ├── General/        # General utilities and helpers
│   ├── Operation/      # Operations tracking
│   ├── Permissions/    # Permission sets and security
│   ├── Session/        # Session management
│   ├── Setup/          # Setup and configuration
│   ├── Telemetry/      # Telemetry and logging
│   └── Tenant/         # Tenant management
├── Translations/       # Language translations
├── .vscode/           # VS Code configuration
└── app.json           # Extension manifest
```

## Code Style and Conventions

### Naming Conventions
- **Prefix**: All objects use `D4P` prefix (Directions for Partners)
- **Object Names**: Follow pattern `D4P BC <ObjectName>`
  - Tables: `D4P BC Customer`, `D4P BC Setup`
  - Pages: `D4P BC Customers List`, `D4P BC Admin Role Center`
  - Codeunits: `D4P BC API Helper`, `D4P BC Operations Helper`
  - Enums: `D4P Export Status`, `D4P Operation Type`
- **Namespaces**: Use `D4P.CCMS.<FeatureArea>` pattern
- **File Names**: Match object names with type suffix (`.table.al`, `.page.al`, `.codeunit.al`)

### AL Code Standards
- **Feature**: `NoImplicitWith` is enabled - always use explicit record references
- **Feature**: `TranslationFile` is enabled - use translation files for multilingual support
- **Data Classification**: Always specify appropriate data classification (typically `CustomerContent`)
- **Captions**: Always provide captions for fields and actions
- **ToolTips**: Add tooltips for user-facing fields
- **Security**: Use `SecretText` type for sensitive data (tokens, credentials)
- **HTTP Calls**: Always use proper error handling and response validation

### Code Quality
- Keep procedures focused and single-purpose
- Use meaningful variable names
- Add error labels for user-facing error messages
- Follow AL coding guidelines from Microsoft
- Maintain consistency with existing code patterns

## Key Design Principles

1. **Modular by Design**: Each feature area is independent and can work standalone
2. **Cloud-Native**: Focus exclusively on cloud deployments (no on-premises support)
3. **Security-First**: Follow secure-by-default principles with proper logging and permissions
4. **Minimal Data Collection**: Only collect and store data necessary for operations
5. **Partner-Centric**: Built for partners to manage customers at scale
6. **Simplicity**: Avoid over-complication - clear value over complexity

## Security and Compliance

- **Never commit secrets** or credentials to the repository
- **Use SecretText** type for all tokens and sensitive data
- **Data Classification**: Properly classify all table fields
- **Resource Exposure Policy**: 
  - `allowDebugging`: true
  - `allowDownloadingSource`: true
  - `includeSourceInSymbolFile`: true
- Follow security guidelines in `SECURITY.md`

## Governance and Contribution

- Review `GOVERNANCE.md` for Technical Steering Committee (TSC) model
- Follow `CODEOFCONDUCT.md` - all contributors must adhere to the Contributor Covenant
- See `MAINTAINERS.md` for maintainer responsibilities
- All contributions require signing the Contributor License Agreement (CLA)
- Decisions are made by TSC consensus with public discussion

## Testing and Quality Assurance

- Test app creation workflow: `.github/workflows/CreateTestApp.yaml`
- Performance test workflow: `.github/workflows/CreatePerformanceTestApp.yaml`
- Follow existing test patterns when adding new tests
- Ensure all API integrations have proper error handling
- Test both happy path and error scenarios

## Important Files

- `README.md` - Project overview and vision
- `CHANGELOG.md` - Version history and changes
- `GOVERNANCE.md` - Project governance model
- `CODEOFCONDUCT.md` - Code of conduct
- `MAINTAINERS.md` - Maintainer guide
- `SECURITY.md` - Security policy and vulnerability reporting
- `SUPPORT.md` - Support information
- `.github/RELEASENOTES.copy.md` - AL-Go release notes

## Working with AL-Go

- AL-Go manages versioning, builds, and releases automatically
- Settings are configured in `.github/AL-Go-Settings.json`
- Versioning strategy is set to mode 19 (see AL-Go documentation)
- Template repository: https://github.com/Freddy-D4P/AL-Go@main
- For AL-Go questions, refer to https://github.com/microsoft/AL-Go/blob/main/Scenarios/settings.md

## Common Tasks

### Adding a New Feature Area
1. Create new folder under `CCMS/src/<FeatureArea>/`
2. Use namespace `D4P.CCMS.<FeatureArea>`
3. Follow existing naming conventions with `D4P BC` prefix
4. Add appropriate permissions and error handling

### Adding New Tables
- Use ID range 62000-62049
- Set `DataClassification = CustomerContent`
- Define appropriate caption and data caption fields
- Specify DrillDownPageId and LookupPageId

### Adding API Integrations
- Follow patterns in `D4P BC API Helper` codeunit
- Use `SecretText` for authentication tokens
- Implement proper error handling and logging
- Use debug mode flag from setup for diagnostics

### Documentation
- Keep README.md up to date
- Document breaking changes in CHANGELOG.md
- Add inline comments for complex business logic only
- Use meaningful captions and tooltips instead of code comments where possible

## Goals and Non-Goals

### In Scope
✅ Cloud environment management
✅ Customer lifecycle automation
✅ Extension/PTE management
✅ Monitoring and health checks
✅ Backup and restore operations
✅ Permission and security management

### Out of Scope
❌ On-premises support
❌ DevOps platform lock-in
❌ Unnecessary telemetry collection
❌ Over-engineering features

## Support and Communication

- Email: freddy@directions4partners.com
- GitHub Issues: For feature requests and bug reports
- GitHub Discussions: For community questions
- Project Board: https://github.com/directions4partners/ccms/issues

---

When working on CCMS, prioritize security, simplicity, and the partner experience. Always consider how changes affect multiple customers and maintain the modular architecture that allows partners to adopt features incrementally.
