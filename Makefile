
default:
	@+make -C build

mac:
	@+make -C build mac

clean:
	@rm -f mandelbrot mandelbrot_threaded mandelbrot_cuda build/*.o
	@echo "Clean!"

