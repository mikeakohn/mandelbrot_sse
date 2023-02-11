CFLAGS=-Wall -O3
VPATH=../x86:../cuda

ifeq ($(shell uname), 'Darwin')
  EXETYPE:=macho64
else
  EXETYPE:=elf64
endif

OBJECTS= \
  mandelbrot_sse.o \
  mandelbrot_avx2.o \
  mandelbrot_avx_512.o

default: $(OBJECTS)
	$(CC) -o ../mandelbrot ../x86/mandelbrot.c \
          $(OBJECTS) \
	  $(CFLAGS) -z noexecstack -no-pie
	$(CC) -o ../mandelbrot_threaded ../x86/mandelbrot_threaded.c \
          $(OBJECTS) \
	  -lpthread $(CFLAGS) -z noexecstack -no-pie

mac: $(OBJECTS)
	$(CC) -o ../x86/mandelbrot ../x86/mandelbrot.c \
          $(OBJECTS) \
	  -O3 -Wall -g -m64

noasm:
	$(CC) -o ../x86/mandelbrot ../x86/mandelbrot.c \
	  -O3 -Wall -g -m64 -DNOASM

cuda:
	nvcc -o ../mandelbrot_cuda ../cuda/mandelbrot_cuda.cu -g -O3

%.o: %.asm
	nasm -f $(EXETYPE) -o $*.o $<

