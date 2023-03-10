===========================
Ninux NNXX - Openwrt Builds
===========================

.. image:: https://github.com/mikysal78/ninux-build-openwrt/blob/master/workflows/nnxx.png
    :target: http://wiki.ninux.org/nnxx
    :alt: Ninux NNXX

-----------

Build
-----
-

Build script:

.. code-block:: shell

    ./build.sh tplink_c2600

-

Build manually:

.. code-block:: shell

    cd openwrt
    make menuconfig
    make defconfig
    make V=s

-

Write your SD card:

.. code-block:: shell

    gzip -k -d openwrt/bin/path_xxx/file_xxx.img.gz
    dd if=openwrt/bin/path_xxx/file_xxx.img of=/dev/YOURSDCARD

-

-----------

Clean
-----
Cleaning Up (in openwrt directory):

.. code-block:: shell

    make clean


deletes contents of the directories /bin and /build_dir. make clean does not remove the toolchain, it also avoids cleaning architectures/targets other than the one you have selected in your .config

-

Dirclean:

.. code-block:: shell

    make dirclean


deletes contents of the directories /bin and /build_dir and additionally /staging_dir and /toolchain (=the cross-compile tools) and /logs. 'Dirclean' is your basic "Full clean" operation.


-

Distclean:

.. code-block:: shell

    make distclean

nukes everything you have compiled or configured and also deletes all downloaded feeds contents and package sources.


*CAUTION* : In addition to all else, this will erase your build configuration (<buildroot_dir>/.config), your toolchain and all other sources. Use with care!

-----------

Jenkins
-------

.. image:: https://github.com/mikysal78/ninux-build-openwrt/blob/master/workflows/project.png
    :alt: Jenkins project

.. image:: https://github.com/mikysal78/ninux-build-openwrt/blob/master/workflows/repo.png
    :alt: Jenkins repository

.. image:: https://github.com/mikysal78/ninux-build-openwrt/blob/master/workflows/esegui.png
    :alt: Jenkins build

