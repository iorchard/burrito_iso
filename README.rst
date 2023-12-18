Burrito ISO
=============

This creates a custom iso for Burrito installation.
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
    ex) ./run.sh --build 8.9 1.3.1

There will be burrito-<burrito_source_version>-<rocky_linux_version>.iso and 
SHA512SUM files in output directory.::

    $ ls output
    burrito-1.3.1_8.9.iso  SHA512SUM

Use the iso file to install Burrito Rocky Linux OS.

Install Burrito from USB
------------------------

Insert your USB stick and the linux system should be automatically 
recognized and the USB stick will be mapped to a device named /dev/sdX which
X is a letter in the range of a-z.
You can find out which device the USB stick is mapped by running the command
**lsblk** or see the output of **dmesg** as root.

Make sure the device is not mounted. If it is mounted, unmount it with 
the command **umount** as root.

The iso file should be written directly to the USB stick.
Copy the iso file to the device.::

    # cp <iso_file> /dev/sdX
    # sync

Unplug the USB stick.


    $ 
