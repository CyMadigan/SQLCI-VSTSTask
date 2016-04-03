# SQLCI-VSTSTask
This is the SQL CI task for Visual Studio Team Services (VSTS).

## Tasks
There are 2 tasks:
- SQL CI - Choose one of the the four actions of SQL CI
- Upgrade Advisor - Produces a report on the forwards-compatibilty of a database

## Structure
- extension-manifest.json defines most of the metadata about the plugin.
- images\ is various images shown in the marketplace. These are referenced by extensions-manifest.json.
- overview.md is a markdown file. This is the text shown in the marketplace.
- SQLCITask\task.json defines the SQL CI task.
- SQLCITask\SqlCiTask.ps1 is the PowerShell run by the task.

## Development

1. Install Node.
2. Install the latest DLM Automation Suite.
3. Install 7-Zip
4. Install Microsoft Upgrade Advisor
5. Run build.bat to build the VSIX package.
6. Upload to the Marketplace and use it.

# Contact

Speak to Jason Crease about this project.
