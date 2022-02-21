;; Cluster
;;
;; Copyright 2022 - By Michael Kohn
;; http://www.mikekohn.net/
;; mike@mikekohn.net
;;
;; Multiple chips listen to SPI to give the ability to upload code to
;; to flash, run it with paramters, and return a result.

.include "msp430x2xx.inc"

LED equ 0x01
CHIP_BUSY equ 0x08
SPI_CS  equ 0x10
SPI_CLK equ 0x20
SPI_SDO equ 0x40
SPI_SDI equ 0x80

RAM equ 0x0200
PROGRAM_LENGTH equ RAM
COMMAND equ RAM+2
VALUE_R equ RAM+4
VALUE_I equ RAM+6
DEBUG equ RAM+16
CHECKSUM equ RAM+18
CHECKSUM_2 equ RAM+20

;  r4 =
;  r5 =
;  r6 =
;  r7 =
;  r8 =
;  r9 =
; r10 =
; r11 =
; r12 =
; r13 =
; r14 =
; r15 = temp

.org 0xf800
start:
  ;; Turn off watchdog
  mov.w #WDTPW|WDTHOLD, &WDTCTL

  ;; Turn off interrupts
  dint

  ;; Set up stack pointer
  mov.w #0x0280, SP

  call #set_clock_12MHz
  ;call #set_clock_8MHz
  ;call #set_clock_1MHz

  ;; Set up output pins
  ;; P1.1 = LED
  ;; P1.3 = IsBusy (Output)
  ;; P1.4 = /CS
  ;; P1.5 = SCLK
  ;; P1.6 = SDO
  ;; P1.7 = SDI
  mov.b #CHIP_BUSY | LED, &P1DIR
  mov.b #CHIP_BUSY, &P1OUT

  ;; Setup hardware SPI.
  ;mov.b #USIPE7|USIPE6|USIPE5|USIOE|USISWRST, &USICTL0
  ;;mov.b #USIPE7|USIPE6|USIPE5|USISWRST, &USICTL0
  ;mov.b #USICKPH, &USICTL1
  ;mov.b #0, &USICKCTL
  ;bic.b #USISWRST, &USICTL0      ; clear reset

  ;; Setup software SPI.
  ;bis.b #SPI_SDO, &P1DIR

  ;; Set up Timer
  ;mov.w #1600, &TACCR0
  ;mov.w #(TASSEL_2|MC_1), &TACTL ; SMCLK, DIV1, COUNT to TACCR0
  ;mov.w #CCIE, &TACCTL0
  ;mov.w #0, &TACCTL1

  ;; Clear RAM
  mov.w #RAM, r4
clear_ram:
  mov.w #0, @r4
  add.w #2, r4
  cmp.w #RAM+0x20, r4
  jnz clear_ram

  call #compute_checksum

  ;; Enable interrupts
  eint

main:
  call #read_spi
  mov.b r15, &COMMAND
  cmp.b #0x01, r15
  jeq download_program
  cmp.b #0x02, r15
  jeq run_program
  cmp.b #0x03, r15
  jeq set_r
  cmp.b #0x04, r15
  jeq set_i
  jmp main

download_program:
  mov.w #0, &CHECKSUM
  ;; Read length of program.
  call #read_spi
  mov.b r15, &PROGRAM_LENGTH + 0
  call #read_spi
  mov.b r15, &PROGRAM_LENGTH + 1
  call #erase_flash
  mov.w &PROGRAM_LENGTH, r4
  mov.w #code, r14
read_program_loop:
  call #read_spi
  add.w r15, &CHECKSUM
  call #write_flash
  inc.w r14
  dec.w r4
  jnz read_program_loop
  call #compute_checksum
  jmp main

run_program:
  bis.b #LED, &P1OUT
  mov.w &VALUE_R, -6(sp)
  mov.w &VALUE_I, -8(sp)
  call #code
  mov.w r15, &DEBUG
  mov.b r15, &USISRL
  bic.b #CHIP_BUSY, &P1OUT
  call #read_spi
  bic.b #LED, &P1OUT
  jmp main

set_r:
  call #read_spi
  mov.b r15, &VALUE_R + 0
  call #read_spi
  mov.b r15, &VALUE_R + 1
  jmp main

set_i:
  call #read_spi
  mov.b r15, &VALUE_I + 0
  call #read_spi
  mov.b r15, &VALUE_I + 1
  jmp main

read_spi:
read_spi_wait:
  bit.b #SPI_CS, &P1IN
  jz read_spi_wait
  bis.b #CHIP_BUSY, &P1OUT
  mov.b #8, r10
  mov.b #0, r11
  bis.b #SPI_SDO, &P1DIR
  bic.b #SPI_SDO, &P1OUT
  bic.b #CHIP_BUSY, &P1OUT
read_spi_next_bit:
  bit.b #0x80, r15
  jz read_spi_bit_is_zero
  bis.b #SPI_SDO, &P1OUT
read_spi_bit_is_zero:
  rla.w r15
read_spi_wait_for_clock_high:
  bit.b #SPI_CLK, &P1IN
  jz read_spi_wait_for_clock_high
  rla.w r11
  bit.b #SPI_SDI, &P1IN
  jz read_spi_wait_for_clock_low
  bis.w #1, r11
read_spi_wait_for_clock_low:
  bit.b #SPI_CLK, &P1IN
  jnz read_spi_wait_for_clock_low
  bic.b #SPI_SDO, &P1OUT
  dec.b r10
  jnz read_spi_next_bit
  mov.b r11, r15
  bis.b #CHIP_BUSY, &P1OUT
  bic.b #SPI_SDO, &P1DIR
  ret

read_spi_hardware:
  bit.b #SPI_CS, &P1IN
  jz read_spi
  mov.b #8, &USICNT
  bic.b #CHIP_BUSY, &P1OUT
read_spi_loop:
  ;; Wait on no data received.
  bit.b #USIIFG, &USICTL1
  jz read_spi_loop
read_spi_wait_clock:
  bit.b #USISCLREL, &USICNT
  jnz read_spi_wait_clock

  bis.b #CHIP_BUSY, &P1OUT
  mov.b &USISRL, r15
  ret

write_flash:
  bis.b #LED, &P1OUT
  dint

  ;; Set timing.
  mov.w #FWKEY | FSSEL_1 | 31, &FCTL2

  ;; Unlock memory
  mov.w #FWKEY, &FCTL3

  ;; Put in erase mode (immediate value here can be anything).
  ;mov.w #FWKEY | ERASE, &FCTL1
  ;mov.b #0xff, @r14

  ;; Put in write mode.
  mov.w #FWKEY | WRT, &FCTL1
  mov.b r15, @r14

  ;; Lock memory.
  mov.w #FWKEY, &FCTL1
  mov.w #FWKEY | LOCK, &FCTL3

  eint
  bic.b #LED, &P1OUT
  ret

erase_flash:
  bis.b #LED, &P1OUT
  dint

  ;; Set timing.
  mov.w #FWKEY | FSSEL_1 | 31, &FCTL2

  ;; Unlock memory
  mov.w #FWKEY, &FCTL3

  ;; Put in erase mode (immediate value here can be anything).
  mov.w #FWKEY | ERASE, &FCTL1

  mov.w #code, r14
  mov.w &PROGRAM_LENGTH, r4
erase_flash_loop:
  mov.b #0xff, @r14
  inc.w r14
  dec.w r4
  jnz erase_flash_loop

  ;; Lock memory.
  mov.w #FWKEY, &FCTL1
  mov.w #FWKEY | LOCK, &FCTL3

  eint
  bic.b #LED, &P1OUT
  ret

compute_checksum:
  ;; Warning: The file size is hardcoded.
  mov.w #426, r4
  mov.w #0, &CHECKSUM_2
  mov.w #code, r5
compute_checksum_loop:
  mov.b @r5+, r15
  add.w r15, &CHECKSUM_2
  dec.w r4
  jnz compute_checksum_loop
  ret

set_clock_12MHz:
  ;; Set MCLK to 12 MHz with DCO
  mov.b #DCO_5, &DCOCTL
  mov.b #RSEL_14, &BCSCTL1
  mov.b #0, &BCSCTL2
  ret

set_clock_8MHz:
  ;; Set MCLK to 8 MHz with DCO
  mov.b #DCO_5, &DCOCTL
  mov.b #RSEL_13, &BCSCTL1
  mov.b #0, &BCSCTL2
  ret

set_clock_1MHz:
  ;; Set MCLK to 1 MHz with DCO
  mov.b #DCO_3, &DCOCTL
  mov.b #RSEL_7, &BCSCTL1
  mov.b #0, &BCSCTL2
  ret

.org 0xfa00
code:

.org 0xfffe
  dw start                 ; Reset

