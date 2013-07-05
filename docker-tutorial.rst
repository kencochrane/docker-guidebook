:date: 2013-07-05 10:48:29
:tags: docker, tutorial
:category: blog
:slug: the-ultimate-docker-tutorial
:author: Ken Cochrane
:title: the-ultimate-docker-tutorial

Topics
- intro
- what is docker
- installation
    - requirements
        - kernel
        - LXC
        - aufs
    - server
    - developer setup
- docker daemon and config options
    - log file
    - config file
- commands
    - list all of them with explanation of all switches and examples on how to use each
- registry / index
    - index
        - create an account
            - web or command line
        - delete repo
        - change description
    - public
    - private
    - search
    
- remote api
    - libraries
    - web ui's
- build files
    - how to
    - examples
- using external mounts (not finished yet)

- creating images, pushing and pulling.
- docker run
    - limiting memory, cpu
    - detached vs attached
    - volume mounting


<logo>
<Table of contents>

Introduction
============
The goal of this tutorial is to introduce you to `Docker <http://docker.io>_`, show you what it can do, and how to get it up and running on your system, and how to use it to make your life better.

[TODO: Add link to github repo]
This guide is open source and available on github.com. If you would like to add to it or fix something, please fork it and submit a pull request.

What is docker?
===============
Docker is a tool created by the folks at `dotCloud <http://dotcloud.com>`_ to make using LinuX Containers (`LXC <http://lxc.sourceforge.net/>`_) easier to use. Linux Containers are basically light weight Virtual Machines (`VM <http://en.wikipedia.org/wiki/Virtual_machine>`_). A linux container runs Unix processes with strong guarantees of isolation across servers. Your software runs repeatably everywhere because its Container includes all of its dependencies.

If you still don't understand what Docker is, and what it can do for you, don't worry, keep reading and it will become clear soon enough.

How is Docker's containers different from a normal Virtual Machine?
-------------------------------------------------------------------
Docker, which uses LinuX Containers (LXC) run in the same kernel as it's host. This allows it to share a lot of the host's resources. It also uses `AuFS <http://aufs.sourceforge.net>`_ for the file system. It also manages the networking for you as well.

AuFS is a layered file system, so you can have a read only part, and a write part, and it merges those together. So you could have the common parts of the file system as read only, which are shared amongst all of your containers, and then give each container it's own mount for writing.

So let's say you have a container image that is 1GB in size. If you wanted to use a Full VM, you would need to have 1GB times x number of VMs you want. With LXC and AuFS you can share the bulk of the 1GB and if you have 1000 containers you still might only have a little over 1GB of space for the containers OS, assuming they are all running the same OS image.

A full virtualized system gets it's own set of resources allocated to it, and does minimal sharing. You get more isolation, but it is much heavier (requires more resources).

With LXC you get less isolation, but they are more lightweight and require less resources. So you could easily run 1000's on a host, and it doesn't even blink. Try doing that with Xen, and unless you have a really big host, I don't think it is possible.

A full virtualized system usually takes minutes to start, LXC containers take seconds, and most times less then a second.

There are pros and cons for each type of virtualized system. If you want full isolation with guaranteed resources then a full VM is the way to go. If you just want to isolate processes from each other and want to run a ton of them on a reasonably sized host, then LXC might be the way to go.

For more information check out these set of blog posts which do a good job of explaining now LXC works: http://blog.dotcloud.com/under-the-hood-linux-kernels-on-dotcloud-part


Installing Docker
=================
Before you can install Docker you need to decide how you want to install it. There are three ways to install it, you can install from source, download a compiled binary, or install via your systems package manager. 

For detailed instructions on how to install Docker on your system for each of the following steps, check out the official Docker documentation http://docs.docker.io/en/latest/installation/

Requirements
------------
In order for Docker to run correctly on your server, you need to have a few things. For more details on the kernel requirements see this page: see http://docs.docker.io/en/latest/installation/kernel/

- Kernel version greater then 3.8 and Cgroups and namespaces must be enabled.
- AUFS : AUFS is included in the kernels built by the Debian and Ubuntu distributions, but not built into the standard kernel, so if you are using another distribution you will need to add it to your kernel.
- LXC : This is most likely already installed on your system and kernel, you might just need to install a system package or two. See the install instructions for your distribution to get a list of packages.

Kernel version
~~~~~~~~~~~~~~
The reason why Docker needs to run in a kernel version of 3.8 or greater is because there are some kernel bugs that are in the older versions that cause problems in some cases. Some people have ran Docker fine on lower kernels, so if you can't run on 3.8, do so at your own risk. There is talk about an effort to back port the bug fixes to the older kernel trees, so that in the future they will be available on the older kernel versions. For more information about this see. https://github.com/dotcloud/docker/pull/1062

AUFS
~~~~
Currently AUFS is the standard file system for Docker, but there is an effort underway to make the filesystem more pluggable, so that we can use different file systems with Docker. AUFS will most likely not be available in future Ubuntu releases, and UnionFS doesn't look like it will be getting added to the kernel anytime soon, so we can't add that as a replacement. The current replacement looks like `BTRFS <https://github.com/dotcloud/docker/issues/443> `_.

Package Manager
---------------
The most common way to install Docker is via your server's package manager. On Ubuntu that is as simple as running the following command ``sudo apt-get install lxc-docker``. This is an easy way to install docker, and keep it up to date. 

The package will also install an init script so that the docker daemon will start up automatically.

If you are installing on a production server, this is the recommended way to install. 

Upgrading:
~~~~~~~~~~
To upgrade you would upgrade the same way you upgrade any other package for your system. On Ubuntu you would run 'sudo apt-get upgrade'

Binaries
--------
If a docker package isn't available for your package manager, you can download the binaries directly. When a new version of docker is released the binaries are uploaded to http://get.docker.io, so that you can download directly from there. Here is an example on how to download the latest docker release.

::

    wget http://get.docker.io/builds/Linux/x86_64/docker-latest.tgz
    tar -xf docker-latest.tgz

This just downloads the docker binary, to get it to run you would still need to put the binary in a good location, and create an init script so that it will start on system reboots.

Init script examples:
~~~~~~~~~~~~~~~~~~~~~

- Debian init: https://github.com/dotcloud/docker/blob/master/packaging/debian/lxc-docker.init
- Ubuntu Upstart: https://github.com/dotcloud/docker/blob/master/packaging/ubuntu/docker.upstart

Upgrading:
~~~~~~~~~~
To upgrade you would need to download the latest version, make a backup of the current docker binary, replace the current one with the new one, and restart your daemon. The init script should be able to stay the same.

More information:
~~~~~~~~~~~~~~~~~
http://docs.docker.io/en/latest/installation/binaries/

From Source
-----------
Installing from a package manager or from a binary is fine if you want to only install released versions. But if you want to be on the cutting edge and install some features that are either on a feature branch, or something that isn't released yet, you will need to compile from source.

Compiling from source is a little more complicated because you will need to have GO 1.1 and all other dependences install on your system, but it isn't too bad. 

Here is what you need to do to get it up and running on Ubuntu::

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:gophers/go
    sudo apt-get update
    sudo apt-get -y install lxc xz-utils curl golang-stable git aufs-tools

    export GOPATH=~/go/
    export PATH=$GOPATH/bin:$PATH

    mkdir -p $GOPATH/src/github.com/dotcloud
    cd $GOPATH/src/github.com/dotcloud
    git clone git://github.com/dotcloud/docker.git
    cd docker

    go get -v github.com/dotcloud/docker/...
    go install -v github.com/dotcloud/docker/...

Then run the docker daemon,

    sudo $GOPATH/bin/docker -d
    
If you make any changes to the code, run the ``go install`` command (above) to recompile docker. Feel free to change the git clone command above to your own fork, to make pull request's easier.

Docker requires Go 1.1, if you have an older version it will not compile correctly.

Docker Daemon
=============
The Docker daemon needs to be running on your system to control the containers. The daemon needs to be run as Root so that it can have access to everything it needs.

Starting the daemon
-------------------
There are two ways to start the daemon, you can start it using an init script so that it starts on system boot, and manually starting the daemon and sending to the background. The init script is the preferred way of doing this. If you install Docker via a package manager you already have the init script on your system.

To start it manually you need to use a command like this.

    sudo <path to>/docker -d &

When Docker starts, it will listen on 127.0.0.1:4243 to allow only local connections but you can set it to 0.0.0.0:4243 or a specific host ip to give access to everybody. 

To change the host and port that docker listens to you will need to use the ``-H`` flag when starting docker.

``-H`` accepts host and port assignment in the following format: tcp://[host][:port] or unix://path For example:

- tcp://host -> tcp connection on host:4243
- tcp://host:port -> tcp connection on host:port
- tcp://:port -> tcp connection on 127.0.0.1:port
- unix://path/to/socket -> unix socket located at path/to/socket

When you do this, you need to also let the docker client know what daemon you want to connect too. To do that you have to also pass in the -H flag to with the ip:port of the daemon to connect too.

    # Run docker in daemon mode on port 5555
    sudo <path to>/docker -H 0.0.0.0:5555 &
    
    # Download a base image using the daemon on port 5555
    docker -H :5555 pull base

You can use multiple -H, for example, if you want to listen on both tcp and a unix socket

    # Run docker in daemon mode on 127.0.0.1:4243 and unix socket unix:///var/run/docker.sock
    sudo <path to>/docker -H tcp://127.0.0.1:4243 -H unix:///var/run/docker.sock
    
    # Download a base image (no need to put the -H since it is listen on default port :4243)
    docker pull base
    
    # OR (pull via the unix socket)
    docker -H unix:///var/run/docker.sock pull base


Configuration
-------------
Currently if you want to configure the docker daemon, you can either pass in command switches to the docker daemon on startup, or you can set ENV variables that the docker daemon will pick up. I have proposed a better approach for configuring docker, the idea is to use a ``docker.conf`` file so that it is easier to set and is more obvious. Details can be found here: https://github.com/dotcloud/docker/issues/937

There are two ENV variables that you can set today, there maybe more added in the future.

DEBUG
~~~~~
This tells the Docker daemon that you want more debug information in your logs. 

defaults to DEBUG=0, set to DEBUG=1 to enable.

DOCKER_INDEX_URL
~~~~~~~~~~~~~~~~
This tells Docker which Docker index to use. You will most likely not use this setting, it is mostly used for Docker developer when they want to try things out with the test index before they release the code. 

defaults to DOCKER_INDEX_URL=https://index.docker.io

Logs
----
There is no official Docker log file right now, I have opened an issue and requested one: https://github.com/dotcloud/docker/issues/936 but in the meantime if you are using upstart you can use ``/var/log/upstart/docker.log`` which has some information, but not as much as I would like.















