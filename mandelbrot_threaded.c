#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <pthread.h>
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

struct _thread_info
{
  struct _mandel_info mandel_info;
  int *picture;
  //float real_start;
  //float imaginary_start;
  uint8_t signal_start;
  uint8_t signal_done;
  pthread_t pid;
};

void mandelbrot_sse(int *picture, volatile struct _mandel_info *mandel_info);
void mandelbrot_avx2(int *picture, struct _mandel_info *mandel_info);
void mandelbrot_avx_512(int *picture, struct _mandel_info *mandel_info);
//void test_sse(uint32_t *vector);
//void test_avx2(uint32_t *vector);
//void test_avx_512(uint32_t *vector);

void *thread_sse(void *context)
{
  volatile struct _thread_info *thread_info = (struct _thread_info *)context;

  while (thread_info->signal_done == 0)
  {
    if (thread_info->signal_start == 1)
    {
      mandelbrot_sse(thread_info->picture, &thread_info->mandel_info);

      thread_info->signal_start = 0;
    }
  }

  return NULL;
}

int mandel_calc_avx2(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end,
  int threads)
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
  float imaginary_end,
  int threads)
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

void mandel_normal(
  int *picture,
  volatile struct _mandel_info *mandel_info)
{
  const int max_count = 127;
  int x, y;
  float r, i;
  float tr, ti, zr, zi;
  int ptr, count;

  ptr = 0;

  i = mandel_info->imaginary_start;

  for (y = 0; y < mandel_info->height; y++)
  {
    r = mandel_info->real_start;

    for (x = 0; x < mandel_info->width; x++)
    {
      zr = 0;
      zi = 0;

      for (count = 0; count < max_count; count++)
      {
        tr = ((zr * zr) - (zi * zi));
        ti = (2 * zr * zi);
        zr = tr + r;
        zi = ti + i;
        if ((zr * zr) + (zi * zi) > 4) { break; }
      }

      picture[ptr] = colors[count >> 3];

      ptr++;
      r = r + mandel_info->r_step;
    }

    i = i + mandel_info->i_step;
  }
}

void *thread_normal(void *context)
{
  volatile struct _thread_info *thread_info = (struct _thread_info *)context;

  while (thread_info->signal_done == 0)
  {
    if (thread_info->signal_start == 1)
    {
      mandel_normal(thread_info->picture, &thread_info->mandel_info);

      thread_info->signal_start = 0;
    }
  }

  return NULL;
}

int mandel_calc_normal(
  int *picture,
  int width,
  int height,
  float real_start,
  float real_end,
  float imaginary_start,
  float imaginary_end,
  int threads,
  int do_simd)
{
  struct _mandel_info mandel_info;
  struct _thread_info thread_info[threads];
  int n, y;

  mandel_info.r_step4 = (real_end - real_start) * 4 / (float)width;
  mandel_info.r_step = (real_end - real_start) / (float)width;
  mandel_info.i_step = (imaginary_end - imaginary_start) / (float)height;
  mandel_info.real_start = real_start;
  mandel_info.imaginary_start = imaginary_start;
  mandel_info.width = width;
  //mandel_info.height = height;
  mandel_info.height = 1;
  mandel_info.real_start4[0] = real_start;
  mandel_info.real_start4[1] = mandel_info.real_start4[0] + mandel_info.r_step;
  mandel_info.real_start4[2] = mandel_info.real_start4[1] + mandel_info.r_step;
  mandel_info.real_start4[3] = mandel_info.real_start4[2] + mandel_info.r_step;

  memset(thread_info, 0, sizeof(thread_info));

  for (n = 0; n < threads; n++)
  {
    memcpy(&thread_info[n].mandel_info, &mandel_info, sizeof(mandel_info));

    switch (do_simd)
    {
      case 0:
        pthread_create(&thread_info[n].pid, NULL, thread_normal, &thread_info[n]);
        break;
      case 1:
        pthread_create(&thread_info[n].pid, NULL, thread_sse, &thread_info[n]);
        break;
    }
  }

  y = 0;

  while (y < height)
  {
    for (n = 0; n < threads; n++)
    {
      if (thread_info[n].signal_start == 0)
      {
        thread_info[n].picture = picture;
        thread_info[n].mandel_info.imaginary_start =
           mandel_info.imaginary_start;
        thread_info[n].signal_start = 1;

        mandel_info.imaginary_start += mandel_info.i_step;
        picture += width;

        y++;
      }
    }
  }

  for (n = 0; n < threads; n++)
  {
    thread_info[n].signal_done = 1;
  }

  for (n = 0; n < threads; n++)
  {
    pthread_join(thread_info[n].pid, NULL);
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
  float real_start = 0.37 - 0.00;
  float real_end = 0.37 + 0.04;
  float imaginary_start = -0.2166 - 0.02;
  float imaginary_end = -0.2166 + 0.02;

  int do_simd = 1;

  if (argc != 3)
  {
    printf("Usage: %s <normal/sse/avx2/avx_512> <threads>\n", argv[0]);
    exit(0);
  }

  if (strcmp(argv[1], "normal") == 0) { do_simd = 0; }
  else if (strcmp(argv[1], "sse") == 0) { do_simd = 1; }
  else if (strcmp(argv[1], "avx2") == 0) { do_simd = 2; }
  else if (strcmp(argv[1], "avx_512") == 0) { do_simd = 3; }

  int threads = atoi(argv[2]);

  printf("Threads: %d\n", threads);

  if (threads <= 0)
  {
    printf("Illegal number of threads\n");
    exit(1);
  }

  gettimeofday(&tv_start, NULL);

#if 0
  if (do_simd == 1)
  {
    mandel_calc_sse(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end, threads);
  }
    else
  if (do_simd == 2)
  {
    mandel_calc_avx2(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end, threads);
  }
    else
  if (do_simd == 3)
  {
    mandel_calc_avx_512(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end, threads);
  }
    else
  {
    mandel_calc_normal(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end, threads);
  }
#endif

  mandel_calc_normal(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end, threads, do_simd);

  gettimeofday(&tv_end, NULL);

  printf("%ld %ld\n", tv_end.tv_sec, tv_end.tv_usec);
  printf("%ld %ld\n", tv_start.tv_sec, tv_start.tv_usec);
  long time_diff = tv_end.tv_usec - tv_start.tv_usec;
  while(time_diff < 0) { tv_end.tv_sec--; time_diff += 1000000; }
  time_diff += (tv_end.tv_sec - tv_start.tv_sec) * 1000000;
  printf("time=%f\n", (float)time_diff / 1000000);

  write_bmp(picture, WIDTH, HEIGHT);

  return 0;
}

