/**
  ******************************************************************************
  * @file      Usb_signal_transfer.s  [3/7/2026]
  * @author    Renan A. Pacheco
  * @brief   Handle USB differential signal transmission timing
  *     This module:
  *         - Module designed for systemCoreFrequency = 160MHz
  *         - Transmit and receive USB differential signal
  *         - Uses PA0 for (D-) and PA1 for (D+)
  *
  ******************************************************************************
  * @attention
  *     This module is strongly dependent of Core running at 160MHz frequency.
  ******************************************************************************
  */

#include "usb_conf.h"

.global Send_RawDiff

/**
 * @brief  Send Raw differential data bits
 *
 * @param  a0: Length of array differential bits
 * @param  a1: Pointer of array differential bits
 * @retval void
 *
 * @note
 *
 */
.section .iram1.text
Send_RawDiff:
    mv      a7, ra
    jal   fUsb_setMode_Output
    li      t6, USB_GPIO_BASE
    li      t5, USB_DIFF_0_C
    li      t4, USB_DIFF_0
    li      t3, USB_DIFF_1_C
    li      t2, USB_DIFF_1
    csrrc   x0, mstatus, 8      # Disable interrupt
    j     Send_RawDiff_L1       # jump to send raw diff bits

Sd_RD_fSIGNAL:
    andi    t0, a2, 1           # Get next bit in carry
    bnez    t0, Sd_RD_fSIGNAL1
    nop
    nop
    sw      t2, USB_OUT_SET(t6)
    sw      t3, USB_OUT_CLR(t6)
    ret

Sd_RD_fSIGNAL1:
    sw      t4, USB_OUT_SET(t6)
    sw      t5, USB_OUT_CLR(t6)
    ret

Send_RawDiff_L1:
    lbu      a2, 0(a1)          # Load byte from data in
    addi    a1, a1, -1          # dec data pointer
Send_RawDiff_L2:
    jal    Sd_RD_fSIGNAL        # Send bit to USB lines
    srli    a2, a2, 2           # Shift byte to get next bit in carry
    addi    a0, a0, -1          # dec bit length
    beqz   a0, Send_RawDiff_End # Branch if more bits to send
    li      a4, 20
    jal     _fDelay_a4          # Delay to fill timing

    jal    Sd_RD_fSIGNAL        # Send bit to USB lines
    srli    a2, a2, 2           # Shift byte to get next bit in carry
    addi    a0, a0, -1          # dec bit length
    beqz   a0, Send_RawDiff_End # Branch if more bits to send
    li      a4, 19
    jal     _fDelay_a4          # Delay to fill timing

    jal    Sd_RD_fSIGNAL        # Send bit to USB lines
    srli    a2, a2, 2           # Shift byte to get next bit in carry
    addi    a0, a0, -1          # dec bit length
    beqz   a0, Send_RawDiff_End # Branch if more bits to send
    li      a4, 19
    jal     _fDelay_a4          # Delay to fill timing

    jal    Sd_RD_fSIGNAL        # Send bit to USB lines
    li      a4, 18
    jal     _fDelay_a4          # Delay to fill timing

    addi    a0, a0, -1          # dec bit length
    bnez    a0, Send_RawDiff_L1
Send_RawDiff_End:
    li      t3, USB_D_MSK
    sw      t3, USB_SE0(t6)     # Set SE0 to signal end of packet

    li      a4, 52
    jal     _fDelay_a4          # Delay to fill timing

    lw      t3, USB_OUT(t6)
    andi    t3, t3, ~USB_D_MSK
    ori     t3, t3, USB_DIFF_0
    sw      t3, USB_OUT(t6)     # Set D+ low, D- high (idle state)

    mv    a0, x0
    mv    a1, x0
    mv    ra, a7
    ret
