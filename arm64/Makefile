
default:
	../../naken_asm/naken_asm -l -type elf -o mandelbrot_simd.o mandelbrot_simd.asm
	gcc -o mandelbrot mandelbrot.c mandelbrot_simd.o -Wall -O3

clean:
	rm -f mandelbrot *.o
	@echo "Clean!"

