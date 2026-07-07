/**
  ******************************************************************************
  * @file      usb_data_encoding.S  [3/7/2026]
  * @author    Renan A. Pacheco
  * @brief     Data encoding and decoding for USB communication
  *     This module performs:
  *         - Conversion of data bytes to raw differential format for
  *           USB transmission
  *         - Handling of bit stuffing for USB communication protocol
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */


.global Bytes2Rawdiff

.equ  SYNC_BITS,            0x66A6
.equ  BITSTUFF_CNT_INIT,    0x05
.equ  BITSTUFF_CNT_RST,     0x07
.equ  STACK_FRAME_SIZE,     16

.text

/**
 * @brief  Converts an array of data bytes to raw differential format for
 *         USB transmission.
 * @param  a0: Length of the input data array (number of bytes)
 * @param  a1: Pointer to the input data array
 * @param  a2: Pointer to function to handle the rawdiff data
 *
 * Passed to function (a2)
 * @param  a0: Length of the output raw differential data in bits
 *         a1: Pointer to the output raw differential data (stored on the stack)
 *              !!(the pointer is stored on the stack in reverse order,
 *              callee must read decrementally)!!
 * @note
 *
 */
Bytes2Rawdiff:
    mv      t6, sp          # [t6] initial stack position
    addi    sp, sp, -STACK_FRAME_SIZE     # Alloc stack frame
    sw      s0, -4(t6)      # [s0] backup register
    sw      ra, -8(t6)      # [s1] backup return address
    mv      s0, t6          # [s0] store initial stack position

    li      t0, SYNC_BITS   # load sync bits differential
    sh      t0, -10(s0)     # store sync bits on stack
    addi    a7 , s0, -10    # [a7] save rawdiff pointer
    li      a6, BITSTUFF_CNT_INIT    # [a6] count 1s(start with 1)
    li      t5, 0x00        # current diff byte
    li      t4, 0x03        # diff bits mask
    li      t3, 0xAA        # previous diff state
    li      a5, 0x08        # [a5] outLendiff bits
Bytes2Rawdiff_L0:
    lbu     t1, 0(a1)       # [t1] load byte from data in
    addi    a1, a1, 1       # inc data pointer
    li      a4, 0x08        # [a4] bits in byte
Bytes2Rawdiff_L1:
    andi    t0, t1, 0x01    # get LSB bit
    srli    t1, t1, 1       # rotate to next bit
    bnez    t0, Bytes2Rawdiff_L3    # branch if bit is 1
Bytes2Rawdiff_L2:
    xori    t3, t3, 0xFF    # change diff
    li      a6, BITSTUFF_CNT_RST   # [a6] update bitstuff count
Bytes2Rawdiff_L3:
    addi    a5, a5, 1       # [a5] inc len diff bits
    and     t0, t3, t4      # mask bits
    or      t5, t5, t0      # store diff
    slli    t4, t4, 2       # shift mask
    andi    t4, t4, 0xFF    # mask diff bits
    bnez    t4, Bytes2Rawdiff_L4    # jump if dont need store
    jal    StoreByte
    li      t5, 0x00        # reset current diff byte
    li      t4, 0x03        # reset diff bits mask
Bytes2Rawdiff_L4:
    addi    a6, a6, -1      # [a6] dec bitstuff count
    beqz    a6, Bytes2Rawdiff_L2    # add bitstuff (0)
    addi    a4, a4, -1      # [a4] dec bits of byte
    bnez    a4, Bytes2Rawdiff_L1
    addi    a0, a0, -1      # [a0] dec bytes in array in
    bnez    a0, Bytes2Rawdiff_L0
    jal   StoreByte
    mv      a0, a5          # len diff bits
    addi    a1, s0, -9      # ptr array diff

    jalr    a2              # Call function to handle the rawdiff data

    mv      t6, s0          # [t6] initial stack position
    lw      ra, -8(t6)      # restore return address
    lw      s0, -4(t6)      # restore register
    mv      sp, t6          # restore stack
    ret

StoreByte:
    addi    a7, a7, -1      # [a7] rawdiff pointer next position (dec)
    bgt     a7, sp, StoreByteNoOverflow # if dont overflow stack frame
    addi    sp, sp, -STACK_FRAME_SIZE   # Alloc one more stack frame
StoreByteNoOverflow:
    sb      t5, 0(a7)       # store diff byte
    ret
