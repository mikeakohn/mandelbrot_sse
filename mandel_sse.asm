
BITS 64
global mandel_sse
global test_sse

mandel_max:
  dd 4.0, 4.0, 4.0, 4.0

add_count:
  dd 1, 1, 1, 1

mul_by_2:
  dd 2.0, 2.0, 2.0, 2.0

vect_3:
  dd 3, 3, 3, 3

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
mandel_sse:
  sub rsp, 64 

  ; local variables are:
  ; [ r, r, r, r ] 0
  ; [ i, i, i, i ] 16
  ; x              32
  ; y              36 
  ;
  ;
  ; [ temp, temp, temp, temp] 48

  ; xmm3 = [ 4.0, 4.0, 4.0, 4.0 ]
  ; xmm8 = [ 2.0, 2.0, 2.0, 2.0 ]
  movups xmm3, [mandel_max]
  movups xmm8, [mul_by_2]

  ; xmm14 = [ 1, 1, 1, 1 ]
  movups xmm14, [add_count]

  ; rdx = int colors[]
  mov rdx, colors

  ; xmm11 = [ r_step4, r_step4, r_step4, r_step4 ]
  mov eax, [rsi+0]
  mov [rsp+16], eax
  mov [rsp+20], eax
  mov [rsp+24], eax
  mov [rsp+28], eax
  movups xmm11, [rsp+16]

  ; [r, r, r, r] = real_start
  ;mov eax, [rsi+12]
  ;mov [rsp+48], eax
  ;mov [rsp+52], eax
  ;mov [rsp+56], eax
  ;mov [rsp+60], eax

  ; xmm13 = [ r0, r1, r2, r3 ]
  movups xmm13, [rsi+32]

  ; xmm12 = [ i_step, i_step, i_step, i_step ]
  mov eax, [rsi+8]
  mov [rsp+16], eax
  mov [rsp+20], eax
  mov [rsp+24], eax
  mov [rsp+28], eax
  movups xmm12, [rsp+16]

  ; imaginary_start = mandel_info->imaginary_start
  ;mov eax, [rsi+16]
  ;mov [rsp+12], eax

  ; xmm1 = [ i0, i1, i2, i3 ]  imaginary_start
  mov eax, [rsi+16]
  mov [rsp+16], eax
  mov [rsp+20], eax
  mov [rsp+24], eax
  mov [rsp+28], eax
  movups xmm1, [rsp+16]

  ; y = 0
  xor eax, eax 
  mov [rsp+36], eax

  ; for (y = 0; y < height; y++)
for_y:

  ; xmm0 = [ r0, r1, r2, r3 ]
  movaps xmm0, xmm13

  ; x = 0
  xor eax, eax
  mov [rsp+32], eax

  ; for (x = 0; x < width; y++)
for_x:
  ; xmm2 = [ 1, 1, 1, 1 ]
  movaps xmm2, xmm14

  ; xmm4 = zr = [ 0.0, 0.0, 0.0, 0.0 ]
  ; xmm5 = zi = [ 0.0, 0.0, 0.0, 0.0 ]
  pxor xmm4, xmm4
  pxor xmm5, xmm5

  ; counts
  pxor xmm10, xmm10

  mov ecx, 127
mandel_sse_for_loop:
  ; xmm7 = ti = (2 * zr * zi);
  movapd xmm7, xmm4
  mulps xmm7, xmm5
  mulps xmm7, xmm8

  ; xmm4 = tr = ((zr * zr) - (zi * zi));
  mulps xmm4, xmm4
  mulps xmm5, xmm5
  subps xmm4, xmm5

  ; xmm4 = zr = tr + r;
  ; xmm5 = zi = ti + i;
  movapd xmm5, xmm7
  addps xmm4, xmm0 
  addps xmm5, xmm1 

  ; if ((tr * tr) + (ti * ti) > 4) break;
  movapd xmm6, xmm4
  movapd xmm7, xmm5
  mulps xmm6, xmm6
  mulps xmm7, xmm7
  addps xmm6, xmm7
  cmpleps xmm6, xmm3

  ; count const = 0 if less than
  pand xmm2, xmm6
  paddd xmm10, xmm2

  packssdw xmm6, xmm10
  packsswb xmm6, xmm6
  pextrw eax, xmm6, 3
  test eax, eax
  jz exit_mandel

  dec ecx
  jnz mandel_sse_for_loop

exit_mandel:
  psrld xmm10, 3
  pslld xmm10, 2
  movupd [rsp+48], xmm10

  ; map colors into picture 
  mov eax, [rsp+48]
  mov eax, [rdx+rax]
  mov [rdi], eax

  mov eax, [rsp+52]
  mov eax, [rdx+rax]
  mov [rdi+4], eax

  mov eax, [rsp+56]
  mov eax, [rdx+rax]
  mov [rdi+8], eax

  mov eax, [rsp+60]
  mov eax, [rdx+rax]
  mov [rdi+12], eax

  ; picture += 4
  add rdi, 16

  ; [ r0, r1, r2, r3 ] += rstep4;
  addps xmm0, xmm11

  ; next x
  mov eax, [rsp+32]
  add eax, 4
  mov [rsp+32], eax
  cmp eax, [rsi+20]
  jl for_x

  ; [ i0, i1, i2, i3 ] += istep;
  addps xmm1, xmm12

  ; next y
  mov eax, [rsp+36]
  inc eax
  mov [rsp+36], eax
  cmp eax, [rsi+24]
  jl for_y

  add rsp, 64 
  ret

test_sse:
  mov dword [rdi], 1
  mov dword [rdi+4], 1
  mov dword [rdi+8], 1
  mov dword [rdi+12], 1
  movups xmm14, [rdi]
  packssdw xmm14, xmm14
  packsswb xmm14, xmm14
  movups [rdi], xmm14
  ret

