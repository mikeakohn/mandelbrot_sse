#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

#define WIDTH 1024
#define HEIGHT 768
#define CORE_COUNT 128

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

struct MandelInfo
{
  float r_step;
  float i_step;
  float real_start;
  float imaginary_start;
  int width;
  int height;
};

struct CoreInfo
{
  MandelInfo mandel_info;
  int *picture;
  uint8_t signal_start;
  uint8_t signal_done;
  int core_id;
};

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
  int x, y;
  float r, i, r_step, i_step;
  float tr, ti, zr, zi;
  int ptr, count;

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

      ptr++;
      r = r + r_step;
    }

    i = i + i_step;
  }

  return 0;
}

__global__
void mandel_calc_cuda_single(
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
  float r, i, r_step, i_step;
  float tr, ti, zr, zi;
  int ptr, count;

  int colors[] =
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

      ptr++;
      r = r + r_step;
    }

    i = i + i_step;
  }
}

__global__
void mandel_calc_cuda_multi(
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
  float r, i, r_step, i_step;
  float tr, ti, zr, zi;
  int ptr, count;

  int index = threadIdx.x;
  //int stride = blockDim.x;

//printf("index=%d stride=%d\n", index, stride);

  int colors[] =
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

  r_step = (real_end - real_start) / (float)width;
  i_step = (imaginary_end - imaginary_start) / (float)height;

//printf("step = %f %f\n", r_step, i_step);

  height = height / CORE_COUNT;

  y = index * height;

  ptr = y * width;

  i = imaginary_start + (i_step * y);
#if 0
  i = imaginary_start;

  for (y = 0; y < index * height; y++)
  {
    i = i + i_step;
  }
#endif

//printf("ptr=%d index=%d height=%d %f\n", ptr, index, height, i);

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

      ptr++;
      r = r + r_step;
    }

    i = i + i_step;
  }
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
  int *picture;

  float real_start = 0.37 - 0.00;
  float real_end = 0.37 + 0.04;
  float imaginary_start = -0.2166 - 0.02;
  float imaginary_end = -0.2166 + 0.02;

  int do_cuda = 0;

  if (argc != 2)
  {
    printf("Usage: %s <normal/cuda/cuda128>\n", argv[0]);
    exit(0);
  }

  if (strcmp(argv[1], "normal") == 0)
  {
    do_cuda = 0;
  }
    else
  if (strcmp(argv[1], "cuda") == 0)
  {
    do_cuda = 1;
  }
    else
  if (strcmp(argv[1], "cuda128") == 0)
  {
    do_cuda = 2;
  }

  const int length = WIDTH * HEIGHT * sizeof(int);

  switch (do_cuda)
  {
    case 0:
      picture = (int *)malloc(length);
      break;
    case 1:
    case 2:
      cudaMallocManaged(&picture, length);
      break;
  }

  gettimeofday(&tv_start, NULL);

  if (do_cuda == 1)
  {
    mandel_calc_cuda_single<<<1,1>>>(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);

    cudaDeviceSynchronize();
  }
    else
  if (do_cuda == 2)
  {
    mandel_calc_cuda_multi<<<1,128>>>(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);

    cudaDeviceSynchronize();
  }
    else
  {
    mandel_calc(picture, WIDTH, HEIGHT, real_start, real_end, imaginary_start, imaginary_end);
  }

  gettimeofday(&tv_end, NULL);

  printf("%ld %ld\n", tv_end.tv_sec, tv_end.tv_usec);
  printf("%ld %ld\n", tv_start.tv_sec, tv_start.tv_usec);
  long time_diff = tv_end.tv_usec - tv_start.tv_usec;
  while(time_diff < 0) { tv_end.tv_sec--; time_diff += 1000000; }
  time_diff += (tv_end.tv_sec - tv_start.tv_sec) * 1000000;
  printf("time=%f\n", (float)time_diff / 1000000);

  switch (do_cuda)
  {
    case 0:
    {
      write_bmp(picture, WIDTH, HEIGHT);
      free(picture);
      break;
    }
    case 1:
    case 2:
    {
      int *image = (int *)malloc(length);
      cudaMemcpy(image, picture, length, cudaMemcpyDeviceToHost);
      write_bmp(image, WIDTH, HEIGHT);
      cudaFree(picture);
      break;
    }
  }

  return 0;
}

