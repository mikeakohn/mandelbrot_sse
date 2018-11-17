
BITS 64
global _mandelbrot_avx2_512
global mandelbrot_avx2_512
global _test_avx2_512
global test_avx2_512

default rel

mandel_max:
  dd 4.0, 4.0, 4.0, 4.0
  dd 4.0, 4.0, 4.0, 4.0
  dd 4.0, 4.0, 4.0, 4.0
  dd 4.0, 4.0, 4.0, 4.0

add_count:
  dd 1, 1, 1, 1
  dd 1, 1, 1, 1
  dd 1, 1, 1, 1
  dd 1, 1, 1, 1

mul_by_2:
  dd 2.0, 2.0, 2.0, 2.0
  dd 2.0, 2.0, 2.0, 2.0
  dd 2.0, 2.0, 2.0, 2.0
  dd 2.0, 2.0, 2.0, 2.0

colors:
  dd 0xff0000  ; f
  dd 0xee3300  ; e
  dd 0xcc5500  ; d
  dd 0xaa5500  ; c
  dd 0xaa3300  ; b
  dd 0x666600  ; a
  dd 0x999900  ; 9
  dd 0x669900  ; 8
  dd 0x339900  ; 7
  dd 0x0099aa  ; 6
  dd 0x0066aa  ; 5
  dd 0x0033aa  ; 4
  dd 0x0000aa  ; 3
  dd 0x000099  ; 2
  dd 0x000066  ; 1
  dd 0x000000  ; 0

; mandel_avx(rdi=[ count, count, count, count ], rsi=[ r, r, r, r, i, i, i, i ], rdx=struct _mandel_info)
; mandel_avx(rdi=picture, rsi=struct _mandel_info)
_mandelbrot_avx2_512:
mandelbrot_avx2_512:
  sub rsp, 128

  ; local variables are:
  ; [ temp, temp, temp, temp ] 0
  ; [ temp, temp, temp, temp ] 16
  ; x                          32
  ; y                          36

  ; zmm3 = [ 4.0, 4.0, 4.0, 4.0, .. 4.0 ]
  ; zmm8 = [ 2.0, 2.0, 2.0, 2.0, .. 2.0 ]
  vmovups zmm3, [mandel_max]
  vmovups zmm8, [mul_by_2]

  ; zmm14 = [ 1, 1, 1, 1, .. 1 ]
  vmovups zmm14, [add_count]

  ; rdx = int colors[]
  mov rdx, colors

  ; zmm11 = [ r_step4, r_step4, r_step4, r_step4, .. r_step4 ]
  vbroadcastss zmm11, [rsi+0]

  ; zmm13 = [ r0, r1, r2, r3, r4, .. r15 ]
  vmovups zmm13, [rsi+32]

  ; zmm12 = [ i_step, i_step, i_step, i_step ]
  vbroadcastss zmm12, [rsi+8]

  ; imaginary_start = mandel_info->imaginary_start
  ;mov eax, [rsi+16]
  ;mov [rsp+12], eax

  ; zmm1 = [ i0, i1, i2, i3, i4, .. i15 ]  imaginary_start
  vbroadcastss zmm1, [rsi+16]

  ; y = 0
  xor eax, eax
  mov [rsp+36], eax

  ; for (y = 0; y < height; y++)
for_y:

  ; zmm0 = [ r0, r1, r2, r3, r4, .. r15 ]
  vmovaps zmm0, zmm13

  ; x = 0
  xor eax, eax
  mov [rsp+32], eax

  ; for (x = 0; x < width; y++)
for_x:
  ; zmm2 = [ 1, 1, 1, 1, 1, 1, 1, 1 .. 1 ]
  vmovaps zmm2, zmm14

  ; zmm4 = zr = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 .. 0.0 ]
  ; zmm5 = zi = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 .. 0.0 ]
  ;vpsubq zmm4, zmm4, zmm4
  ;vpsubq zmm5, zmm5, zmm5
  vpxorq zmm4, zmm4, zmm4
  vpxorq zmm5, zmm5, zmm5

  ; counts
  ;vpsubq zmm10, zmm10, zmm10
  vpxorq zmm10, zmm10, zmm10

  mov ecx, 127
mandel_avx_for_loop:
  ; zmm7 = ti = (2 * zr * zi);
  vmulps zmm7, zmm4, zmm5
  vmulps zmm7, zmm7, zmm8

  ; zmm4 = tr = ((zr * zr) - (zi * zi));
  vmulps zmm4, zmm4, zmm4
  vmulps zmm5, zmm5, zmm5
  vsubps zmm4, zmm4, zmm5

  ; zmm4 = zr = tr + r;
  ; zmm5 = zi = ti + i;
  vaddps zmm4, zmm4, zmm0
  vaddps zmm5, zmm7, zmm1

  ; if ((tr * tr) + (ti * ti) > 4) break;
  vmulps zmm6, zmm4, zmm4
  vmulps zmm7, zmm5, zmm5
  vaddps zmm6, zmm6, zmm7

  ;vcmpleps zmm6, zmm6, zmm3
  vcmpps k2, zmm6, zmm3, 2

  ; count const = 0 if less than
  vpandq zmm2, zmm2, zmm6
  vpaddd zmm10, zmm10, zmm2

  ;vptest zmm6, zmm6
  vptestmd k2, zmm6, zmm6
  jz exit_mandel

  dec ecx
  jnz mandel_avx_for_loop

exit_mandel:
  vpsrld zmm10, 3
  vpslld zmm10, 2
  vmovupd [rsp+0], zmm10

  mov ecx, 64
pixel_loop:

  mov eax, [rsp+rcx]
  mov eax, [rdx+rax]
  mov [rdi], eax

  add rdi, 4
  add rdx, 4
  add ecx, 4
  cmp ecx, 128
  jnz pixel_loop

  ; map colors into picture

  ; [ r0, r1, r2, r3, r4, .. r15 ] += rstep4;
  vaddps zmm0, zmm0, zmm11

  ; next x
  mov eax, [rsp+32]
  add eax, 8
  mov [rsp+32], eax
  cmp eax, [rsi+20]
  jl for_x

  ; [ i0, i1, i2, i3, i4, .. i15 ] += istep;
  vaddps zmm1, zmm1, zmm12

  ; next y
  mov eax, [rsp+36]
  inc eax
  mov [rsp+36], eax
  cmp eax, [rsi+24]
  jl for_y

  add rsp, 128
  ret

_test_avx2_512:
test_avx2_512:
  ;mov dword [rdi], 1
  ;mov dword [rdi+4], 1
  ;mov dword [rdi+8], 1
  ;mov dword [rdi+12], 1
  ;mov dword [rdi+16], 1
  ;mov dword [rdi+20], 1
  ;mov dword [rdi+24], 1
  ;mov dword [rdi+28], 1
  vmovups zmm14, [rdi]
  vpackssdw zmm14, zmm14
  vpacksswb zmm14, zmm14
  vmovups [rdi], zmm14
  ret

