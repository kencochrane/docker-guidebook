:date: 2013-07-05 10:48:29
:tags: docker, tutorial
:category: blog
:slug: the-docker-guidebook
:author: Ken Cochrane
:title: The Docker Guidebook

====================
The Docker Guidebook
====================

TODO:

- build files
    - how to
    - examples
- setting up your own private registry
- docker run
    - limiting memory, cpu
    - detached vs attached
    - volume/bind mounting
    - using external mounts (not finished yet)

.. image:: docker_logo.png

.. sectnum::

.. sidebar:: Table of Contents

   .. contents:: Table of Contents
      :depth: 3

Introduction
============
The goal of this tutorial is to introduce you to `Docker <http://docker.io>`_, show you what it can do, and how to get it up and running on your system, and how to use it to make your life better.

This guide is open source and available on `github.com <https://github.com/kencochrane/docker-tutorial>`_. If you would like to add to it or fix something, please `fork it <https://github.com/kencochrane/docker-tutorial>`_ and submit a pull request.

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
Currently AUFS is the standard file system for Docker, but there is an effort underway to make the filesystem more pluggable, so that we can use different file systems with Docker. AUFS will most likely not be available in future Ubuntu releases, and UnionFS doesn't look like it will be getting added to the kernel anytime soon, so we can't add that as a replacement. The current replacement looks like `BTRFS <https://github.com/dotcloud/docker/issues/443>`_.

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

Then run the docker daemon::

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

::

    sudo <path to>/docker -d &

When Docker starts, it will listen on 127.0.0.1:4243 to allow only local connections but you can set it to 0.0.0.0:4243 or a specific host ip to give access to everybody. 

To change the host and port that docker listens to you will need to use the ``-H`` flag when starting docker.

``-H`` accepts host and port assignment in the following format: tcp://[host][:port] or unix://path For example:

- tcp://host -> tcp connection on host:4243
- tcp://host:port -> tcp connection on host:port
- tcp://:port -> tcp connection on 127.0.0.1:port
- unix://path/to/socket -> unix socket located at path/to/socket

When you do this, you need to also let the docker client know what daemon you want to connect too. To do that you have to also pass in the -H flag to with the ip:port of the daemon to connect too.

::

    # Run docker in daemon mode on port 5555
    sudo <path to>/docker -H 0.0.0.0:5555 &
    
    # Download a base image using the daemon on port 5555
    docker -H :5555 pull base

You can use multiple -H, for example, if you want to listen on both tcp and a unix socket

::

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

Example
~~~~~~~
This is how you would set it if it was in an init file::

    # /etc/init/docker.conf
    env LC_ALL="en_US.UTF-8"
    env DOCKER_INDEX_URL="https://index.docker.io"
    env DEBUG=1
    exec /usr/local/bin/docker -d

Logs
----
There is no official Docker log file right now, I have opened an issue and requested one: https://github.com/dotcloud/docker/issues/936 but in the meantime if you are using upstart you can use ``/var/log/upstart/docker.log`` which has some information, but not as much as I would like.

Testing Docker install
======================
Now that you have Docker running, you can start to issue some Docker commands to see how things are working. The very first commands that I always run are ``Docker version`` and ``Docker info``. These tell me quickly if I have everything working correctly. 
::

    $ docker version
    Client version: 0.4.8
    Server version: 0.4.8
    Go version: go1.1

    $ docker info
    Containers: 0
    Images: 0
    WARNING: No memory limit support
    WARNING: No swap limit support

Notice that I have two warnings for my docker info. If you use Debian or Ubuntu kernels, and want to enable memory and swap accounting, you must add the following command-line parameters to your kernel::

    cgroup_enable=memory swapaccount=1

On Debian or Ubuntu systems, if you use the default GRUB bootloader, you can add those parameters by editing ``/etc/default/grub`` and extending GRUB_CMDLINE_LINUX. Look for the following line::

    GRUB_CMDLINE_LINUX=""

And replace it by the following one::

    GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"

Then run ``update-grub``, and reboot the server.

Terminology
===========
There are going to be some terms that you hear throughout this tutorial, to make sure you understand what we are talking about, I'll explain a few of them here.

Image
-----
An image is a read only layer used to build a container. They do not change.

Container
---------
Is basically a self contained runtime environment that is built using one or more images. You can commit your changes to a container and create an image.

index / registry
----------------
These are public or private servers where people can upload their repositories so they can easily share what they made.

Repository
----------
A repository is a group of images located in the docker registry. There are two types of repositories, Top level and user repositories. Top level repositories don't have a '/' in the name and they are usually reserved for base images. These Top level repositories is what most people build their repositories on top of. They are controlled by the maintainers of Docker. User repositories are repositories that anyone can upload into the registry and share with other people.

Getting Help with Docker
========================
If you have a question or problem when using Docker, there are a number of different ways to help you. Here is a list of the ways, pick the one that works best for you.

- IRC: #docker on freenode, There are a bunch (250+) people normally in this channel, come on in, and ask your question, we are very friendly and we don't bite. Also newbie questions are welcome.
- Email: There is a google group called docker-club. Join the list, and ask any questions you might have. https://groups.google.com/d/forum/docker-club
- Twitter: http://twitter.com/getdocker/ Follow along, if you aren't already, lots of great info posted every day.
- StackOverflow: We love Stack Overflow, if you also enjoy it, feel free to post a question using the `docker` tag, and one of the many Docker fans  will get back to you quickly. If you love getting points, feel free to answer questions as well.
- Bugs and feature requests: If you have a bug or feature request, submit them to GitHub. http://www.github.com/dotcloud/docker

Part 1. Getting Started
=======================
Now that we have the boring stuff out of the way lets start playing with Docker. The very first example we are going to do is a very simple one, we will spin up a container and print ``hello world`` to the screen.
::

    #run a simple echo command, that will echo hello world back to the console over standard out.
    $ docker run base /bin/echo hello world
    hello world

If this was your first docker command you will notice that it will need to download the base image first. It only needs to do this once, and it caches it locally so you don't need to do this again. We could have broken these out into two commands ``docker pull base`` and then the docker run command, but I was lazy and put them together, and Docker is smart enough to know what I want to do, and do it for me.

Now you might be wondering what is Docker doing here exactly. It doesn't look like much because we picked such a simple example, but here is what is happening.

1. Generated a new LXC container
2. Created a new file system
3. Mounted a read/write layer
4. Allocated network interface
5. Setup IP
6. Setup NATing
7. Executed the process in the container
8. Captured it's output
9. Printed to screen
10. Stopped the container

All in under a second!

If we run the ``docker images`` command we should see the base image in our list.
::

    $ docker images
    REPOSITORY          TAG                 ID                  CREATED             SIZE
    base                latest              b750fe79269d        3 months ago        24.65 kB (virtual 180.1 MB)
    base                ubuntu-12.10        b750fe79269d        3 months ago        24.65 kB (virtual 180.1 MB)
    base                ubuntu-quantal      b750fe79269d        3 months ago        24.65 kB (virtual 180.1 MB)
    base                ubuntu-quantl       b750fe79269d        3 months ago        24.65 kB (virtual 180.1 MB)

Notice how you see the same image more then once, that is because there are more then one tag for the same image.

If we want to see the container we just ran we can run the ``docker ps`` command. Since it isn't running anymore we need to use the ``-a`` flag to show us all of the image::

    $ docker ps -a
    ID                  IMAGE               COMMAND                CREATED             STATUS              PORTS
    861361e27501        base:latest         /bin/echo hello world  1 minutes ago       Exit 0

Lets do something a little more complicated. We are going to do the same thing, but instead of having the container exit right after we start, we want it to keep running in the background, and print hello world every second::

    $ CONTAINER_ID=$(docker run -d base /bin/sh -c "while true; do echo hello world; sleep 1; done")
    $ echo $CONTAINER_ID
    f684fc88aec3
    
    $ docker ps
    ID                  IMAGE               COMMAND                CREATED             STATUS              PORTS
    f684fc88aec3        base:latest         /bin/sh -c while tru   33 seconds ago      Up 33 seconds

There we go, now lets see what the container is doing by looking at the logs for the container::

    $ docker logs f684fc88aec3
    hello world
    hello world
    hello world
    hello world
    hello world
    .. (trimmed)

Now lets attach to the container and see the results in realtime::

    $ docker attach f684fc88aec3
    hello world
    hello world
    hello world

Ok, enough fun for this container, lets stop it.

    $ docker stop f684fc88aec3
    f684fc88aec3
    
    $ docker ps
    ID                  IMAGE               COMMAND             CREATED             STATUS              PORTS

Another thing we could have done to look at the container was inspect the container, we can do this while it is running or after it stopped::

    $ docker inspect f684fc88aec3
    [{
        "ID": "f684fc88aec3bf5b74df2fe03da1fe7cebf07a89d308b6ac7e8a6f14d9c9a3dd",
        "Created": "2013-07-05T21:23:31.27766521Z",
        "Path": "/bin/sh",
        "Args": [
            "-c",
            "while true; do echo hello world; sleep 1; done"
        ],
        "Config": {
            "Hostname": "f684fc88aec3",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": [
                "/bin/sh",
                "-c",
                "while true; do echo hello world; sleep 1; done"
            ],
            "Dns": null,
            "Image": "base",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": []
        },
        "State": {
            "Running": false,
            "Pid": 0,
            "ExitCode": 137,
            "StartedAt": "2013-07-05T21:23:31.298200635Z",
            "Ghost": false
        },
        "Image": "b750fe79269d2ec9a3c593ef05b4332b1d1a02a62b4accb2c21d589ff2f5f2dc",
        "NetworkSettings": {
            "IPAddress": "",
            "IPPrefixLen": 0,
            "Gateway": "",
            "Bridge": "",
            "PortMapping": null
        },
        "SysInitPath": "/usr/bin/docker",
        "ResolvConfPath": "/etc/resolv.conf",
        "Volumes": {},
        "VolumesRW": {}
    }]

There is a lot of information there, you might not need it now, but you may need it in the future, so it is nice to have it available. 

Now that you know the basics go to part 2, and learn how to build an image.

Part 2. Building an image
=========================

Our goal for this part is to create our own Redis server container. The first thing we will need to do is decide which base image we want to build on. I usually pick the base image, but sometimes it is nice to start from something a little higher so that I don't have to recreate steps, and I can build on the shoulders of others.

We are going to run /bin/bash with the ``-i`` and the ``-t`` flags. ``-i`` tells Docker to keep stdin open even if not attached, and ``-t`` is to allocate a pseudo-tty. Once we run the command, we will be connected into the container, and all commands at this point are running from inside the container.
::

    $ docker run -i -t base /bin/bash
    root@dda8bfc22397:/# hostname
    dda8bfc22397
    root@dda8bfc22397:/# ps aux
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.0  18060  1940 ?        S    21:40   0:00 /bin/bash
    root        11  0.0  0.0  15532  1136 ?        R+   21:41   0:00 ps aux

OK, it looks like we are in, and things are working well, now lets get to work.

We are going to update apt and then install redis::

    $ apt-get update
    $ apt-get install redis-server
    $ps aux
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.0  18060  1944 ?        S    22:21   0:00 /bin/bash
    redis      116  0.0  0.0  36628  1656 ?        Ssl  22:22   0:00 /usr/bin/redis-server /etc/redis/redis.conf
    root       125  0.0  0.0  15532  1140 ?        R+   22:23   0:00 ps aux
    $ exit

Now we have a container with redis installed. Less see what we did to the container::

    $ docker diff dda8bfc22397
    A /.bash_history
    C /dev
    A /dev/kmsg
    C /etc
    C /etc/bash_completion.d
    A /etc/bash_completion.d/redis-cli
    C /etc/default
    A /etc/default/redis-server
    .. (trimmed)

It should show you what files have changed (C) and which ones were added (A). Lets save our work so we can reuse this in the future. To do this we need to ``docker commit`` the container to create an image. In order to commit changes you need your container_id. If you don't remember it don'tw worry you can get it from ``docker ps -a``::

    $ docker ps -a  # grab the container id (this will be the first one in the list)
    $ docker commit <container_id> <your username>/redis
    82ebf04d9385
    
It returns an image id. if we run ``docker images`` we should see it listed::

    $ docker images
    REPOSITORY          TAG                 ID                  CREATED              SIZE
    base                latest              b750fe79269d        3 months ago         24.65 kB (virtual 180.1 MB)
    base                ubuntu-12.10        b750fe79269d        3 months ago         24.65 kB (virtual 180.1 MB)
    base                ubuntu-quantal      b750fe79269d        3 months ago         24.65 kB (virtual 180.1 MB)
    base                ubuntu-quantl       b750fe79269d        3 months ago         24.65 kB (virtual 180.1 MB)
    kencochrane/redis   latest              82ebf04d9385        About a minute ago   98.46 MB (virtual 278.6 MB)


Lets run our new image and see if it works::

    $ docker run -d -p 6379 kencochrane/redis /usr/bin/redis-server
    4cbaae2f67d0

The ``-d`` tell docker to run it in the background, just like our Hello World daemon from the last part. ``-p 6379`` says to use 6379 as the port for this container.

Test 1
Connect to the container with the redis-cli.
::

    $ docker ps  # grab the new container id
    $ docker inspect <container_id> | grep IPAddress   # grab the ipaddress of the container
    "IPAddress": "172.16.42.5",
    redis-cli -h 172.16.42.5 -p 6379
    redis 10.0.3.32:6379> set docker awesome
    OK
    redis 10.0.3.32:6379> get docker
    "awesome"
    redis 10.0.3.32:6379> exit


Connect to the public IP with the redis-cli.
:: 

    $ docker ps  # grab the new container id
    $ docker port <container_id> 6379  # grab the external port
    49153
    ip addr show   # grab the host ip address
    redis-cli -h <host ipaddress> -p 49153
    redis 192.168.0.1:49153> set docker awesome
    OK
    redis 192.168.0.1:49153> get docker
    "awesome"
    redis 192.168.0.1:49153> exit


We just proved that it is working as it should, we can now stop the container using ``docker stop``. You have now created your first Docker image. Continue on to the next part to learn how to use that image on another host, and share it with the world.

Part 3: Docker Index/registry
=============================
When you create an image it is only available on that server. In the past, if you wanted to use the same image on another server, you would need to recreate the image, which isn't ideal because there is no way to guarantee that the two images are the same. To make moving images around, and sharing them easier, the Docker team created the `Docker index <https://index.docker.io>`_.

The Docker Index is a public Registry where people can upload their custom images and share them with others. This is also where the base images are located and where you pull from when doing a ``docker pull``. There are two parts to the Docker Index. There is a web component that makes it easier for you to mange your images and account with a graphical interface. There is also the API which is what the Docker client uses to interact with the index. This allows you to do some of the tasks from the command line or the web UI.

The Docker Registry is server that stores all of the images and repositories. The Index just has the metadata about the images, repositories and the user accounts, but all of the images and repositories are stored in the Docker Registry.


Creating an Account on the Docker Index
---------------------------------------
There are two ways to create an account on the Docker Index. Either way requires that you enter a valid email address and that the email address is confirmed before you can activate the account. So make sure you enter a valid email address, and then check you email after registering so that you can click the confirmation link and confirm the account.

Command Line
~~~~~~~~~~~~
If you want to register for an account from the command line you can use the ``docker login`` command. The Docker login command will either register an account for you, or if you already have an account it will log you into the Index.

When you register via the command line, it will register you and login you in a the same time. Remember to click on the activation link in the confirmation email, or else your account isn't fully active.
::

    $ docker login
    Username (): myusername
    Password:
    Email (): myusername@example.com
    Login Succeeded

Web site
~~~~~~~~
If you prefer to register from a web browser, then go to https://index.docker.io/account/signup/ and then fill out the form, and then click on the activation link sent in the confirmation email.

Once you are activated, you will still need to login to the Docker Index from your Docker client on your server, so that you can link the two.
::

    $ docker login
    Username (): myusername
    Password:
    Email (): myusername@example.com
    Login Succeeded

Credentials
~~~~~~~~~~~
When you login to the Docker Index from the Docker client, it will store your login information, so you don't have to enter it again. Depending on what Docker client version you are using it will either be located at ``~/.dockercfg`` or ``/var/lib/docker/.dockercfg``. If you are having issues logging in you, can delete this file, and it will re-prompt you for your username and password the next time you login. Running Docker login should do the same thing, so do that first, and use this for a last resort.


Search
------
There are a lot of Docker images in the Index, with more getting added everyday. Before you go ahead and create your own, you should see if someone has already created what you wanted. The best way to find images is via the ``docker search`` command on the command line, or via the Docker Index website.
:: 

    $ docker search memcache
    Found 5 results matching your query ("memcache")
    NAME                     DESCRIPTION
    ehazlett/memcached       Memcached 1.4.15.  Specify the following e...
    jbarbier/memcached       memcached
    checkraiser/memcached
    arcus/memcached
    bacongobbler/memcached

Pulling
-------
When you found an image that you want to pull down and try out, you would use the ``docker pull`` command. It will then connect to the Docker Index find the repository that you want, and it will let the Docker client know where in the Docker Registry it can download it.
::

    $ docker pull jbarbier/memcached

Pushing
-------
If you have a repository that you want to share with someone then you would need to push it into the Docker Index/Registry using the ``docker push`` command.  When you do a push, it will contact the Docker Index, and make sure you are logged in, have permission to push, and that the same repository doesn't already exist. If everything looks good, it will then return a special authorization token that the Docker client will use when push up the repository to the Docker Registry. 

Since the Docker Register doesn't have any concept of authorization, or user accounts, it relies on Authorization tokens to manage permissions. The nice thing about this, is that Docker hides this all from you, and you don't even need to worry about it, it will just work assuming you have permission to push.

Let's push the repository that we created in the last part, so that others can use it.
::

    $ docker push kencochrane/redis

Now that it is up on the registry we can use it on any Docker host, and we just need to do a ``Docker pull`` to get it on the host, and I'll know it is going to be the same every time.


Repository Description
----------------------
If you want to add a description to your repository so that it lets people know what it does, you can login to the website and edit the description there. There are two descriptions, a short one, which is what shows up in search results, and is plain text. There is also a full description which allows MarkDown and is used to give more detailed information. 

Deleting a Repository
---------------------
If you made a mistake and need to delete a repository, you can do this by logging into the Docker Index website, and clicking on the repository settings and clicking the delete button. Make sure this is what you want to do, because there is no turning back once you do this.


Part 4: Docker Buildfiles
=========================
TODO:

- Go over what a Docker Buildfile is, and how to make their own.
- With examples

Part 5: Advanced Usage
======================
TODO:

- docker run
    - limiting memory, cpu
    - detached vs attached
    - volume/bind mounting
- More?

Part 6: Using a Private Registry
================================
TODO:

- what is the private registry, and why would you use?
- setting up your own private registry
- how to use the private registry


Part 7: Automating Docker
=========================
Running docker commands on the command line are a good way to start, but if you need to automate what you are doing, it isn't ideal. To make this better Docker provides a REST based remote API. The remote API allows you to do everything that the command line does. In fact the command line is just a client for the REST API. 

Remote API
-----------
Docker provides a remote API for the docker daemon so that you can control it programmatically, for documentation on how it works check out the `Docker Remote API Docs <http://docs.docker.io/en/latest/api/docker_remote_api/>`_

Docker Web UI's
---------------
Docker is a completly command line experience, which is fine for hackers, but some people prefer a more graphical experience, and for those folks I would recommend checking out these projects that people have started.

Dockland
~~~~~~~~
A ruby based Docker web UI

Code: https://github.com/dynport/dockland

Shipyard
~~~~~~~~
A python/django based Docker web UI

Code: https://github.com/ehazlett/shipyard

DockerUI
~~~~~~~~
An Angular.js based Docker web UI

Code: https://github.com/crosbymichael/dockerui


Docker Libraries
-----------------
If you want to write some code to interact with Docker, there is most likely already a binding for your programming language. Check out the link in the documentation to find what is available. If there isn't one available for your language of choice, feel free to create your own, and let us know so we can update the documentation.

`Docker Library list in the Docker Docs <http://docs.docker.io/en/latest/api/docker_remote_api/#id15>`_

What can I do to help?
======================
If you are a big fan of Docker, and want to know how to help out, then look at the list below, and see if any of them are things that you can do.

- Contribute to Docker, it could be as small as a bug fix, documentation update, or a new feature. Look through the `docker issues <https://github.com/dotcloud/docker/issues?state=open>`_, and see if anything tickles your fancy.
- Tweet about how much you love Docker
- Write a blog post about how you use Docker, and how others can do what you have done.
- Talk at a conference or meetup. This is a good way to introduce docker to a new set of potential Docker lovers.
- Create a product that uses Docker, and let everyone know how Docker made your life easier.
- Make a video showing how you use Docker, and upload to YouTube/Vimeo.
- Answer questions on 
    - Stack Overflow
    - IRC
    - Mailing list
- Attend the Docker hack days and meet other Docker users, and let us know how we can make Docker even better.
- Get a `Docker` sticker, and display it proudly.
- Wear your Docker shirt and wear it around town all day.


Docker Commands
===============
Here is a list of all of the current Docker commands, the different parameters they might have, as well as an example or two on how to use them.

attach
------
Attach to a running container.

Parameters
~~~~~~~~~~
- CONTAINER_ID: The ID for the container you want to attach too.

Usage
~~~~~
::

    docker attach CONTAINER_ID

Example
~~~~~~~
::

    docker attach afs232ybh2123d

build
-----
Build a container from a Dockerfile

Parameters
~~~~~~~~~~
- PATH: Build a new container image from the source code at PATH
- URL: When a single Dockerfile is given as URL, then no context is set. When a git repository is set as URL, the repository is used as context
- OPTIONS:
    - -t="" : Tag to be applied to the resulting image in case of success.

Usage
~~~~~
::

    docker build [OPTIONS] PATH | URL | -

Examples
~~~~~~~~

Read the Dockerfile from the current directory
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    docker build .

This will read the Dockerfile from the current directory. It will also send any other files and directories found in the current directory to the docker daemon. The contents of this directory would be used by ADD commands found within the Dockerfile.
This will send a lot of data to the docker daemon if the current directory contains a lot of data.
If the absolute path is provided instead of ‘.’, only the files and directories required by the ADD commands from the Dockerfile will be added to the context and transferred to the docker daemon.

Read a Dockerfile from standard in (stdin) without context
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    docker build - < Dockerfile
    
This will read a Dockerfile from Stdin without context. Due to the lack of a context, no contents of any local directory will be sent to the docker daemon. ADD doesn’t work when running in this mode due to the absence of the context, thus having no source files to copy to the container.


Build from a git repo
^^^^^^^^^^^^^^^^^^^^^^
::

    docker build github.com/creack/docker-firefox

This will clone the github repository and use it as context. The Dockerfile at the root of the repository is used as Dockerfile.
Note that you can specify an arbitrary git repository by using the ‘git://’ schema.


commit
------
Save your containers state to a container image, so the state can be re-used.

When you commit your container only the differences between the image the container was created from and the current state of the container will be stored (as a diff). See which images you already have using docker images

In order to commit to the repository it is required to have committed your container to an image with your namespace.

Parameters
~~~~~~~~~~
- CONTAINER_ID: The container ID for the container you want to commit
- REPOSITORY: The name for your image that you will save to the repository <your username>/<image name>
- TAG: The tag you want to give to the commit.
- OPTIONS:
    - -m="": Commit message
    - -author="": Author (eg. "John Hannibal Smith <hannibal@a-team.com>"
    - -run="": Config automatically applied when the image is run. "+`(ex: {"Cmd": ["cat", "/world"], "PortSpecs": ["22"]}')

Usage
~~~~~
::

    docker commit [OPTIONS] CONTAINER_ID [REPOSITORY [TAG]]

Examples
~~~~~~~~


basic commit
^^^^^^^^^^^^
This will commit a container with a message and author.
::

    docker commit -m="My commit message" -author="Joe smith" a1bcbabsdhb323h2b

commit with repository
^^^^^^^^^^^^^^^^^^^^^^
Same as basic commit, but with a repository name
::

    docker commit -m="My commit message" -author="Joe smith" a1bcbabsdhb323h2b joesmith/myrepo

commit with tag
^^^^^^^^^^^^^^^
Same as basic commit, but with a repository name and tag
::

    docker commit -m="My commit message" -author="Joe smith" a1bcbabsdhb323h2b joesmith/myrepo mytag


Full example
^^^^^^^^^^^^
An example with all parameters and options.
::

    docker commit -m="My commit message" -author="Joe smith" -run='{"Hostname": "", "User": "","CpuShares": 0,"Memory": 0,"MemorySwap": 0,"PortSpecs": ["22", "80", "443"],"Tty": true,"OpenStdin": true,"StdinOnce": true,"Env": ["FOO=BAR", "FOO2=BAR2"],"Cmd": ["cat", "-e", "/etc/resolv.conf"],"Dns": ["8.8.8.8", "8.8.4.4"]}' a1bcbabsdhb323h2b joesmith/myrepo mytag


diff
---- 
Inspect changes on a container’s filesystem

Parameters
~~~~~~~~~~
- CONTAINER_ID: The ID for the container you want to create a diff for


Usage
~~~~~
::

    docker diff CONTAINER_ID

Examples
~~~~~~~~
::

    docker diff a1bcbabsdhb323h2b


export
------
Stream the contents of a container as a tar archive

Parameters
~~~~~~~~~~
- CONTAINER_ID: The ID for the container you want to export.

Usage
~~~~~
::

    docker export CONTAINER_ID

Examples
~~~~~~~~
::

    docker export a1bcbabsdhb323h2b > myfile.tar


history
-------
Show the history of an image

Parameters
~~~~~~~~~~
- IMAGE: The name of the image you want to see the history for

Usage
~~~~~
::

    docker history IMAGE

Examples
~~~~~~~~
::

    docker history joesmith/myimage


images
------
List the images managed by Docker

Parameters
~~~~~~~~~~
- NAME: A filter to limit results to only images matching the NAME
- OPTIONS:
    - -a=false: show all images
    - -q=false: only show numeric IDs
    - -viz=false: output in graphviz format

Usage
~~~~~
::

    docker images [OPTIONS] [NAME]

Examples
~~~~~~~~

Show images
^^^^^^^^^^^
::

    docker images

Show images with name ubuntu
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    docker images ubuntu

Show all images
^^^^^^^^^^^^^^^
::

    docker images -a

Show only image ID's
^^^^^^^^^^^^^^^^^^^^
::

    docker images -q

Displaying images visually
^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    docker images -viz | dot -Tpng -o docker.png


import
------
Create a new filesystem image from the contents of a tarball

Parameters
~~~~~~~~~~
- URL: At this time, the URL must start with http and point to a single file archive (.tar, .tar.gz, .bzip) containing a root filesystem. If you would like to import from a local directory or archive, you can use the - parameter to take the data from standard in.
- TAG: name of the tag you want to assign repo after import
- REPOSITORY: the repository to import into.

Usage
~~~~~
::

    docker import URL |- [REPOSITORY [TAG]]

Examples
~~~~~~~~

Import from a remote location
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker import http://example.com/exampleimage.tgz exampleimagerepo

Import from a local file
^^^^^^^^^^^^^^^^^^^^^^^^
Import to docker via pipe and standard in::

    $ cat exampleimage.tgz | docker import - exampleimagelocal

Import from a local directory
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Note the sudo in this example – you must preserve the ownership of the files (especially root ownership) during the archiving with tar. If you are not root (or sudo) when you tar, then the ownerships might not get preserved.
::

    $ sudo tar -c . | docker import - exampleimagedir


info
----
Display system-wide information.

Parameters
~~~~~~~~~~
None

Usage
~~~~~
::

    $ docker info

Examples
~~~~~~~~
::

    $ docker info
    Containers: 30
    Images: 25
    Debug mode (server): true
    Debug mode (client): false
    Fds: 8
    Goroutines: 10


inspect
-------
Return low-level information on a container/image. The command will take 1 or more container or image ids and return all of the information relating to those ids.

Parameters
~~~~~~~~~~
- CONTAINER: The ID for the container you want to export.
- IMAGE: The image name for the images you want information for.

Usage
~~~~~
::

    $ docker inspect CONTAINER|IMAGE [CONTAINER|IMAGE...]

Examples
~~~~~~~~

Container inspect
^^^^^^^^^^^^^^^^^
Inspect one container
::
    
    $ docker inspect a5e78640ece4
    [{
        "ID": "a5e78640ece4b64657b86780ebfeacf614c402cf3b30bb2226f9f8abd48a46ff",
        "Created": "2013-07-05T22:43:36.281232878Z",
        "Path": "sh",
        "Args": [],
        "Config": {
            "Hostname": "a5e78640ece4",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": true,
            "AttachStdout": true,
            "AttachStderr": true,
            "PortSpecs": null,
            "Tty": true,
            "OpenStdin": true,
            "StdinOnce": true,
            "Env": null,
            "Cmd": [
                "sh"
            ],
            "Dns": null,
            "Image": "joffrey/busybox",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": []
        },
        "State": {
            "Running": false,
            "Pid": 0,
            "ExitCode": 0,
            "StartedAt": "2013-07-05T22:43:36.286163881Z",
            "Ghost": false
        },
        "Image": "e74096c5172b34732c9769db5f23805cf786dffe25f25da66ebf7c0fc30d0e0b",
        "NetworkSettings": {
            "IPAddress": "",
            "IPPrefixLen": 0,
            "Gateway": "",
            "Bridge": "",
            "PortMapping": null
        },
        "SysInitPath": "/usr/bin/docker",
        "ResolvConfPath": "/etc/resolv.conf",
        "Volumes": {},
        "VolumesRW": {}
    }]


Inspect more then one container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Inspect 2 containers
::

    $ docker inspect a5e78640ece4 0775b219a48a
    [{
        "ID": "a5e78640ece4b64657b86780ebfeacf614c402cf3b30bb2226f9f8abd48a46ff",
        "Created": "2013-07-05T22:43:36.281232878Z",
        "Path": "sh",
        "Args": [],
        "Config": {
            "Hostname": "a5e78640ece4",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": true,
            "AttachStdout": true,
            "AttachStderr": true,
            "PortSpecs": null,
            "Tty": true,
            "OpenStdin": true,
            "StdinOnce": true,
            "Env": null,
            "Cmd": [
                "sh"
            ],
            "Dns": null,
            "Image": "joffrey/busybox",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": []
        },
        "State": {
            "Running": false,
            "Pid": 0,
            "ExitCode": 0,
            "StartedAt": "2013-07-05T22:43:36.286163881Z",
            "Ghost": false
        },
        "Image": "e74096c5172b34732c9769db5f23805cf786dffe25f25da66ebf7c0fc30d0e0b",
        "NetworkSettings": {
            "IPAddress": "",
            "IPPrefixLen": 0,
            "Gateway": "",
            "Bridge": "",
            "PortMapping": null
        },
        "SysInitPath": "/usr/bin/docker",
        "ResolvConfPath": "/etc/resolv.conf",
        "Volumes": {},
        "VolumesRW": {}
    },{
        "ID": "0775b219a48ab9bbebe841a0388f9909e996140f941585e318dbe64289392534",
        "Created": "2013-07-05T22:40:47.219244957Z",
        "Path": "sh",
        "Args": [],
        "Config": {
            "Hostname": "0775b219a48a",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": true,
            "AttachStdout": true,
            "AttachStderr": true,
            "PortSpecs": null,
            "Tty": true,
            "OpenStdin": true,
            "StdinOnce": true,
            "Env": null,
            "Cmd": [
                "sh"
            ],
            "Dns": null,
            "Image": "joffrey/busybox",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": []
        },
        "State": {
            "Running": false,
            "Pid": 0,
            "ExitCode": 127,
            "StartedAt": "2013-07-05T22:40:47.224570459Z",
            "Ghost": false
        },
        "Image": "e74096c5172b34732c9769db5f23805cf786dffe25f25da66ebf7c0fc30d0e0b",
        "NetworkSettings": {
            "IPAddress": "",
            "IPPrefixLen": 0,
            "Gateway": "",
            "Bridge": "",
            "PortMapping": null
        },
        "SysInitPath": "/usr/bin/docker",
        "ResolvConfPath": "/etc/resolv.conf",
        "Volumes": {},
        "VolumesRW": {}
    }]


Image inspect
^^^^^^^^^^^^^
Inspect an Image::

    $ docker inspect bced7ad27b98
    [{
        "id": "bced7ad27b98ea990fae3a7479632419109c7a14412365af379a26393ca0492b",
        "parent": "c7fe644d47bc05b6990fafec2f4b61fa0c9f7b248af6e754cbcd9c9507af36b1",
        "created": "2013-06-28T16:45:01.056208611Z",
        "container": "2deff3a37f8b5e1ce6e23ce420be07609df3813429909e2cfe5426c46f0a9552",
        "container_config": {
            "Hostname": "2deff3a37f8b",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": [
                "/bin/sh",
                "-c",
                "apt-get install -y curl"
            ],
            "Dns": null,
            "Image": "c7fe644d47bc",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "docker_version": "0.4.6",
        "author": "Ken \"ken@example.com\"",
        "config": {
            "Hostname": "",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": null,
            "Dns": null,
            "Image": "",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "architecture": "x86_64",
        "Size": 4096
    }]


Multiple Image inspect
^^^^^^^^^^^^^^^^^^^^^^
Inspect more then one image at a time::

    $  docker inspect bced7ad27b98 e74096c5172b
    [{
        "id": "bced7ad27b98ea990fae3a7479632419109c7a14412365af379a26393ca0492b",
        "parent": "c7fe644d47bc05b6990fafec2f4b61fa0c9f7b248af6e754cbcd9c9507af36b1",
        "created": "2013-06-28T16:45:01.056208611Z",
        "container": "2deff3a37f8b5e1ce6e23ce420be07609df3813429909e2cfe5426c46f0a9552",
        "container_config": {
            "Hostname": "2deff3a37f8b",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": [
                "/bin/sh",
                "-c",
                "apt-get install -y curl"
            ],
            "Dns": null,
            "Image": "c7fe644d47bc",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "docker_version": "0.4.6",
        "author": "Ken \"ken@example.com\"",
        "config": {
            "Hostname": "",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": null,
            "Dns": null,
            "Image": "",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "architecture": "x86_64",
        "Size": 4096
    },{
        "id": "e74096c5172b34732c9769db5f23805cf786dffe25f25da66ebf7c0fc30d0e0b",
        "parent": "e9aa60c60128cad1",
        "created": "2013-05-09T09:45:26.287021-07:00",
        "container": "73f9f76d46cc07b3a6aa4e96c85dbabbfc4d1345697f263d5cd1741b5b05d6f2",
        "container_config": {
            "Hostname": "73f9f76d46cc",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": true,
            "AttachStderr": true,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": [
                "ls"
            ],
            "Dns": null,
            "Image": "busybox",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "docker_version": "0.3.0",
        "Size": 16391
    }]


Container and Image inspect
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Inspect a container and an image at the same time::

    $ docker inspect bced7ad27b98 a5e78640ece4
    [{
        "id": "bced7ad27b98ea990fae3a7479632419109c7a14412365af379a26393ca0492b",
        "parent": "c7fe644d47bc05b6990fafec2f4b61fa0c9f7b248af6e754cbcd9c9507af36b1",
        "created": "2013-06-28T16:45:01.056208611Z",
        "container": "2deff3a37f8b5e1ce6e23ce420be07609df3813429909e2cfe5426c46f0a9552",
        "container_config": {
            "Hostname": "2deff3a37f8b",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": [
                "/bin/sh",
                "-c",
                "apt-get install -y curl"
            ],
            "Dns": null,
            "Image": "c7fe644d47bc",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "docker_version": "0.4.6",
        "author": "Ken \"ken@dotcloud.com\"",
        "config": {
            "Hostname": "",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "PortSpecs": null,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": null,
            "Dns": null,
            "Image": "",
            "Volumes": null,
            "VolumesFrom": "",
            "Entrypoint": null
        },
        "architecture": "x86_64",
        "Size": 4096
    },{
        "ID": "a5e78640ece4b64657b86780ebfeacf614c402cf3b30bb2226f9f8abd48a46ff",
        "Created": "2013-07-05T22:43:36.281232878Z",
        "Path": "sh",
        "Args": [],
        "Config": {
            "Hostname": "a5e78640ece4",
            "User": "",
            "Memory": 0,
            "MemorySwap": 0,
            "CpuShares": 0,
            "AttachStdin": true,
            "AttachStdout": true,
            "AttachStderr": true,
            "PortSpecs": null,
            "Tty": true,
            "OpenStdin": true,
            "StdinOnce": true,
            "Env": null,
            "Cmd": [
                "sh"
            ],
            "Dns": null,
            "Image": "joffrey/busybox",
            "Volumes": {},
            "VolumesFrom": "",
            "Entrypoint": []
        },
        "State": {
            "Running": false,
            "Pid": 0,
            "ExitCode": 0,
            "StartedAt": "2013-07-05T22:43:36.286163881Z",
            "Ghost": false
        },
        "Image": "e74096c5172b34732c9769db5f23805cf786dffe25f25da66ebf7c0fc30d0e0b",
        "NetworkSettings": {
            "IPAddress": "",
            "IPPrefixLen": 0,
            "Gateway": "",
            "Bridge": "",
            "PortMapping": null
        },
        "SysInitPath": "/usr/bin/docker",
        "ResolvConfPath": "/etc/resolv.conf",
        "Volumes": {},
        "VolumesRW": {}
    }]

kill
----
Kill a running container(s). If the container won't stop, you can brute force it with the kill command.

Parameters
~~~~~~~~~~
- CONTAINER: The container id for the container you want to kill, can be one or a list separated by spaces.

Usage
~~~~~
::

    $ docker kill CONTAINER [CONTAINER...]

Examples
~~~~~~~~

Kill one container
^^^^^^^^^^^^^^^^^^
::
    
    $ docker kill a5e78640ece4
    a5e78640ece4

Kill more then one container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::
    
    $ docker kill a5e78640ece4 0775b219a48a
    a5e78640ece4
    0775b219a48a

login
-----
Register or Login to the docker registry server. If you have an account it will log you in, and cache the credentials, if you don't  have an account it will create one for you, and automatically log you in. You can pass in the username, email and password as command line parameters to easily script out the login process.

Parameters
~~~~~~~~~~
- OPTIONS:
    - e: email
    - p: password
    - u: username

Usage
~~~~~
::

    $ docker login [OPTIONS]

Examples
~~~~~~~~
Login with prompts
^^^^^^^^^^^^^^^^^^
::

    $ docker login
    Username (): myusername
    Password:
    Email (): myusername@example.com
    Login Succeeded

Login with parameters
^^^^^^^^^^^^^^^^^^^^^
::
    $ docker login -u myusername -p mypassword -e myusername@example.com
    Login Succeeded

logs
----
Fetch the logs of a container

Parameters
~~~~~~~~~~
- CONTAINER: The Container ID for the Container you want to get the logs for.

Usage
~~~~~
::

    $ docker logs CONTAINER

Examples
~~~~~~~~
::

    $ docker logs a5e78640ece4
    some logs from my container
    some logs from my container
    some logs from my container
    ...


port
----
Lookup the public-facing port which is NAT-ed to PRIVATE_PORT

Parameters
~~~~~~~~~~
- CONTAINER: The Container ID for the container you want to find the port for
- PRIVATE_PORT: The private port, you want to find the matching Public port for

Usage
~~~~~
::

     $ docker port CONTAINER PRIVATE_PORT

Examples
~~~~~~~~
::

    $ docker port 335c587d6ad1 6379
    49153

ps
--
List containers

Parameters
~~~~~~~~~~
- OPTIONS:
    - -a=false: Show all containers. Only running containers are shown by default.
    - -notrunc=false: Don't truncate output
    - -q=false: Only display numeric IDs

Usage
~~~~~
::

    docker ps [OPTIONS]

Examples
~~~~~~~~

Show running containers
^^^^^^^^^^^^^^^^^^^^^^^
::
    
    $ docker ps
    ID                  IMAGE                    COMMAND                CREATED             STATUS              PORTS
    335c587d6ad1        joffrey/busybox:latest   /bin/sh -c while tru   3 minutes ago       Up 3 minutes        49153->6379

Show all containers
^^^^^^^^^^^^^^^^^^^
::

    $ docker ps -a
    ID                  IMAGE                    COMMAND                CREATED             STATUS              PORTS
    335c587d6ad1        joffrey/busybox:latest   /bin/sh -c while tru   3 minutes ago       Up 3 minutes        49153->6379
    1347dbb9d32f        joffrey/busybox:latest   /bin/sh -c while tru   4 minutes ago       Exit 137
    db2db67170ba        joffrey/busybox:latest   /bin/echo hi           5 minutes ago       Exit 0
    a5e78640ece4        joffrey/busybox:latest   sh                     6 days ago          Exit 0
    0775b219a48a        joffrey/busybox:latest   sh                     6 days ago          Exit 127
    1668f16b3ef4        joffrey/busybox:latest   bash                   6 days ago          Exit 127
    ... trimed

show all containers full output
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker ps -a -notrunc
    ID                                                                 IMAGE                    COMMAND                                                         CREATED             STATUS              PORTS
    335c587d6ad121519e1489b837e80a5efb748669c86a8bdd485867759fb3c9a7   joffrey/busybox:latest   /bin/sh -c while true; do echo hello world; sleep 1; done   4 minutes ago       Up 4 minutes        49153->6379
    1347dbb9d32fcafe922a58e6b01c56d04d35fbd3f3226e3789c30310222eceee   joffrey/busybox:latest   /bin/sh -c while true; do echo hello world; sleep 1; done   5 minutes ago       Exit 137
    db2db67170ba9e1df14cadcaa6f172ad743b387eea3a9c454001279649463cdb   joffrey/busybox:latest   /bin/echo hi                                                6 minutes ago       Exit 0
    ... Trimmed

show only container ids
^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker ps -q -a
    335c587d6ad1
    1347dbb9d32f
    db2db67170ba
    a5e78640ece4
    0775b219a48a
    ... trimmed

pull
----
Pull an image or a repository from the docker registry server. By default it will always pull down the latest version, but you can also pull by tag.

Parameters
~~~~~~~~~~
- NAME: the name of the repository to pull from registry
- OPTIONS:
    - -t: Tag, if you want to pull down a tagged version of the repository.
Usage
~~~~~
::

    $ docker pull NAME


Examples
~~~~~~~~

Pull library repository
^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker pull base

Pull User repository
^^^^^^^^^^^^^^^^^^^^
::

    $ docker pull samalba/hipache

Pull repository by tag
^^^^^^^^^^^^^^^^^^^^^^
replace `latest` with the tag name you want to pull.
::

    $ docker pull samalba/hipache:latest

or use the command line flag `-t`

::

    $ docker pull -t latest samalba/hipache


push
----
Push an image or a repository to the docker registry server

Parameters
~~~~~~~~~~
- NAME: the name of the repository to push to the registry

Usage
~~~~~
::

    $ docker push NAME


Examples
~~~~~~~~
::

    $ docker push kencochrane/testrepo


restart
-------
Restart one or more running containers

Parameters
~~~~~~~~~~
- CONTAINER: The Container ID for the container you want to restart
- OPTIONS:
    - t: Number of seconds to try to stop for before killing the container. Once killed it will then be restarted

Usage
~~~~~
::

    $ docker restart [OPTIONS] CONTAINER [CONTAINER ...]

Examples
~~~~~~~~
restart container
^^^^^^^^^^^^^^^^^
::

    $ docker restart 335c587d6ad1
    335c587d6ad1

restart multiple containers
^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker restart 335c587d6ad1 1347dbb9d32f
    335c587d6ad1
    1347dbb9d32f

restart container with 15 second timeout
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker restart -t 15 335c587d6ad1
    335c587d6ad1

rm
--
Remove a container

Parameters
~~~~~~~~~~
- CONTAINER: The Container ID for the container you want to remove
- OPTIONS:
    - v: Remove the volumes associated to the container

Usage
~~~~~
::

    $ docker rm [OPTIONS] CONTAINER

Examples
~~~~~~~~

Remove container
^^^^^^^^^^^^^^^^
::

    $ docker rm 335c587d6ad1

Remove container and volume
^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker rm -v 335c587d6ad1


rmi
---
Remove one or more images

Parameters
~~~~~~~~~~
- IMAGE: The ID for the image you want to remove

Usage
~~~~~
::

    $ docker rmi IMAGE [IMAGE...]

Examples
~~~~~~~~

Remove one image
^^^^^^^^^^^^^^^^
::

    $ docker rmi bced7ad27b98

Remove more then one image
^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker rmi bced7ad27b98 e74096c5172b


run
---
Run a command in a new container

Parameters
~~~~~~~~~~
IMAGE: The name of the image you want to create a container from
OPTIONS:
    - a=map[]: Attach to stdin, stdout or stderr.
    - c=0: CPU shares (relative weight)
    - d=false: Detached mode: leave the container running in the background
    - e=[]: Set environment variables
    - h="": Container host name
    - i=false: Keep stdin open even if not attached
    - m=0: Memory limit (in bytes)
    - p=[]: Map a network port to the container
    - t=false: Allocate a pseudo-tty
    - u="": Username or UID
    - d=[]: Set custom dns servers for the container
    - v=[]: Creates a new volume and mounts it at the specified path.
    - volumes-from="": Mount all volumes from the given container.
    - b=[]: Create a bind mount with: [host-dir]:[container-dir]:[rw|ro]
    - entrypoint="": Overwrite the default entrypoint set by the image.

Usage
~~~~~
::

    $ docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

Examples
~~~~~~~~

Run container in foreground
^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Run container in background
^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Start container with memory limit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Limit containers CPU shares
^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Set container environment variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Attach a Volume to a container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Set custom DBS server for the container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Create bind mount for container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Override the default entrypoint set by image
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

search
------
Search for an image in the docker index

Parameters
~~~~~~~~~~
- TERM: Search term
- OPTIONS:
    - notrunc

Usage
~~~~~
::

    $ docker search [OPTIONS] TERM


Examples
~~~~~~~~

Normal search
^^^^^^^^^^^^^
::

    $ docker search base

Show full results
^^^^^^^^^^^^^^^^^
This will not truncate the description field for the search results
::

    $ docker search -notrunc base

start
-----
Start one or more stopped containers

Parameters
~~~~~~~~~~
- CONTAINER: The container ID for the container you want to start

Usage
~~~~~
::

    $ docker start CONTAINER [CONTAINER...]

Examples
~~~~~~~~

Start one container
^^^^^^^^^^^^^^^^^^^
::

    $ docker start 335c587d6ad1
    335c587d6ad1

Start two containers
^^^^^^^^^^^^^^^^^^^^
::
    
    $ docker start 335c587d6ad1 1347dbb9d32f
    335c587d6ad1
    1347dbb9d32f

stop
----
Stop a running container

Parameters
~~~~~~~~~~
- CONTAINER: The container ID for the container you want to stop
- OPTIONS:
    - t=10: Number of seconds to try to stop for before killing the container.

Usage
~~~~~
::

    $ docker stop [OPTIONS] CONTAINER [CONTAINER...]

Examples
~~~~~~~~

Stop one container
^^^^^^^^^^^^^^^^^^^
::

    $ docker stop 335c587d6ad1
    335c587d6ad1

Stop two containers
^^^^^^^^^^^^^^^^^^^^
::
    
    $ docker stop 335c587d6ad1 1347dbb9d32f
    335c587d6ad1
    1347dbb9d32f

Stop container with 15 second timeout
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
::

    $ docker stop -t 15 335c587d6ad1
    335c587d6ad1


tag
---
Tag an image into a repository

Parameters
~~~~~~~~~~
- IMAGE: The image to tag
- REPOSITORY: The repository name in the registry
- TAG: The tag name
- OPTIONS:
    - f=false: Force

Usage
~~~~~
::

    $ docker tag [OPTIONS] IMAGE REPOSITORY [TAG]

Examples
~~~~~~~~

Tag an image
^^^^^^^^^^^^
TODO:

Tag an image, without specifying a Tag
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TODO:

Force setting a Tag
^^^^^^^^^^^^^^^^^^^
TODO:


version
-------
Show the docker version information

Parameters
~~~~~~~~~~
None

Usage
~~~~~
::

    $ docker version

Examples
~~~~~~~~
::

    $ docker version
    Client version: 0.4.8
    Server version: 0.4.8
    Go version: go1.1


wait
----
Block until a container stops, then print its exit code

Parameters
~~~~~~~~~~
- CONTAINER: The container ID for the container you want to wait for

Usage
~~~~~
::
    
    $ docker wait CONTAINER

Examples
~~~~~~~~
::

    $ docker wait 335c587d6ad1
    0
