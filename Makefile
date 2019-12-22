
default:
	nasm -f elf64 mandelbrot_sse.asm
	nasm -f elf64 mandelbrot_avx2.asm
	nasm -f elf64 mandelbrot_avx_512.asm
	$(CC) -o mandelbrot mandelbrot.c \
	  mandelbrot_sse.o \
	  mandelbrot_avx2.o \
	  mandelbrot_avx_512.o \
	  -O3 -Wall -g
	$(CC) -o mandelbrot_threaded mandelbrot_threaded.c \
	  mandelbrot_sse.o \
	  mandelbrot_avx2.o \
	  mandelbrot_avx_512.o \
	  -lpthread -O3 -Wall -g

mac:
	nasm -f macho64 mandelbrot_sse.asm
	nasm -f macho64 mandelbrot_avx2.asm
	nasm -f macho64 mandelbrot_avx_512.asm
	$(CC) -o mandelbrot mandelbrot.c \
	  mandelbrot_sse.o \
	  mandelbrot_avx2.o \
	  mandelbrot_avx_512.o \
	  -O3 -Wall -g -m64 -Wl,-no_pie

clean:
	@rm -f mandelbrot *.o
	@echo "Clean!"

