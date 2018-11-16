
default:
	nasm -f elf64 render_mandelbrot_sse.asm
	nasm -f elf64 render_mandelbrot_avx.asm
	$(CC) -o mandelbrot_sse mandelbrot_sse.c \
	  render_mandelbrot_sse.o \
	  render_mandelbrot_avx.o \
	  -O3 -Wall -g

mac:
	nasm -f macho64 render_mandelbrot_sse.asm
	nasm -f macho64 render_mandelbrot_avx.asm
	$(CC) -o mandelbrot_sse mandelbrot_sse.c \
	  render_mandelbrot_sse.o \
	  render_mandelbrot_avx.o \
	  -O3 -Wall -g -m64 -Wl,-no_pie

clean:
	@rm -f mandelbrot_sse *.o
	@echo "Clean!"

