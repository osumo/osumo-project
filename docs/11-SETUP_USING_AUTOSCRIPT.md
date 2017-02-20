
SETUP USING AUTOSCRIPT
======================

This version of the setup guide will guide you in using the AUTOSCRIPT and
related tools in the `osumo-project` helper repository to automate most of the
tasks needed to set up a local osumo development environment.

You will still need to confirm that your system meets the necessary software
requirements detailed in the previous section.  You can also use the `check-env`
script to help you determine what might be missing from your system.  Refer to
the [previous section](10-SETUP_GUIDE.md) for more details.

### Clone the repos/set up push URLs

 1. This part is similar to the first steps in the manual process, except you
    will use the `osumo-project` helper repository and the git submodules
    therein.

    ```bash
    mkdir -p ~/projects/osumo
    cd ~/projects/osumo
    git clone git://github.com/osumo/osumo-project
    cd osumo-project
    git submodule update --init --recursive
    ```

 1. (Optional) if you intend to push directly to any of these repos, including
    the helper repo, itself, set the push urls to use either ssh or https.

    ```bash
    ( cd osumo ; git remote set-url --push origin ssh://git@github.com/osumo/osumo )
    ( cd girder ; git remote set-url --push origin ssh://git@github.com/girder/girder)
    ( cd girder_worker ; git remote set-url --push origin ssh://git@github.com/girder/girder_worker)
    etc
    ```

    or

    ```bash
    ( cd osumo ; git remote set-url --push origin https://github.com/osumo/osumo )
    ( cd girder ; git remote set-url --push origin https://github.com/girder/girder)
    ( cd girder_worker ; git remote set-url --push origin https://github.com/girder/girder_worker)
    etc
    ```

 1. (Optional) Checkout the versions of each repo.  Whether you need to do this
     and for which repos will vary as development proceeds.  If unsure, ask the
     other developers.

    ```bash
    ( cd girder ; git checkout some-branch-or-tag )
    ( cd osumo ; git checkout testing-branch )
    ```

### Run the AUTOSCRIPT

 1. Once you have the repos cloned and checked out to your desired versions, you
    should be able to use the AUTOSCRIPT to handle the rest of the setup process
    for you.

    ```bash
    # ensure that you are at the top of the project root
    pwd
     > /home/user/projects/osumo/osumo-project
    node scripts/dev/auto.js
    ```

    At this point, you might want to go grab a cup of coffee or something. :)
    If everything goes well, you should see a simple text interface replace your
    screen with a list of running tasks as well as an activity monitor
    indicating how much output activity the task is engaged in.

    The mongodb server should be the first task, then, you should see an
    "install" task run for quite a while.  This task is automating a large
    portion of the setup process; it sets up your python virtual environment,
    installs all necessary packages, configures girder and girder_worker,
    automatically creates a girder admin user account, registers all the
    necessary plugins, builds all the neccessary web code in multiple passes,
    and even ensures that the app routing tables are set properly.  If all these
    steps complete successfully, you should see the interface add on four new
    tasks: "server", which represents the girder web application server,
    "worker", which represents the computational worker server, "watch-osumo",
    which represents the watcher for the osumo code, and "watch-core", which
    represents the watcher for girder, proper. Together with the mongodb
    service, you should have five total running services by the end of the setup
    process.

    At this point, you should be able to browse to localhost:8080 and see the
    osumo application run without issue.  You should be able to make changes to
    the osumo code, and see those changes in your browser after refreshing.

    Once you are done developing for the day, or want to shut down the running
    services, simply press "q" while in the text interface and wait for a brief
    moment.  The services should all be shut down and closed and control of your
    terminal returned to your shell.

    For diagnostic purposes, you will likely wish to observe the logging output
    from these various tasks as they run.  For this purpose, each task is logged
    to a space created in the root directory under `cache/logs`.  For example,
    to view the log output from the install step as it runs, start a new shell,
    navigate to your project space root, and use `tail` on the desired file.
    You should now see all the new logging output from the install step as it
    happens.

    ```bash
    cd ~/projects/osumo/osumo-project
    tail -F cache/logs/install.log
    ```

