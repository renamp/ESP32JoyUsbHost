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
.global USB_AppendCRC5


.equ CRC16_INI,         0xFFFF
.equ CRC16_POLY,        0xA001
.equ CRC5_POLY,         0x14        ; poly = 10100
.equ CRC5_INIMASK,      0x1F

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


/**
 * @brief  Calculate and Append CRC-5 to USB token
 *
 * @param  a0: pointer to USBToken struct type
 * @retval  CRC-5
 * @note
 *    prototype:
 *      extern void USB_AppendCRC5(USBToken *data);
 * USBToken {[0:8]pid, [0:6]Addr|[7:10]endpont|[11:15]CRC}
 */
USB_AppendCRC5:
    lw      a1, 0(a0)            # Read token
    srli    a1, a1, 8           # Rotate to exclude first byte (pid)
    li      t0, CRC5_INIMASK    # init = 11111
    li      t1, 11
crc5_01:
    xor     t2, t0, a1
    srli    a1, a1, 1
    srli    t0, t0, 1
    andi    t6, t2, 1
    srli    t2, t2, 1
    beqz    t6, crc5_02
    li      t2, CRC5_POLY
    xor     t0, t0, t2		    # xor with poly
crc5_02:
    addi    t1, t1, -1          # decrement
    bnez    t1, crc5_01
    li      t2, 0xff
    and     t0, t0, t2
    sub     t2, t2, t0          # One complement
    andi    a1, t2, CRC5_INIMASK
    slli    t0, a1, 3           # Shift returned crc5
    andi    t0, t0, 0xF8        # CRC5 last 5 bits
    lbu     t1, 2(a0)
    andi    t1, t1, 0x7         # First 3 bits are from endpoint
    or      t1, t1, t0
    sb      t1, 2(a0)           # Append CRC5 to Token array
    ret
