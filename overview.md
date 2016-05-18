# Redgate DLM Automation Build

[Redgate Software](http://www.red-gate.com/) develop database lifecycle management tools ([DLM](http://www.red-gate.com/dlm)) that help your organization include databases alongside applications in agile processes.

Redgate [DLM Automation](http://www.red-gate.com/products/dlm/dlm-automation/) is a tool that lets you apply continuous integration and release management processes to Microsoft SQL Server databases. 

Using this extension you can build, test, synchronize and publish SQL Server databases, as part of your application build and release process. 


## How to use this Extension

You need to commit your database schema to source control. The easiest way to do this is with Redgate’s [SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/), available to download from the Redgate website on a 28 day free trial.

Within the extension, there are four actions available:
* Build – builds your database into a NuGet package from the database scripts folder in source control
* Test – runs your tSQLt tests against the database
* Sync – synchronizes the package to an integration database
* Publish – publishes the package to a NuGet stream

![test-screenshot](images/screenshot-testTask.png)

## Tools and Pricing

You need Redgate’s [SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/), which you can download on a 28 day free trial.