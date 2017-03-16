# Sitecore Devops with AppVeyor

This is a sample solution which shows how to develop an open-source [Sitecore](http://www.sitecore.net/) module and hook it up with [AppVeyor](https://www.appveyor.com), a Continuous Delivery solution hosted in the cloud.

The scripts in this solution show:

* Installing Sitecore, Solr
* Building the solution
* Testing with Unit Tests, and Automated UI tests (Selenium)
* Generating visual reports such as Build status badges, Code Quality, Test coverage
* Packaging up files and items as .zip and .update files using Hedgehog's [Team Development for Sitecore](http://www.teamdevelopmentforsitecore.com/)
* Deploying items using [Sitecore Ship](https://github.com/kevinobee/Sitecore.Ship) and files using [Appveyor Agent](https://www.appveyor.com/docs/deployment/agent/)
* Post-deployment warm-up and health monitoring
* [Rollback](https://jammykam.wordpress.com/2017/01/24/anti-update-rollback-package/)

## Build status

The current state of the build is a badge hosted by [AppVeyor](https://www.appveyor.com)

[![Build status](https://ci.appveyor.com/api/projects/status/ihbo48osm0mxsmg8?svg=true)](https://ci.appveyor.com/project/steviemcg/sitecore-devops-appveyor)

## Installing Sitecore

This repository shows how to encrypt files and credentials so that sensitive data such as your Sitecore license, TDS credentials and Sitecore installation files aren't in the public domain.

The PowerShell functions for installing Sitecore are hosted in a private location. Our long-term goal is an open-source repository for installing and configuring Sitecore and its modules, for each version, each server role, and each environment.

## Code Quality

Code Quality is monitored by [SonarQube](https://www.sonarqube.com). "Technical Debt" grades for Reliability, Security and Maintainability are summarised on a [cloud-hosted dashboard](https://sonarqube.com/dashboard?id=SitecoreDevopsAppVeyor).

[![Quality Gate](https://sonarqube.com/api/badges/gate?key=SitecoreDevopsAppVeyor)](https://sonarqube.com/dashboard/index/SitecoreDevopsAppVeyor)

## Pull Requests

Pull Requests are automatically built by AppVeyor, and can only be merged to master on a Green build. There is also a Sonarqube Quality Gate which ensures that Code Quality and Test Coverage does not decrease. In larger projects Peer Review can also be enabled.

## Packaging

Packaging is done using Hedgehog's [Team Development for Sitecore](http://www.teamdevelopmentforsitecore.com/). An alternative would be to use [Unicorn](https://github.com/kamsar/Unicorn) and this will be added to this repository soon as an option.

## Contributing

Contributions from the community are **very** welcome. No processes are in place for this yet. Please contact Steve McGill on Twitter [(@steviemcgill)](https://twitter.com/steviemcgill) if you would like to help out. Thanks!