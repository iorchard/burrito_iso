Burrito ISO
=============

This creates a custom iso for Burrito OS installation.
Burrito is the OpenStack on Kubernetes platform.
(https://github.com/iorchard/burrito.git)

pre-requisites
------------------

I assume podman is installed on builder.

Install the following packages.::

    $ sudo dnf -y install podman

Build an ISO
--------------

Create an image.::

    $ podman build -t burrito-isobuilder .

Run a container to build.::

    $ podman run -v output:/output --rm burrito-isobuilder

Or just execute run.sh to build an image and run a container to build.::

    $ ./run.sh

There will be burrito-<version>.iso and SHA512SUM files in your volume.::

    $ cd $(podman volume inspect --format "{{.Mountpoint}}" output)
    $ ls burrito*.iso SHA512SUM 
    burrito-8.7.iso  SHA512SUM

Use the iso file to install Burrito OS.
