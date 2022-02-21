
PROGRAM=cluster
INCLUDE=../../../naken_asm/include/msp430
JAVA_GRINDER=../../../java_grinder/java_grinder
NAKEN_ASM=../../../naken_asm/naken_asm

default:
	$(NAKEN_ASM) -l -o $(PROGRAM).hex -I$(INCLUDE) $(PROGRAM).asm

mandel: Mandelbrot.class
	$(JAVA_GRINDER) -v Mandelbrot.class mandelbrot.asm msp430g2231
	python3 modify_mandel.py
	$(NAKEN_ASM) -I $(INCLUDE) -l -type bin -o mandelbrot.bin mandelbrot.asm

%.class: %.java
	javac -classpath ../../../java_grinder/build/JavaGrinder.jar:. $*.java

clean:
	@rm -f *.hex *.lst *.class mandelbrot.asm mandelbrot.bin
	@rm -rf __pycache__
	@echo "Clean!"

