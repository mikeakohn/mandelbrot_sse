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

mandelbrot_simd:
  ; x0 = picture
  ; x1 = mandel_info

  ; y = 0 (w10)
  eor w10, w10, w10
for_y:

  ; y = 0 (w9)
  eor w9, w9, w9
for_x:

;; implement ldr, ldur

  ; picture++
  add x0, x0, #4

  subs w9, w9, #1
  b.ne for_x

  subs w10, w10, #1
  b.ne for_y

  ret

