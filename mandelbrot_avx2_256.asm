
BITS 64
global _mandelbrot_avx2_256
global mandelbrot_avx2_256
global _test_avx2_256
global test_avx2_256

default rel

mandel_max:
  dd 4.0, 4.0, 4.0, 4.0
  dd 4.0, 4.0, 4.0, 4.0

add_count:
  dd 1, 1, 1, 1
  dd 1, 1, 1, 1

mul_by_2:
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
_mandelbrot_avx2_256:
mandelbrot_avx2_256:
  sub rsp, 64

  ; local variables are:
  ; [ temp, temp, temp, temp ] 0
  ; [ temp, temp, temp, temp ] 16
  ; x                          32
  ; y                          36

  ; ymm3 = [ 4.0, 4.0, 4.0, 4.0 ]
  ; ymm8 = [ 2.0, 2.0, 2.0, 2.0 ]
  vmovups ymm3, [mandel_max]
  vmovups ymm8, [mul_by_2]

  ; ymm14 = [ 1, 1, 1, 1, 1, 1, 1, 1 ]
  vmovups ymm14, [add_count]

  ; rdx = int colors[]
  mov rdx, colors

  ; ymm11 = [ r_step4, r_step4, r_step4, r_step4, r_step4, r_step4, r_step4, . ]
  vbroadcastss ymm11, [rsi+0]

  ; ymm13 = [ r0, r1, r2, r3, r4, r5, r6, r7 ]
  vmovups ymm13, [rsi+32]

  ; ymm12 = [ i_step, i_step, i_step, i_step ]
  vbroadcastss ymm12, [rsi+8]

  ; imaginary_start = mandel_info->imaginary_start
  ;mov eax, [rsi+16]
  ;mov [rsp+12], eax

  ; ymm1 = [ i0, i1, i2, i3, i4, i5, i6, i7 ]  imaginary_start
  vbroadcastss ymm1, [rsi+16]

  ; y = 0
  xor eax, eax
  mov [rsp+36], eax

  ; for (y = 0; y < height; y++)
for_y:

  ; ymm0 = [ r0, r1, r2, r3, r4, r5, r6, r7 ]
  vmovaps ymm0, ymm13

  ; x = 0
  xor eax, eax
  mov [rsp+32], eax

  ; for (x = 0; x < width; y++)
for_x:
  ; ymm2 = [ 1, 1, 1, 1, 1, 1, 1, 1 ]
  vmovaps ymm2, ymm14

  ; ymm4 = zr = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
  ; ymm5 = zi = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
  vpxor ymm4, ymm4, ymm4
  vpxor ymm5, ymm5, ymm5

  ; counts
  vpxor ymm10, ymm10, ymm10

  mov ecx, 127
mandel_avx_for_loop:
  ; ymm7 = ti = (2 * zr * zi);
  vmulps ymm7, ymm4, ymm5
  vmulps ymm7, ymm7, ymm8

  ; ymm4 = tr = ((zr * zr) - (zi * zi));
  vmulps ymm4, ymm4, ymm4
  vmulps ymm5, ymm5, ymm5
  vsubps ymm4, ymm4, ymm5

  ; ymm4 = zr = tr + r;
  ; ymm5 = zi = ti + i;
  vaddps ymm4, ymm4, ymm0
  vaddps ymm5, ymm7, ymm1

  ; if ((tr * tr) + (ti * ti) > 4) break;
  vmulps ymm6, ymm4, ymm4
  vmulps ymm7, ymm5, ymm5
  vaddps ymm6, ymm6, ymm7

  vcmpleps ymm6, ymm6, ymm3

  ; count const = 0 if less than
  vpand ymm2, ymm2, ymm6
  vpaddd ymm10, ymm10, ymm2

  vptest ymm6, ymm6
  jz exit_mandel

  dec ecx
  jnz mandel_avx_for_loop

exit_mandel:
  vpsrld ymm10, 3
  vpslld ymm10, 2
  vmovupd [rsp+0], ymm10

  ; map colors into picture
  mov eax, [rsp+0]
  mov eax, [rdx+rax]
  mov [rdi], eax

  mov eax, [rsp+4]
  mov eax, [rdx+rax]
  mov [rdi+4], eax

  mov eax, [rsp+8]
  mov eax, [rdx+rax]
  mov [rdi+8], eax

  mov eax, [rsp+12]
  mov eax, [rdx+rax]
  mov [rdi+12], eax

  mov eax, [rsp+16]
  mov eax, [rdx+rax]
  mov [rdi+16], eax

  mov eax, [rsp+20]
  mov eax, [rdx+rax]
  mov [rdi+20], eax

  mov eax, [rsp+24]
  mov eax, [rdx+rax]
  mov [rdi+24], eax

  mov eax, [rsp+28]
  mov eax, [rdx+rax]
  mov [rdi+28], eax

  ; picture += 8
  add rdi, 32

  ; [ r0, r1, r2, r3, r4, r5, r6, r7 ] += rstep4;
  vaddps ymm0, ymm0, ymm11

  ; next x
  mov eax, [rsp+32]
  add eax, 8
  mov [rsp+32], eax
  cmp eax, [rsi+20]
  jl for_x

  ; [ i0, i1, i2, i3, i4, i5, i6, i7 ] += istep;
  vaddps ymm1, ymm1, ymm12

  ; next y
  mov eax, [rsp+36]
  inc eax
  mov [rsp+36], eax
  cmp eax, [rsi+24]
  jl for_y

  add rsp, 64
  ret

_test_avx2_256:
test_avx2_256:
  ;mov dword [rdi], 1
  ;mov dword [rdi+4], 1
  ;mov dword [rdi+8], 1
  ;mov dword [rdi+12], 1
  ;mov dword [rdi+16], 1
  ;mov dword [rdi+20], 1
  ;mov dword [rdi+24], 1
  ;mov dword [rdi+28], 1
  vmovups ymm14, [rdi]
  vpackssdw ymm14, ymm14
  vpacksswb ymm14, ymm14
  vmovups [rdi], ymm14
  ret

