
SETUP GUIDE
===========

The OSUMO platform is made up of several software components that are closely
coordinated to enable rapid development of web-based computational workflows.
To get started developing on the OSUMO platform, your workstation will need to
meet the following requirements:

 - Linux or Unix-based OS
 - any modern version of git as well a comprehensive understanding of how to use
   git
 - Python version 2.7 or greater or Python version 3.5 or greater
   - with virtualenv package
 - Node.js major version 6
   - OSUMO is likely to work on other versions of Node, but has not yet been
     tested against them.
 - MongoDB server
 - R installed with all the R packages that will be needed by your analysis
   tasks
 - and any additional requirements imposed by your choice of analysis tasks,
   such as docker, Spark, or additional Python libraries

> NOTE: You can use the "check-env" script in the osumo-project repository to
> check your environment for any missing components.  The script will check to
> make sure you have adequate versions of each software component installed as
> well as any necessary packages.
>
> ```bash
> git clone git://github.com/osumo/osumo-project
> bash osumo-project/dev/check-env.bash
> ```

The rest of this document outlines a proceedure for manually setting up a local
OSUMO development environment.  OSUMO developers may also use the AUTOSCRIPT to
automate the majority of this proceedure.  Information on using the AUTOSCRIPT
can be found [here](11-SETUP_USING_AUTOSCRIPT.md).

### Clone the repos/set up push URLs

 1. Start with an empty directory that will house your project space.

    ```bash
    mkdir -p ~/projects/osumo
    cd ~/projects/osumo
    ```

 1. Clone the repositories for girder, girder-worker, and the osumo girder
    plugin.

    ```bash
    git clone git://github.com/girder/girder
    git clone git://github.com/girder/girder_worker
    git clone git://github.com/osumo/osumo
    ```

 1. (Optional) if you intend to push directly to any of these repos, you should
     set the push url to use either ssh or https.

    ```bash
    ( cd osumo ; git remote set-url --push origin ssh://git@github.com/osumo/osumo )
    ( cd osumo ; git remote set-url --push origin https://github.com/osumo/osumo )
    ```

 1. (Optional) Checkout the versions of each repo.  Whether you need to do this
     and for which repos will vary as development proceeds.  If unsure, ask the
     other developers.

    ```bash
    ( cd girder ; git checkout some-branch-or-tag )
    ( cd osumo ; git checkout testing-branch )
    ```

### Start your MongoDB server

 1. If your mongodb server is not already running, you can run a local instance
     for development.

    ```bash
    mkdir -p ./db-storage
    mongod --dbpath ./db-storage
    ```

    Then, switch to another shell to continue.


### Set up your python virtual environment

 1. Set up virtual env

    ```bash
    virtualenv ./sumo-python-env
    ```

    Note: make sure that the virtual environment is activated whenever you work
    on OSUMO development.  Anytime you open a new shell or terminal, you will
    need to reactivate the environment.

    ```bash
    source ./sumo-python-env/bin/activate
    ```

 1. Install girder and girder-worker in developer mode

    ```bash
    ( cd girder ; pip install -e '.[plugins]' )
    ( cd girder_worker ; pip install -e . )
    ```

### Customize Girder/Girder_worker options

 1. Edit girder config

    ```bash
    $MY_EDITOR girder/girder/conf/girder.local.cfg
    ```

    This file is a config file with sections, each having their own options.
    You can copy `girder/girder/conf/girder.dist.cfg` and only keep the
    sections/options you want to change.  The `local` file overrides the
    defaults in the `dist` file.

    Make sure that Girder is configured to use the correct mongo database at the
    correct port.  This tutorial assumes you are using the default mongodb port,
    27017, the default port for girder, 8080, and "sumo" as the database name
    (`uri: "mongodb://localhost/sumo"`).

 1. Edit girder_worker config

    ```bash
    $MY_EDITOR girder_worker/girder_worker/worker.local.cfg
    ```

    This file is similar to the girder config file.  You can copy
    `girder_worker/girder_worker/worker.dist.cfg` and only keep the
    sections/options you want to change.  The `local` file overrides the
    defaults in the `dist` file.

    Make sure that Girder worker is configured to use the correct mongo database
    at the correct port.  This tutorial assumes you are using the default
    mongodb port, 27017, using "sumoBroker" as the database name for the broker
    (`broker=mongodb://localhost:27017/sumoBroker`), and enabled the "r" and
    "girder_io" plugins for girder_worker (`plugins_enabled=r,girder_io`).

### Build, Enable Plugins, Rebuild

 1. Build the web code for Girder.  In this first pass, you will not use osumo
    or any related plugins, because you need to use the girder app to enable
    them.

    ```bash
    girder-install plugin osumo
    girder-install web
    girder-server
    ```

 1. If the above commands are successful, you should now have a girder web
    server listening on port 8080.  Point your browser to localhost:8080, and
    click on the dropdown menu on the top-right corner to create a new account.

    This first account will have admin permissions, and for development, the
    details of the account are not important.  This tutorial assumes you use
    "girder" for all fields and "girder@girder.girder" for the email.

    After creating your account, you will be logged in, and can click on the
    "admin console" menu entry on the left-hand bar.

    Click on "Plugins" and enable the "osumo" plugin.  Other dependent plugins
    should be enabled automatically. Save the changes, and go back to the admin
    console.  While here, click on the "assetstore" configuration entry, and
    create a new GridFS assetstore.  Assetstore name can be anything (like
    "local"), database name should be "sumoData", mongo host uri must match your
    mongodb server (mongodb://localhost:27017).  Ignore replica set unless your
    mongodb service uses replication, which it shouldn't if you're using this
    guide for development! ;) Click the "create" button when you're ready!

 1. With all these changes in place, go back to your shell that is running the
    girder-server instance and close it by typing ctrl-c.  Now, rebuild the web
    code.  This time, it should bundle the osumo code as well.

    ```bash
    girder-install web
    ```

### Run services and start developing

 1. If everything has worked up to this point, you are ready to run the services
    that will assist you in developing on osumo.  Note that each of these
    services run indefinitely and so will either need to run in the background,
    or run in their own shells.

    1. MongoDB, if you're going through this guide for the first time, you
       should already have your database running.  If you're returning to your
       project after shutting down, start from here and resume your database
       service.

       ```bash
       mongod --dbpath ./db-storage
       ```

    1. girder-server: run the main web app server. `girder-server`

    1. girder_worker: run the backend computation server. `girder-worker`

    1. osumo code watcher: run this watcher so that your osumo code is
       automatically rebuilt and loaded every time you make a change.

       ```bash
       girder-install web --watch-plugin osumo --plugin-prefix index
       ```

    1. girder core watcher: if you're going to make modifications on the code
       for girder, itself, run this watcher.

       ```bash
       girder-install web --watch
       ```

### Known Issues

 1. Currently girder must be set to serve the osumo application from the root
    mountpoint ("/").  To enable this, you will need to browse to
    localhost:8080, log in as an admin, click on "admin console", then "server
    configuration", and modify the mount point table near the bottom.  You need
    to change girder's mount point from "/" to "/girder" and osumo's mount point
    from "/osumo" to "/".

    After adding these settings, restart the girder-server and browse to
    "localhost:8080".  The osumo application should be served normally.

