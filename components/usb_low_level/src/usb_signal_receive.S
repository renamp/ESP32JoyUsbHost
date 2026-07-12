/**
  ******************************************************************************
  * #file      Usb_signal_receive.s  [11/6/2026]
  * #author    Renan A. Pacheco
  * #brief   Handle USB differential signal receive timing
  *     This module:
  *         - Module designed for systemCoreFrequency = 24MHz
  *         - receive USB differential signal
  *         - PORT and PINS for (D-) and (D+) in usb_def_config.inc
  *
  ******************************************************************************
  * #attention
  *     This module is strongly dependent of Core running at 24MHz frequency.
  ******************************************************************************
  */
#

#include "usb_conf.h"

.global USB_ReceiveBytes
.global USB_ReceiveBytesAck

.equ BIT_TIMING_CYCLES,         107

/**
 * #brief  Receive bytes from device and send ACK packet after
 *
 * #param  a0: ptr_out, pointer where to store data received
 * #retval  length of bytes received
 * #note
 *    prototype:
 *      extern uint8_t USB_ReceiveBytesAck(uint8_t *ptr_out);
 */
.section .iram1.text
USB_ReceiveBytesAck:
    li      t3, 1	        # send Ack packet after receive bytes
    j	Receive_Bytes_INI1

/**
 * #brief  Only Receive bytes from device
 *
 * #param  a0: ptr_out, pointer where to store data received
 * #retval  length of bytes received
 * #note
 *    prototype:
 *      extern uint8_t USB_ReceiveBytes(uint8_t *ptr_out);
 */
USB_ReceiveBytes:
    li      t3, 0
Receive_Bytes_INI1:
    addi    sp, sp, -STACK_FRAME_SIZE   # Alloc stack
    addi    t0, sp, STACK_FRAME_SIZE
    sw      s0, -4(t0)                  # push [s0] to stack
    mv      s0, t0                      # Initial stack position to [s0]
    sw      ra, -8(s0)                  # store return address
    sw      a0, -12(s0)                 # pointer outArray
    sw      t3, -16(s0)                 # Store param: (0) No_ACK / (1) ACK0
    csrrc   t0, mstatus, 8              # disable interrupt

    call   fUsb_setMode_Input
    addi    a1, sp, -1                  # Set Ptr for diff array on [a1]
    addi    sp, sp, -STACK_FRAME_SIZE   # Alloc one more stack frame

    li      t3, USB_DATA_K
    li      t4, USB_DATA_J
    li      a5, USB_SYNC_TIMEOUT
    li      t6, USB_GPIO_BASE
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK
    sw      t0, USB_OUT_CLR(t6)         # #DEBUG LOW
#endif

Rcv_wait_first_bit:
    lw      t0, USB_IN(t6)              # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK           # mask usb inputs
    beq  t0, t3, RCV_next_sync_bit      # Check if input changed
    addi    a5, a5, -1                  # dec timeout
    beqz a5, Rcv_Bytes_SyncErro         # sync timeout
    lw      t0, USB_IN(t6)              # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK           # mask usb inputs
    bne  t0, t3, Rcv_wait_first_bit     # Check if input changed

RCV_next_sync_bit:
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK             # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_SET(t6)         # #DEBUG HIGH
#endif
    csrr    t2, MPCCR                   # load cycle counter
    addi    t2, t2, BIT_TIMING_CYCLES + 22   # delay for next sync bit
    li      a7, 6                       # Counter for remaining sync bits (0s)
Rcv_sync_bits_loop:
    csrr    t0, MPCCR
    bltu t0, t2, Rcv_sync_bits_loop
    addi    t2, t2, BIT_TIMING_CYCLES   # delay for next sync bit
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK             # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_CLR(t6)         # #DEBUG  LOW
#endif
    lw      t0, USB_IN(t6)              # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK           # Mask usb inputs
    bne  t0, t4, Rcv_Bytes_SyncErro     # Check if input changed
    mv      t0, t4
    mv      t4, t3
    mv      t3, t0
    addi    a7, a7, -1                  # dec remaining sync bits counter
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK             # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_SET(t6)         # #DEBUG HIGH
#endif
    bnez    a7, Rcv_sync_bits_loop

Rcv_last_sync_bit_delay:
    csrr    t0, MPCCR
    bltu t0, t2, Rcv_last_sync_bit_delay
    addi    t2, t2, BIT_TIMING_CYCLES   # delay for next bit
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK             # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_CLR(t6)         # #DEBUG LOW
#endif
    lw      t0, USB_IN(t6)              # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK           # Mask usb inputs
    bne  t0, t3, Rcv_Bytes_SyncErro     # Check if input changed
    li      a0, 0
    li      a2, USB_DATA_K          #     ; State after last sync bit
    li      a4, 0                   #  timing drift correction
    li      a5, INI_L_ENC_DIFF      #     ; Initial value of last enc.diff
    li      a7, NUMBER_DIFF_BITS_IN_BYTE    # set
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK         # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_SET(t6)     # #DEBUG HIGH
#endif

Rcv_data_bits_loop:
    csrr    t0, MPCCR
    bltu t0, t2, Rcv_data_bits_loop
    addi    t2, t2, BIT_TIMING_CYCLES-1 # delay for next bit
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK           # #DEBUG MASK / Dummy
    sw      t0, USB_OUT_CLR(t6)       # #DEBUG LOW
#endif
    lw      t0, USB_IN(t6)              # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK           # Mask usb inputs
    beqz t0, Rcv_Bytes_EOP              # Branch if (D- and D+ == 0)
    addi    a6, a6, 1                   # inc diff bits counter
    beq  t0, a2, Rcv_diff_no_change     # Check if Data state changed
    mv      a2, t0                      # Update last input
    xori    a5, a5, 0xff                # Invert last enc.diff
Rcv_diff_no_change:
    andi    a5, a5, DIFF_IC_MASK        # Mask incomming diff bits
    srli    a0, a0, 2                   # Shift to position
    or      a0, a0, a5                  # Update enc.diff storage
#if defined(USB_DEBUG_PIN)
    li      t0, USB_DBG_MSK             # #DEBUG MASK
    sw      t0, USB_OUT_SET(t6)         # #DEBUG HIGH
#endif
    addi    a7, a7, -1                  # dec bits in byte counter (4bits)
    bnez  a7, Rcv_data_bits_loop
    sb      a0, 0(a1)                   #
    addi    a1, a1, -1                  # Dec pointer
    li      a7, NUMBER_DIFF_BITS_IN_BYTE  # Reset bits in byte counter
    addi    t2, t2, 4                   # Correct timing shift
    bleu    sp, a1, Rcv_data_bits_loop
    addi    sp, sp, -STACK_FRAME_SIZE
    j   Rcv_data_bits_loop              #


Rcv_Bytes_SyncErro: # sync failed
  #if defined(USB_DEBUG_PIN)
    li    t0, USB_DBG_MSK
    sw    t0, USB_OUT_SET(t6)       # #DEBUG LOW
  #endif
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    ebreak
  #endif
    li   a0, -1
    j    Rcv_Bytes_END

Rcv_Bytes_EOP_ERRO1:
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    ebreak
  #endif
    li   a0, (-2 & 0xFFFF)
    j    Rcv_Bytes_END

Rcv_Bytes_EOP_ERRO2:
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    ebreak
  #endif
    li   a0, (-3 & 0xFFFF)
    j    Rcv_Bytes_END

Rcv_Bytes_EOP:
    sb    a0, 0(a1)               #
Rcv_EOP_wait1:
    csrr    t0, MPCCR
    bltu t0, t2, Rcv_EOP_wait1
    addi    t2, t2, BIT_TIMING_CYCLES   # delay for next bit
#if defined(USB_DEBUG_PIN)
    li    t0, USB_DBG_MSK         # #DEBUG MASK
    sw    t0, USB_OUT_SET(t6)     # #DEBUG HIGH
#else
    nop                           # [ dummy to fill timing]
#endif
    lw      t0, USB_IN(t6)        # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK     # Mask usb inputs
    bnez  t0, Rcv_Bytes_EOP_ERRO1 # Branch if (D- and D+ == 0)
#if defined(USB_DEBUG_PIN)
    li    t0, USB_DBG_MSK         # #DEBUG MASK
    sw    t0, USB_OUT_CLR(t6)     # #DEBUG LOW
#endif
Rcv_EOP_wait2:
    csrr    t0, MPCCR
    bltu    t0, t2, Rcv_EOP_wait2
    csrr    t2, MPCCR             # load cycle counter
    lw      t0, USB_IN(t6)        # Read input (D- and D+)
    andi    t0, t0, USB_D_MSK     # Mask usb inputs
    bne     t0, t4, Rcv_Bytes_EOP_ERRO2  #
    lw      a5, -16(s0)           # param: (0) dont call ACK / (1) call ACK
    beqz    a5, Rcv_Bytes_NoAck   # branch if param No ACK
Rcv_Bytes_DoAck:
    li      t0, USB_DIFF_ACK_PACKET
    mv      t1, sp
    addi    sp, sp, -STACK_FRAME_SIZE
    sw      s1, -4(t1)
    sw      a6, -8(t1)            # diff bits counter
    sw      t0, -16(t1)           # store ACK to stack

    li      a0, 200
    la      t0, _fDelay
    jalr    t0

    mv      s1, t1
    li      a0, USB_DIFF_ACK_PACKET_LEN
    addi    a1, s1, -13

    la	    t0, Send_RawDiff
    jalr    t0
    
    mv      t1, s1
    lw      a6, -8(t1)            # back stack pointer
    lw      s1, -4(t1)            # back from stack
    mv      sp, t1                # stack position before last use

Rcv_Bytes_NoAck:
    csrrs   x0, mstatus, 8        # enable interrups
    mv      a0, a6                # length diff bits
    addi    a1, s0, -1-STACK_FRAME_SIZE   # ptr to diff bits (reverse stored)
    lw      a2, -12(s0)           # ptr outArray Data (from stack)

    la	    t0, Rawdiff2Bytes
    jalr    t0

Rcv_Bytes_END:
    csrrs   x0, mstatus, 8  # enable interrups
    mv      t0, s0          # Initial stack position to [t0]
    lw      ra, -8(t0)      # restore return address
    lw      s0, -4(t0)      # restore [s0] from stack
    mv      sp, t0          # restore stack initial position
    ret
