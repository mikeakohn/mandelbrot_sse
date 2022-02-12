#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>

#define WIDTH 1024
#define HEIGHT 768

static int colors[] =
{
  0xff0000,  // f
  0xee3300,  // e
  0xcc5500,  // d
  0xaa5500,  // c
  0xaa3300,  // b
  0x666600,  // a
  0x999900,  // 9
  0x669900,  // 8
  0x339900,  // 7
  0x0099aa,  // 6
  0x0066aa,  // 5
  0x0033aa,  // 4
  0x0000aa,  // 3
  0x000099,  // 2
  0x000066,  // 1
  0x000000,  // 0
};

struct _mandel_info
{
  float r_step4;         // 0
  float r_step;          // 4
  float i_step;          // 8
  float real_start;      // 12
  float imaginary_start; // 16
  int width;             // 20
  int height;            // 24
  int reserved;
  float real_start4[16]; // 32
};

void mandelbrot_sse(int *picture, struct _mandel_info *mandel_info);
void mandelbrot_avx2(int *picture, struct _mandel_info *mandel_info);
void mandelbrot_avx_512(int *picture, struct _mandel_info *mandel_info);
//void test_sse(uint32_t *vector);
//void test_avx2(uint32_t *vector);
//void test_avx_512(uint32_t *vector);

int mandel_calc_sse(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end)
{
  struct _mandel_info mandel_info;

  mandel_info.r_step4 = (real_end - real_start) * 4 / (float)width;
  mandel_info.r_step = (real_end - real_start) / (float)width;
  mandel_info.i_step = (imaginary_end - imaginary_start) / (float)height;
  mandel_info.real_start = real_start;
  mandel_info.imaginary_start = imaginary_start;
  mandel_info.width = width;
  mandel_info.height = height;
  mandel_info.real_start4[0] = real_start;
  mandel_info.real_start4[1] = mandel_info.real_start4[0] + mandel_info.r_step;
  mandel_info.real_start4[2] = mandel_info.real_start4[1] + mandel_info.r_step;
  mandel_info.real_start4[3] = mandel_info.real_start4[2] + mandel_info.r_step;

  mandelbrot_sse(picture, &mandel_info);

  return 0;
}

int mandel_calc_avx2(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end)
{
  struct _mandel_info mandel_info;
  int n;

  mandel_info.r_step4 = (real_end - real_start) * 8 / (float)width;
  mandel_info.r_step = (real_end - real_start) / (float)width;
  mandel_info.i_step = (imaginary_end - imaginary_start) / (float)height;
  mandel_info.real_start = real_start;
  mandel_info.imaginary_start = imaginary_start;
  mandel_info.width = width;
  mandel_info.height = height;
  mandel_info.real_start4[0] = real_start;

  for (n = 1; n < 8; n++)
  {
    mandel_info.real_start4[n] = mandel_info.real_start4[n - 1] + mandel_info.r_step;
  }

  mandelbrot_avx2(picture, &mandel_info);

  return 0;
}

int mandel_calc_avx_512(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end)
{
  struct _mandel_info mandel_info;
  int n;

  mandel_info.r_step4 = (real_end - real_start) * 16 / (float)width;
  mandel_info.r_step = (real_end - real_start) / (float)width;
  mandel_info.i_step = (imaginary_end - imaginary_start) / (float)height;
  mandel_info.real_start = real_start;
  mandel_info.imaginary_start = imaginary_start;
  mandel_info.width = width;
  mandel_info.height = height;
  mandel_info.real_start4[0] = real_start;

  for (n = 1; n < 16; n++)
  {
    mandel_info.real_start4[n] = mandel_info.real_start4[n - 1] + mandel_info.r_step;
  }

  mandelbrot_avx_512(picture, &mandel_info);

  return 0;
}

int mandel_calc(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end)
{
  const int max_count = 127;
  int x,y;
  float r,i,r_step,i_step;
  float tr,ti,zr,zi;
  int ptr,count;

  r_step = (real_end - real_start) / (float)width;
  i_step = (imaginary_end - imaginary_start) / (float)height;
  ptr = 0;

  //printf("step = %f %f\n", r_step, i_step);

  i = imaginary_start;

  for (y = 0; y < height; y++)
  {
    r = real_start;

    for (x = 0; x < width; x++)
    {
      zr = 0;
      zi = 0;

      for (count = 0; count < max_count; count++)
      {
        tr = ((zr * zr) - (zi * zi));
        ti = (2 * zr * zi);
        zr = tr + r;
        zi = ti + i;
        if ((zr * zr) + (zi * zi) > 4) break;
      }

      picture[ptr] = colors[count >> 3];
      //picture[ptr] = count;

      ptr++;
      r = r + r_step;
    }

    i = i + i_step;
  }

  return 0;
}

int write_int32(FILE *out, int n)
{
  putc((n & 0xff), out);
  putc(((n >> 8) & 0xff), out);
  putc(((n >> 16) & 0xff), out);
  putc(((n >> 24) & 0xff), out);

  return 0;
}

int write_int16(FILE *out, int n)
{
  putc((n & 0xff), out);
  putc(((n >> 8) & 0xff), out);

  return 0;
}

void write_bmp(int *picture, int width, int height)
{
  FILE *out;
  int bmp_width;
  int bmp_size;
  int padding;
  int offset;
  int color;
  int x,y;

  out = fopen("out.bmp", "wb");
  if (out == NULL)
  {
    printf("Can't open file for writing.");
    return;
  }

  bmp_width = width * 3;
  bmp_width = (bmp_width + 3) & (~0x3);
  bmp_size = (bmp_width * height) + 14 + 40;
  padding = bmp_width - (width * 3);

  //printf("width=%d (%d)\n", width, width*3);
  //printf("bmp_width=%d\n", bmp_width);
  //printf("bmp_size=%d\n", bmp_size);

  /* size: 14 bytes */

  putc('B', out);
  putc('M', out);
  write_int32(out, bmp_size);
  write_int16(out, 0);
  write_int16(out, 0);
  write_int32(out, 54);

  /* head1: 14  head2: 40 */

  write_int32(out, 40);         /* biSize */
  write_int32(out, width);
  write_int32(out, height);
  write_int16(out, 1);
  write_int16(out, 24);
  write_int32(out, 0);          /* compression */
  write_int32(out, bmp_width*height);
  write_int32(out, 0);          /* biXPelsperMetre */
  write_int32(out, 0);          /* biYPelsperMetre */
  write_int32(out, 0);
  write_int32(out, 0);

  for (y = 0; y < height; y++)
  {
    offset = y * width;

    for (x = 0; x < width; x++)
    {
      color = picture[offset++];

      putc(color & 0xff, out);
      putc((color >> 8) & 0xff, out);
      putc((color >> 16) & 0xff, out);
    }
    for (x = 0; x < padding; x++) { putc(0, out); }
  }

  fclose(out);
}

int main(int argc, char *argv[])
{
  struct timeval tv_start, tv_end;
  int picture[WIDTH * HEIGHT];
#if 0
  float real_start = -0.1592 - 0.01;
  float real_end = -0.1592 + 0.01;
  float imaginary_start = -1.0317 - 0.01;
  float imaginary_end = -1.0317 + 0.01;
#endif

  float real_start = 0.37 - 0.00;
  float real_end = 0.37 + 0.04;
  float imaginary_start = -0.2166 - 0.02;
  float imaginary_end = -0.2166 + 0.02;

#if 0
  float real_start = -2.00;
  float real_end = 1.00;
  float imaginary_start = -1.00;
  float imaginary_end = 1.00;
#endif

  int do_simd = 1;

  if (argc != 2)
  {
    printf("Usage: %s <normal/sse/avx2/avx_512>\n", argv[0]);
    exit(0);
  }

  if (strcmp(argv[1], "normal") == 0) { do_simd = 0; }
  else if (strcmp(argv[1], "sse") == 0) { do_simd = 1; }
  else if (strcmp(argv[1], "avx2") == 0) { do_simd = 2; }
  else if (strcmp(argv[1], "avx_512") == 0) { do_simd = 3; }

  gettimeofday(&tv_start, NULL);

  if (do_simd == 1)
  {
    mandel_calc_sse(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);
  }
    else
  if (do_simd == 2)
  {
    mandel_calc_avx2(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);
  }
    else
  if (do_simd == 3)
  {
    mandel_calc_avx_512(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);
  }
    else
  {
    mandel_calc(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);
  }

  gettimeofday(&tv_end, NULL);

#if 0
  int picture2[WIDTH * HEIGHT];
  mandel_calc(picture2, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);

  int n;
  for (n = 0; n < WIDTH * HEIGHT; n++)
  {
    if (picture[n] != picture2[n])
    {
      printf("error %d  %8x %8x\n", n, picture[n], picture2[n]);
    }
  }
#endif

  printf("%ld %ld\n", tv_end.tv_sec, tv_end.tv_usec);
  printf("%ld %ld\n", tv_start.tv_sec, tv_start.tv_usec);
  long time_diff = tv_end.tv_usec - tv_start.tv_usec;
  while(time_diff < 0) { tv_end.tv_sec--; time_diff += 1000000; }
  time_diff += (tv_end.tv_sec - tv_start.tv_sec) * 1000000;
  printf("time=%f\n", (float)time_diff / 1000000);

  write_bmp(picture, WIDTH, HEIGHT);

  return 0;
}

