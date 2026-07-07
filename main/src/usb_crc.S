/**
  ******************************************************************************
  * @file      usb_crc.s  [3/7/2026]
  * @author    Renan A. Pacheco
  * @brief   Software implemented crc checks
  *     This module:
  *         - CRC-5 for Tocken packets
  *         - CRC-16 for data pachects
  *
  ******************************************************************************
  */

.global USB_crc16


.equ CRC16_INI,         0xFFFF
.equ CRC16_POLY,        0xA001

.text
/**
 * @brief  CRC-16 for USB data packet
 *
 * @param  a0: len (data array length)
 *         a1: ptr_data
 * @retval  CRC-16
 * @note
 *    prototype:
 *      extern uint16_t USB_crc16(uint16_t len, uint8_t *ptr_data);
 */
.balign 4
USB_crc16:
    addi    a1, a1, 1           # skip pid byte (first)
    addi    a0, a0, -1          # dec length
    bnez    a0, usb_crc16_l0
    mv      a0, x0
    ret
usb_crc16_l0:
    li      a2, CRC16_INI       # crc = 0xFFFF
usb_crc16_l1:
    lbu     a3, 0(a1)
    addi    a1, a1, 1
    li      a5, 8               # Bit counter
usb_crc16_l2:
    xor     a4, a2, a3          # (crc) XOR (data bit)
    srli    a2, a2, 1
    andi    t0, a4, 1
    srli    a4, a4, 1           # Shift to poly test using carry
    beqz    t0, usb_crc16_no_poly
    li      a4, CRC16_POLY
    xor     a2, a2, a4
usb_crc16_no_poly:
    srli    a3, a3, 1           # Next data bit
    addi    a5, a5, -1
    bnez    a5, usb_crc16_l2
    addi    a0, a0, -1
    bnez    a0, usb_crc16_l1
    li      a0, 0xFFFF
    sub     a0, a0, a2          # Final invert (One complement)
    ret
