
BITS 64
global render_mandelbrot_avx
global test_avx

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

; mandel_sse(rdi=[ count, count, count, count ], rsi=[ r, r, r, r, i, i, i, i ], rdx=struct _mandel_info)
; mandel_sse(rdi=picture, rsi=struct _mandel_info)
render_mandelbrot_avx:
  sub rsp, 64 

  ; local variables are:
  ; [ r, r, r, r ] 0
  ; [ i, i, i, i ] 16
  ; x              32
  ; y              36 
  ;
  ;
  ; [ temp, temp, temp, temp] 48

  ; ymm3 = [ 4.0, 4.0, 4.0, 4.0 ]
  ; ymm8 = [ 2.0, 2.0, 2.0, 2.0 ]
  vmovups ymm3, [mandel_max]
  vmovups ymm8, [mul_by_2]

  ; ymm14 = [ 1, 1, 1, 1 ]
  vmovups ymm14, [add_count]

  ; rdx = int colors[]
  mov rdx, colors

  ; ymm11 = [ r_step4, r_step4, r_step4, r_step4 ]
  ;mov eax, [rsi+0]
  ;mov [rsp+16], eax
  ;mov [rsp+20], eax
  ;mov [rsp+24], eax
  ;mov [rsp+28], eax
  ;movups xmm11, [rsp+16]
  vbroadcastss ymm11, [rsi+0]

  ; ymm13 = [ r0, r1, r2, r3, r4, r5, r6, r7 ]
  vmovups ymm13, [rsi+32]

  ; ymm12 = [ i_step, i_step, i_step, i_step ]
  ;mov eax, [rsi+8]
  ;mov [rsp+16], eax
  ;mov [rsp+20], eax
  ;mov [rsp+24], eax
  ;mov [rsp+28], eax
  ;movups xmm12, [rsp+16]
  vbroadcastss ymm12, [rsi+8]

  ; imaginary_start = mandel_info->imaginary_start
  ;mov eax, [rsi+16]
  ;mov [rsp+12], eax

  ; xmm1 = [ i0, i1, i2, i3, i4, i5, i6, i7 ]  imaginary_start
  ;mov eax, [rsi+16]
  ;mov [rsp+16], eax
  ;mov [rsp+20], eax
  ;mov [rsp+24], eax
  ;mov [rsp+28], eax
  ;movups xmm1, [rsp+16]
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
  ; ymm2 = [ 1, 1, 1, 1 ]
  vmovaps ymm2, ymm14

  ; ymm4 = zr = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
  ; ymm5 = zi = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
  vpxor ymm4, ymm4, ymm4
  vpxor ymm5, ymm5, ymm5
  ;vsubpd ymm4, ymm4, ymm4
  ;vsubpd ymm5, ymm5, ymm5

  ; counts
  vpxor ymm10, ymm10, ymm10
  ;vsubpd ymm10, ymm10, ymm10

  mov ecx, 127
mandel_sse_for_loop:
  ; xmm7 = ti = (2 * zr * zi);
  vmovapd ymm7, ymm4
  vmulps ymm7, ymm7, ymm5
  vmulps ymm7, ymm7, ymm8

  ; xmm4 = tr = ((zr * zr) - (zi * zi));
  vmulps ymm4, ymm4, ymm4
  vmulps ymm5, ymm5, ymm5
  vsubps ymm4, ymm4, ymm5

  ; xmm4 = zr = tr + r;
  ; xmm5 = zi = ti + i;
  vmovapd ymm5, ymm7
  vaddps ymm4, ymm4, ymm0 
  vaddps ymm5, ymm5, ymm1 

  ; if ((tr * tr) + (ti * ti) > 4) break;
  vmovapd ymm6, ymm4
  vmovapd ymm7, ymm5
  vmulps ymm6, ymm6, ymm6
  vmulps ymm7, ymm7, ymm7
  vaddps ymm6, ymm6, ymm7
  vcmpleps ymm6, ymm6, ymm3

  ; count const = 0 if less than
  vpand ymm2, ymm2, ymm6
  vpaddd ymm10, ymm10, ymm2

  vptest ymm6, ymm6
  jz exit_mandel

  dec ecx
  jnz mandel_sse_for_loop

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
  vaddps xmm0, xmm11

  ; next x
  mov eax, [rsp+32]
  add eax, 8
  mov [rsp+32], eax
  cmp eax, [rsi+20]
  jl for_x

  ; [ i0, i1, i2, i3, i4, i5, i6, i7 ] += istep;
  vaddps xmm1, xmm12

  ; next y
  mov eax, [rsp+36]
  inc eax
  mov [rsp+36], eax
  cmp eax, [rsi+24]
  jl for_y

  add rsp, 64 
  ret

test_avx:
  mov dword [rdi], 1
  mov dword [rdi+4], 1
  mov dword [rdi+8], 1
  mov dword [rdi+12], 1
  movups xmm14, [rdi]
  packssdw xmm14, xmm14
  packsswb xmm14, xmm14
  movups [rdi], xmm14
  ret

