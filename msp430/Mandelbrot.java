
import net.mikekohn.java_grinder.CPU;

public class Mandelbrot
{
  public static int calculate(int r, int i)
  {
    int count;
    int zr = 0, zi = 0;

    for (count = 0; count < 127; count++)
    {
      int zr2 = square(zr);
      int zi2 = square(zi);

      if (zr2 + zi2 > (4 << 12)) { break; }

      int tr = zr2 - zi2;
      int ti = multiply(zr, zi) << 1;

      zr = tr + r;
      zi = ti + i;
    }

    return count;
  }

  public static int square(int a)
  {
    if (a < 0) { a = -a; }

    int b = a;

    return umul16(a, b);
  }

  public static int multiply(int a, int b)
  {
    int negative = 0;

    if (a < 0)
    {
      a = -a;
      negative++;
    }

    if (b < 0)
    {
      b = -b;
      negative++;
    }

    int c = umul16(a, b);

    if ((negative & 1) != 0) { c = -c; }

    return c;
  }

  public static int umul16(int a, int b)
  {
    // r15:14 = r5:r4 * r6
    // r15:14 = xxxx rrrr rrrr rrrr | rrrr xxxx xxxx xxxx

    CPU.asm(
      "  ;; inline assembly:\n" +
      "  mov.w -2(r12), r4  ; push local_0\n" +
      "  mov.w #0, r5\n" +
      "  mov.w -4(r12), r6  ; push local_1\n" +
      "  mov.w #0, r14\n" +
      "  mov.w #0, r15\n" +
      "_multiply_loop:\n" +
      "  bit.w #1, r6\n" +
      "  jz _multiply_skip_add\n" +
      "  add.w r4, r14\n" +
      "  addc.w r5, r15\n" +
      "_multiply_skip_add:\n" +
      "  rla.w r4\n" +
      "  rlc.w r5\n" +
      "  clrc\n" +
      "  rrc.w r6\n" +
      //"  cmp.w #0, r6\n" +
      "  jnz _multiply_loop\n" +
      "  ;; shift result by 12\n" +
      "  rla.w r14\n" +
      "  rlc.w r15\n" +
      "  rla.w r14\n" +
      "  rlc.w r15\n" +
      "  rla.w r14\n" +
      "  rlc.w r15\n" +
      "  rla.w r14\n" +
      "  rlc.w r15\n" +
      "  mov.w r15, -2(r12)\n" +
      "\n");

    return a;
  }

  public static void main(String[] args)
  {
    int a = 0x69;
    int num_1 = 1;
    int num_2 = 2;
    int b = 0x69;
    int c;

    c = calculate(num_1, num_2);

    while (true) { }
  }
}

