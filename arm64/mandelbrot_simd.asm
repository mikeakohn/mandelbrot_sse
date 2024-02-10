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

;; v0:  [   r,   r,   r,   r ]
;; v1:  [  i0,  i1,  i2,  i3 ]
;; v2:  [ inc, inc, inc, inc ]
;; v3:  [ 4.0, 4.0, 4.0, 4.0 ]
;; v4:  [  zr,  zr,  zr,  zr ]
;; v5:  [  zi,  zi,  zi,  zi ]
;; v6:  [ cmp value < 4.0 mask   ]
;; v7:  ti = (2 * zr * zi)
;; v8:  [ 2.0, 2.0, 2.0, 2.0 ]
;; v9:  temp
;; v10: [   count,   count,   count,   count ]
;; v11: [ r_step4, r_step4, r_step4, r_step4 ]
;; v12: [ i_step,  i_step,  i_step,  i_step  ]
;; v13: [  r0,  r1,  r2,  r3 ]
;; v14: [   1,   1,   1,   1 ]
;; v15: zr * zr (aka zr^2)
;; v16: zi * zi (aka zi^2)
;; v17: tr = (zr * zr) - (zi * zi)
;; v18: temp

;;  x0: int *picture
;;  x1: struct _mandel_info
;;  x5: colors
;;  w7: temp
;;  w9: for x
;; w10: for y
;; w11: for count
;; w12: color 0
;; w13: color 1
;; w14: color 2
;; w15: color 3

.export mandelbrot_simd

.macro CRASH
  eor x2, x2, x2
  str w2, [x2]
.endm

mandel_max:
  dc32 4.0, 4.0, 4.0, 4.0

add_count:
  dc32 1, 1, 1, 1

mul_by_2:
  dc32 2.0, 2.0, 2.0, 2.0

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

  ; v8 = [ 2.0, 2.0, 2.0, 2.0 ]
  ; v3 = [ 4.0, 4.0, 4.0, 4.0 ]
  ldr q8, mul_by_2
  ldr q3, mandel_max

  ; v14 = [ 1, 1, 1, 1 ]
  ldr q14, add_count

  ; x5 = int colors[]
  adr x5, colors

  ; v11 = [ r_step4, r_step4, r_step4, r_step4 ]
  ldr w7, [x1, #0]
  dup v11.4s, w7

  ; v13 = [ r0, r1, r2, r3 ]
  ; offset of 32, but indexed by 2.
  ;; FIXME: fix naken_asm.
  ldr q13, [x1, #2]

  ; v12 = [ i_step,  i_step,  i_step,  i_step  ]
  ldr w7, [x1, #8]
  dup v12.4s, w7

  ; v1 = [ i0,  i1,  i2,  i3  ]
  ldr w7, [x1, #16]
  dup v1.4s, w7

  ; y = height (w10)
  ldr w10, [x1, #24]
for_y:
  ;; v0 = [ r0, r1, r2, r3 ]
  orr.16b v0, v13, v13

  ; x = width (w9)
  ldr w9, [x1, #20]
  ;; FIXME: naken_asm is generating asr.
  lsr w9, w9, #2
for_x:
  ; xmm2 = [ 1, 1, 1, 1 ]
  ;movaps xmm2, xmm14
  orr.16b v2, v14, v14

  ; v4 = zr = [ 0.0, 0.0, 0.0, 0.0 ]
  ; v5 = zi = [ 0.0, 0.0, 0.0, 0.0 ]
  eor.16b v4, v4, v4
  eor.16b v5, v5, v5

  ; counts
  eor.16b v10, v10, v10

  orr w11, wzr, #127
  ;; FIXME: add mov.
  ;mov w11, #127
mandel_simd_for_loop:
  ; v7 = ti = (2 * zr * zi);
  ;movapd xmm7, xmm4
  ;mulps xmm7, xmm5
  ;mulps xmm7, xmm8
  fmul.4s v7, v4, v5
  fmul.4s v7, v7, v8

  ; v17 = tr = ((zr * zr) - (zi * zi));
  ;mulps xmm4, xmm4
  ;mulps xmm5, xmm5
  ;subps xmm4, xmm5
  fmul.4s v15, v4, v4
  fmul.4s v16, v5, v5
  fsub.4s v17, v15, v16

  ; q4 = zr = tr + r;
  ; q5 = zi = ti + i;
  fadd.4s v4, v17, v0
  fadd.4s v5, v7, v1

  ; if ((tr * tr) + (ti * ti) > 4.0) break;
  ;movapd xmm6, xmm4
  ;movapd xmm7, xmm5
  ;mulps xmm6, xmm6
  ;mulps xmm7, xmm7
  ;addps xmm6, xmm7
  fmul.4s v6, v4, v4
  fmul.4s v7, v5, v5
  fadd.4s v18, v6, v7

  ;cmpleps xmm6, xmm3
  fcmgt.4s v9, v3, v18

  ; count const = 0 if less than
  ;pand xmm2, xmm6
  ;paddd xmm10, xmm2
  and.16b v2, v2, v9
  add.4s v10, v10, v2

  ;ptest xmm6, xmm6
  ;jz exit_mandel
  addv s9, v9.4s
  umov w7, v9.s[0]
  cmp w7, #0
  b.eq exit_mandel

  subs w11, w11, #1
  b.ne mandel_simd_for_loop

exit_mandel:
  sshr.4s v10, v10, #3

  umov w12, v10.s[0]
  umov w13, v10.s[1]
  umov w14, v10.s[2]
  umov w15, v10.s[3]

  ldr w12, [x5, x12, lsl #2]
  ldr w13, [x5, x13, lsl #2]
  ldr w14, [x5, x14, lsl #2]
  ldr w15, [x5, x15, lsl #2]

  str w12, [x0, #0]
  str w13, [x0, #4]
  str w14, [x0, #8]
  str w15, [x0, #12]

  ; picture++
  add x0, x0, #16

  ; r += r_step
  fadd.4s v0, v0, v11

  subs w9, w9, #1
  b.ne for_x

  ; i += i_step
  fadd.4s v1, v1, v12

  subs w10, w10, #1
  b.ne for_y

  ret

