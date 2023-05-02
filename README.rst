Burrito ISO
=============

This creates a custom iso for Burrito OS installation.
Burrito is the OpenStack on Kubernetes platform.
(https://github.com/iorchard/burrito.git)

pre-requisites
------------------

I assume podman is installed on builder.

Install the package.::

    $ sudo dnf -y install podman

Build an ISO
--------------

Execute run.sh to build an image and run a container to build.::

    $ ./run.sh --build <rocky_linux_verion> <burrito_source_version>
    ex) ./run.sh --build 8.7 1.0.0

There will be burrito-<burrito_source_version>-<rocky_linux_version>.iso and 
SHA512SUM files in output directory.::

    $ ls output
    burrito-1.0.0_8.7.iso  SHA512SUM

Use the iso file to install Burrito OS.
