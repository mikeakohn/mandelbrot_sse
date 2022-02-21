
MSP430 Mandelbrot Cluster
=========================

This is a project for connecting multiple MSP430 chips with a shared
SPI bus to a Raspberry Pi for calculating Mandelbrots. For more information
visit:

https://www.mikekohn.net/micro/msp430_cluster.php

Files
=====

    cluster.asm: Main firmware on MSP430's for downloading and running code.

    Mandelbrot.java   Code that gets uploaded to each MSP430.
    modify_mandel.py  Modifies the generated Java Grinder code.

    bmp.py            Python module for creating BMP files.
    msp430.py         Python module for communicating with MSP430 nodes.

    cluster_upload.py Uploads a function to MSP430 chip.
    cluster_run.py    Main Mandelbrot routine that uses MSP430's for each pixel.
    software.py       Code for computing Mandelbrots in software.

