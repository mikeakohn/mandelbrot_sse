Mandelbrots SIMD
================

Here are some examples of generating Mandelbrots using the x86_64 SSE2,
AVX2, and AVX512 vector units.  There are is a single threaded and
multithreaded version of the program.

I also added a version for doing Mandelbrots using CUDA.

For more information, including timing numbers and code for parallel
computing Mandelbrots on other platforms (Playstation 2, Playstation 3,
Parallela, and Parallax Propeller) visit:

[http://www.mikekohn.net/software/mandelbrots_simd.php](http://www.mikekohn.net/software/mandelbrots_simd.php)

To test the x86_64 version, it's required to install the nasm assembler.
To build the software just type: make

Examples of running it:

./mandelbrot avx2
./mandelbrot_threaded sse 8

For all the options simply run the program with no command line arguments.

