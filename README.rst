Burrito ISO
=============

This creates a custom iso for Burrito OS installation.
Burrito is the OpenStack on Kubernetes platform.
(https://github.com/iorchard/burrito.git)

pre-requisites
------------------

I assume the user has a sudo privilege.

Install the following rpm packages.::

    $ sudo dnf -y install createrepo_c modulemd-tools \
                genisoimage findutils python3 git

Build an ISO
--------------

Download the latest Rocky Linux 8 minimal iso file.::

    $ curl -LO https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.7-x86_64-minimal.iso

Mount it and copy the iso files to iso/ directory.::

    $ sudo mount -o loop,ro Rocky-8.7-x86_64-minimal.iso /mnt
    $ rsync -av --progress /mnt/ ./iso/ \
        --exclude BaseOS --exclude Minimal

Run geniso.sh script.::

    $ ./geniso.sh

If it runs okay, there will be burrito-<version>.iso and SHA512SUM files.::

    $ ls burrito*.iso SHA512SUM 
    burrito-8.7.iso  SHA512SUM

Use the iso file to install Burrito OS.

