limesurvey-docker - 12factor ❯ export TOOLS=599f0a-tools
export PROJECT=599f0a-dev
export SURVEY=testy

limesurvey-docker - 12factor ❯ oc -n ${PROJECT} new-app --file=./ci/openshift/mysql.dc.yaml -p SURVEY_NAME=${SURVEY}
imesurvey-docker - 12factor ❯ oc -n ${PROJECT} new-app --file=./ci/openshift/limesurvey-docker.dc.yaml -p SURVEY_NAME=${SURVEY} -p IS_NAMESPACE=${TOOLS} -p LIMESURVEY_ADMIN_EMAIL=Gary.T.Wong@gov.bc.ca -p LIMESURVEY_ADMIN_NAME="TESTY LimeSurvey Administrator"

---

build

oc -n 599f0a-tools process -f ci/openshift/limesurvey-docker.bc.yaml | oc -n 599f0a-tools apply -f -
oc -n 599f0a-tools  start-build limesurvey-docker
oc -n 599f0a-tools  logs -f build/limesurvey-docker-

oc -n 599f0a-tools delete istag limesurvey-docker:5.2.13
oc -n 599f0a-tools tag limesurvey-docker:latest limesurvey-docker:5.2.13

export TOOLS=599f0a-tools
export PROJECT=599f0a-dev
export SURVEY=testa

oc -n ${PROJECT} new-app --file=./ci/openshift/mysql.dc.yaml -p SURVEY_NAME=${SURVEY}
oc -n ${PROJECT} new-app --file=./ci/openshift/limesurvey-docker.dc.yaml -p SURVEY_NAME=${SURVEY} -p IS_NAMESPACE=${TOOLS} -p LIMESURVEY_ADMIN_EMAIL=Gary.T.Wong@gov.bc.ca -p LIMESURVEY_ADMIN_NAME="TESTY LimeSurvey Administrator"

MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE

oc -n ${PROJECT} scale --replicas=0 dc/${SURVEY}limesurvey-app
oc -n ${PROJECT} delete secret/${SURVEY}limesurvey-app dc/${SURVEY}limesurvey-app svc/${SURVEY}limesurvey-app route/${SURVEY}limesurvey-app hpa/${SURVEY}limesurvey-app pvc/${SURVEY}limesurvey-app-config pvc/${SURVEY}limesurvey-app-upload pvc/${SURVEY}limesurvey-app-plugins

oc -n ${PROJECT} scale --replicas=0 dc/${SURVEY}limesurvey-app dc/${SURVEY}limesurvey-mysql
oc -n ${PROJECT} delete all,secret,pvc,hpa -l app=${SURVEY}limesurvey

===
oc -n ${PROJECT} debug dc/testylimesurvey-app

===
kcfinder doesn't work on Chrome! but on FF yes

<https://testylimesurvey.apps.silver.devops.gov.bc.ca/admin/authentication/sa/login>



ABOVE to merge into bottom
- put some stuff in the root file README.md for local dev




### Table of Contents

<!-- TOC depthTo:2 -->

- [OpenShift](#openshift)
  - [Prerequisites](#prerequisites)
  - [Files](#files)
  - [Build](#build)
    - [Custom Image](#custom-image)
  - [Deploy](#deploy)
    - [Database Deployment](#database-deployment)
    - [Application Deployment](#application-deployment)
      - [LimeSurvey installation](#limesurvey-installation)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app)
  - [Example Deployment](#example-deployment)
    - [Set the environment variables](#set-the-environment-variables)
    - [Database Deployment](#database-deployment-1)
    - [App Deployment](#app-deployment)
  - [Versioning](#versioning)
  - [Unreleased](#unreleased)
    - [Added](#added)
    - [Changed](#changed)
    - [Removed](#removed)

<!-- /TOC -->

# OpenShift

OpenShift 4 templates for [LimeSurvey](https://github.com/LimeSurvey/LimeSurvey), used within Natural Resources Ministries and ready for deployment on BC Government [OpenShift](https://www.openshift.com/). 

## Prerequisites

For appropriate security on deployed pods:

- Kubernetes Network Policies should be in place, see the [Network Policy QuickStart](https://github.com/bcgov/how-to-workshops/tree/master/labs/netpol-quickstart).

For build:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project `*-tools` namespace
- the [oc](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html) CLI tool, installed on your local workstation
- access to this public [GitHub Repo](./)

Once built, this image may be deployed to a separate `*-dev`, `*-test`, or `*-prod` namespace with the appropriate `system:image-puller` role.

For deployment:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project namespace
- the [oc](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html) CLI tool, installed on your local workstation
- access to this public [GitHub Repo](./)

Once deployed, any visitors to the site will require a modern browser (e.g. Edge, FF, Chrome, Opera etc.) with activated JavaScript (see official LimeSurvey [docs](https://manual.limesurvey.org/Installation_-_LimeSurvey_CE#Make_sure_you_can_use_LimeSurvey_on_your_website))

## Files

- [OpenShift LimeSurvey app template](./limesurvey.dc.yaml) for LimeSurvey PHP application, with MySQL Database
- [OpenShift Database service template](./mysql.dc.yaml) for a MySQL Database

## Build

### Custom Image

For a brand new build/image/imagestream/imagestreamtag in your new namespace, you would first create an image stream using this (forked) code (replace `<tools-namespace>` with your `*-tools` project namespace).

```bash
oc -n <tools-namespace> create istag limesurvey:latest
oc -n ${TOOLS} process -f ci/openshift/limesurvey.bc.yaml | oc -n ${TOOLS} apply -f -
oc -n ${TOOLS} start-build limesurvey
oc -n ${TOOLS} logs -f build/limesurvey-<n>

```

Tag the built image stream with the correct release version, matching the `major.minor` release tag at the source [repo](https://github.com/LimeSurvey/LimeSurvey). For example, this v5.2.13 was tagged via:

```bash
oc -n <tools-namespace> tag limesurvey:latest limesurvey:5.2.13
```

NOTE: To update our LimeSurvey image, we would update or override the Dockerfile ARG, and run the [Build](./limesurvey.bc.yaml). For example, this v5.2.13 was built with:

```
ARG GITHUB_TAG=5.2.13+210824
```

## Deploy

### Database Deployment

Deploy the DB using the correct SURVEY_NAME parameter (e.g. an acronym that will be automatically prefixed to `limesurvey`):

```bash
oc -n <project> new-app --file=./ci/openshift/mysql.dc.yaml -p SURVEY_NAME=<survey>
```

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/mysql.html), and DB deployed objects (e.g. deployment configs, secrets, services, etc) have a naming convention of `<survey>limesurvey-mysql` in the Openshift console.

### Application Deployment

Deploy the Application specifying:

- the survey-specific parameter (i.e. `<survey>`)
- your project `*-tools` namespace that contains the image, and
- a `@gov.bc.ca` email account that will be used with the `apps.smtp.gov.bc.ca` SMTP Email Server:

```bash
oc -n <project> new-app --file=./ci/openshift/limesurvey.dc.yaml -p SURVEY_NAME=<survey> -p IS_NAMESPACE=<tools> -p LIMESURVEY_ADMIN_EMAIL=<Email.Address>@gov.bc.ca
```

NOTE: The LIMESURVEY_ADMIN_EMAIL is required, and you may also override the default LIMESURVEY_ADMIN_USER and LIMESURVEY_ADMIN_NAME. The ADMIN_PASSWORD is automatically generated by the template; be sure to __note the generated password__ (shown in the log output of this command on your screen).

Application deployed objects (e.g. deployment configs, secrets, services, etc) have a naming convention of `<survey>limesurvey-app` in the Openshift console.

#### LimeSurvey installation

The database tables are automatically installed as part of the `docker-entrypoint.sh`, which checks for the existence of these tables first and if not present, will do a one-time initial install.  Subsequest pod restarts or deploys (as part of scaling up) see the populated database tables and skip the initial install.

### Log into the LimeSurvey app

Once the application has finished the initial install you may log in as the admin user (using the generated password). Use the correct Survey acronym in the URL:
`https://<survey>limesurvey.apps.silver.devops.gov.bc.ca/admin`

NOTE: The password is also stored as a secret in the OCP Console (`<survey>limesurvey-app.admin-password`), or can be echoed in the shell of deployed app terminal:

```bash
echo ${ADMIN_PASSWORD}
```

## Example Deployment 

As this is a template deployment, it may be easier to set environment variable for the deployment, so using the same PROJECT `599f0a-dev` and SURVEY `acme`:

<details><summary>Deployment Steps</summary>

### Set the environment variables

On a workstation logged into the OpenShift Console:

```bash
export TOOLS=599f0a-tools
export PROJECT=599f0a-dev
export SURVEY=acme
```

### Database Deployment

```bash
oc -n ${PROJECT} new-app --file=./ci/openshift/mysql.dc.yaml -p SURVEY_NAME=${SURVEY}
```


```bash
--> Deploying template "599f0a-dev/nrm-limesurvey-mysql-dc" for "./ci/openshift/mysql.dc.yaml" to project 599f0a-dev

     nrm-limesurvey-mysql-dc
     ---------
     To view the log (assumes oc CLI is installed):
     $  oc -n ${PROJECT} logs -f dc/${SURVEY}limesurvey-mysql

     * With parameters:
        * Survey Name=acme
        * Memory Limit=512Mi
        * mysql Connection Password=PAogdOT2qkHveIJe # generated
        * mysql root Password=LOnWPGaNUeng4joX # generated
        * Database Volume Capacity=1Gi

--> Creating resources ...
    secret "acmelimesurvey-mysql" created
    persistentvolumeclaim "acmelimesurvey-mysql" created
    deploymentconfig.apps.openshift.io "acmelimesurvey-mysql" created
    service "acmelimesurvey-mysql" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/acmelimesurvey-mysql' 
    Run 'oc status' to view your app.

```

### App Deployment



```bash
oc -n ${PROJECT} new-app --file=./ci/openshift/limesurvey.dc.yaml -p SURVEY_NAME=${SURVEY} -p IS_NAMESPACE=${TOOLS} -p LIMESURVEY_ADMIN_EMAIL=Joe.Smith@gov.bc.ca -p LIMESURVEY_ADMIN_NAME="ACME LimeSurvey Administrator"
```

--> Deploying template "599f0a-dev/nrmlimesurvey-app-dc" for "./ci/openshift/limesurvey.dc.yaml" to project 599f0a-dev

     * With parameters:
        * Namespace=599f0a-tools
        * Image Stream=limesurvey
        * Version of LimeSurvey=5.2.13
        * LimeSurvey Acronym=acme
        * Upload Folder size=1Gi
        * Administrator Account Name=admin
        * Administrator Display Name=MAS LimeSurvey Administrator
        * Administrator Password=dV0x1DuaBYjNhjCG # generated
        * Administrator Email Address=Joe.Smith@gov.bc.ca
        * Database Type=pgsql
        * CPU_LIMIT=200m
        * MEMORY_LIMIT=512Mi
        * CPU_REQUEST=50m
        * MEMORY_REQUEST=200Mi
        * REPLICA_MIN=2
        * REPLICA_MAX=3

--> Creating resources ...
    secret "acmelimesurvey-app" created
    persistentvolumeclaim "acmelimesurvey-app-upload" created
    persistentvolumeclaim "acmelimesurvey-app-config" created
    persistentvolumeclaim "acmelimesurvey-app-plugins" created
    deploymentconfig.apps.openshift.io "acmelimesurvey-app" created
    horizontalpodautoscaler.autoscaling "acmelimesurvey-app" created
    service "acmelimesurvey-app" created
    route.route.openshift.io "acmelimesurvey-app" created
--> Success
    Access your application via route 'acmelimesurvey.apps.silver.devops.gov.bc.ca'
    Run 'oc status' to view your app.
```

### Log into the LimeSurvey app

The Administrative interface is at <https://${SURVEY}.apps.silver.devops.gov.bc.ca/index.php/admin/> which is this example is <https://acmelimesurvey.apps.silver.devops.gov.bc.ca/> .

and brings to you a screen like:
![Admin Logon](./docs/images/AdminLogin.png)

Once logged as an Admin, you'll be brought to the Welcome page:
![Welcome Page](./docs/images/WelcomePage.png)

</details>

## FAQ

- to login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:

  `psql -U ${POSTGREQL_USER} ${POSTGRESQL_DATABASE}`

- to clean-up database deployments:

   `oc -n <project> delete secret/<survey>limesurvey-mysql dc/<survey>limesurvey-mysql svc/<survey>limesurvey-mysql`

  NOTE: The Database Volume will be left as-is in case there is critical business data, so to delete:

  `oc -n <project> delete pvc/<survey>limesurvey-mysql`

  or if using environment variables:

  ```bash
  oc -n ${PROJECT} delete secret/${SURVEY}limesurvey-mysql dc/${SURVEY}limesurvey-mysql svc/${SURVEY}limesurvey-mysql
  oc -n ${PROJECT} delete pvc/${SURVEY}limesurvey-mysql
  ```

- to clean-up application deployments:

  ```bash
  oc -n <project> delete secret/<survey>limesurvey-app dc/<survey>limesurvey-app svc/<survey>limesurvey-app route/<survey>limesurvey-app hpa/<survey>limesurvey-app`
  ```

  NOTE: The Configuration, Upload, and Plugins Volumes are left intact in case there are customized assets; if not (i.e. it's a brand-new survey):  

  ```bash
  oc -n <project> delete pvc/<survey>limesurvey-app-config pvc/<survey>limesurvey-app-upload pvc/<survey>limesurvey-app-plugins`
  ```

  or if using environment variables:

  ```bash
  oc -n ${PROJECT} delete secret/${SURVEY}limesurvey-app dc/${SURVEY}limesurvey-app svc/${SURVEY}limesurvey-app route/${SURVEY}limesurvey-app hpa/${SURVEY}limesurvey-app pvc/${SURVEY}limesurvey-app-config pvc/${SURVEY}limesurvey-app-upload pvc/${SURVEY}limesurvey-app-plugins
  ```

- to reset _all_ deployed objects (this will destroy all data and persistent volumes). Only do this on a botched initial install or if you have the DB backed up and ready to restore into the new wiped database.

  `oc -n <project> delete all,secret,pvc -l app=<survey>limesurvey`

  or if using environment variables:

  ```bash
  oc -n ${PROJECT} delete all,secret,pvc,hpa -l app=${SURVEY}limesurvey
  ```

- to dynamically get the pod name of the running pods, this is helpful:

  `oc -n <project> get pods | grep <survey>limesurvey-app- | grep -v deploy | grep Running | awk '{print \$1}'`

- to customize the deployment with higher/lower resources, using environment variables, use  these examples:

  ```bash
  oc -n ${PROJECT} new-app --file=./ci/openshift/postgresql.dc.yaml -p SURVEY_NAME=${SURVEY} -p MEMORY_LIMIT=768Mi -p DB_VOLUME_CAPACITY=1280M
  
  oc -n ${PROJECT} new-app --file=./ci/openshift/limesurvey.dc.yaml -p SURVEY_NAME=${SURVEY} -p LIMESURVEY_ADMIN_EMAIL=John.Doe@gov.bc.ca -p LIMESURVEY_ADMIN_NAME="IITD LimeSurvey Administrator" -p REPLICA_MIN=2
  ```

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Unreleased

- add support for MySQL/MariaDB

### Added

- tested out build using newer version of LimeSurvey (via GITHUB_TAG), from the `/archive/refs/tags/*` of <https://github.com/LimeSurvey/LimeSurvey>
- refactored to use Dockerfile rather than git submodule
- after-the-fact tagged and created release for [first version](https://github.com/garywong-bc/nrm-survey/releases/tag/v3.15)
- implemented health checks for the deployments
- tested DB backup/restore and transfer
- updated `gluster-file-db` to `netapp-block-standard`
- updated `gluster-file` to `netapp-file-standard`
- check for persistent upload between re-deploys
- appropriate resource limits (multi-replica deployment supported)

### Changed

-

### Removed

-
