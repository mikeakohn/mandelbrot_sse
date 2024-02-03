.arm64

;; ARM64 ABI:
;; r31        SP
;; r30        lr link register
;; r29        fp frame pointer
;; r19 .. r28 Callee-saved
;; r18        platform register
;; r17        ip1 intra-procedure-call temporary register
;; r16        ip0 intra-procedure-call temporary register
;; r9 .. r15  temporary registers
;; r8         indirect result location register
;; r0 .. r7   parameter / result registers

.export mandelbrot_simd

mandel_max:
  dq 4.0, 4.0, 4.0, 4.0

add_count:
  dc32 1, 1, 1, 1

mul_by_2:
  dq 2.0, 2.0, 2.0, 2.0

colors:
  dc32 0xff0000  ; f
  dc32 0xee3300  ; e
  dc32 0xcc5500  ; d
  dc32 0xaa5500  ; c
  dc32 0xaa3300  ; b
  dc32 0x666600  ; a
  dc32 0x999900  ; 9
  dc32 0x669900  ; 8
  dc32 0x339900  ; 7
  dc32 0x0099aa  ; 6
  dc32 0x0066aa  ; 5
  dc32 0x0033aa  ; 4
  dc32 0x0000aa  ; 3
  dc32 0x000099  ; 2
  dc32 0x000066  ; 1
  dc32 0x000000  ; 0

; mandel_simd(x0=picture, x1=struct _mandel_info)
mandelbrot_simd:
  ; x0 = picture
  ; x1 = mandel_info

  ; q2 = [ 2.0, 2.0, 2.0, 2.0 ]
  ; q3 = [ 4.0, 4.0, 4.0, 4.0 ]
  ldr q2, mul_by_2
  ldr q3, mandel_max

  ; q1 = [ 1, 1, 1, 1 ]
  ldr q14, add_count

  ; x5 = int colors[]
  adr x5, colors

  ; q2 = [ r_step4, r_step4, r_step4, r_step4 ]
  ldr w8, [x1, #0]
  dup v2.4s, w8

  ; q13 = [ r0, r1, r2, r3 ]
  ldr q13, [x1, #32]

  ; q3 = [ i_step,  i_step,  i_step,  i_step  ]
  ldr w8, [x1, #8]
  dup v3.4s, w8

  ; q1 = [ i0,  i1,  i2,  i3  ]
  ldr w8, [x1, #8]
  dup v1.4s, w8

  ; y = height (w10)
  ldr w10, [x1, #24]
for_y:
  ;; v0 = [ r0, r1, r2, r3 ]
  orr v0.16b, v13.16b, v13.16b

  ; x = width (w9)
  ldr w9, [x1, #20]
for_x:
  ; xmm2 = [ 1, 1, 1, 1 ]
  ;movaps xmm2, xmm14
  orr v2.16b, v14.16b, v14.16b

  ; q4 = zr = [ 0.0, 0.0, 0.0, 0.0 ]
  ; q5 = zi = [ 0.0, 0.0, 0.0, 0.0 ]
  eor v4.16b, v4.16b, v4.16b
  eor v5.16b, v5.16b, v5.16b

  ; counts 
  eor v10.16b, v10.16b, v10.16b
 
  orr w11, wzr, #127
  ;mov w11, #127
mandel_sse_for_loop:
  ; q7 = ti = (2 * zr * zi);
  ;movapd xmm7, xmm4
  ;mulps xmm7, xmm5
  ;mulps xmm7, xmm8

  fmul v7.4s, v4.4s, v5.4s
  fmul v7.4s, v7.4s, v8.4s

  ; q4 = tr = ((zr * zr) - (zi * zi));
  ;mulps xmm4, xmm4
  ;mulps xmm5, xmm5
  ;subps xmm4, xmm5
  fmul v4.4s, v4.4s, v4.4s
  fmul v5.4s, v5.4s, v5.4s
  fsub v4.4s, v4.4s, v5.4s

  ; q4 = zr = tr + r;
  ; q5 = zi = ti + i;
  fadd v4.4s, v4.4s, v0.4s
  fadd v5.4s, v5.4s, v1.4s

  ; if ((tr * tr) + (ti * ti) > 4) break;
  ;movapd xmm6, xmm4
  ;movapd xmm7, xmm5
  fmul v6.4s, v6.4s, v6.4s
  fmul v7.4s, v7.4s, v7.4s
  fadd v6.4s, v6.4s, v7.4s
  ;cmpleps xmm6, xmm3
  fcmgt v6.4s, v3.4s, v6.4s

  ; count const = 0 if less than
  ;pand xmm2, xmm6
  ;paddd xmm10, xmm2
  and v2.16b, v2.16b, v6.16b
  add v10.4s, v10.4s, v2.4s

  ;ptest xmm6, xmm6
  ;jz exit_mandel
  addv s6, v6.4s
  umov w8, v0.s[0]
  cmp w8, #0
  b.eq exit_mandel

  subs w9, w9, #1
  b.ne for_x

exit_mandel:
  ;shl v10.4s, v10.4s, #2

  umov w12, v10.s[0]
  umov w13, v10.s[1]
  umov w14, v10.s[2]
  umov w15, v10.s[3]

  ldr w12, [x0, x12, lsl #2]
  ldr w13, [x0, x13, lsl #2]
  ldr w14, [x0, x14, lsl #2]
  ldr w15, [x0, x15, lsl #2]

  str w12, [x0, #0]
  str w13, [x0, #4]
  str w14, [x0, #8]
  str w15, [x0, #12]

  ; picture++
  add x0, x0, #16

  subs w10, w10, #1
  b.ne for_y

  ;ldr s0, add_count
  ;str q0, [x0]

  ldr s0, add_count
  ;dup s0, v0.s[0]
  dup v0.4s, v0.s[0]
  str q0, [x0]

  ret

