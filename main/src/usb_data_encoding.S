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
.global Rawdiff2Bytes

.equ  SYNC_BITS,                0x66A6
.equ  BITSTUFF_CNT_INIT,        0x05
.equ  BITSTUFF_CNT_RST,         0x07
.equ  STACK_FRAME_SIZE,         16

.equ BITSTUFF_CNT_RST,          0x06
.equ INITIAL_DIFF,              0x02
.equ DIFF_MASK,                 0x03
.equ SET_BIT,                   0x80
.equ NUMBER_DIFF_BITS_IN_BYTE,  4

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


/**
 * @brief  Converts an array of raw differential bits to data bytes.
 * @param  a0: Length of the input raw differential data in bits
 * @param  a1: Pointer to the raw differential data array(stored reverse)
 * @param  a2: Pointer to the data array to store output bytes
 * @retval a0: Length of the output data in bytes
 * @note
 *
 */
Rawdiff2Bytes:
    mv      a7, x0              # clear data bytes counter
    mv      t6, x0              # clear (T)[t6] skip bitstuff
    mv      t5, x0              # clear Decoding data byte
    li      a6, 0x08            # [a6] count data_bits
    li      a4, NUMBER_DIFF_BITS_IN_BYTE   # [a4] load counter diff bits in byte
    li      t3, BITSTUFF_CNT_RST           # [t3] reset bitstuff counter
    li      t4, INITIAL_DIFF               # [t4] load Initial diff state
Rawdiff2BytesI0:
    lbu     t2, 0(a1)           # load to [t2] next packed bitstuff from array
    addi    a1, a1, -1          # update point to next element (dec)
Rawdiff2BytesI1:
    andi    t0, t2, DIFF_MASK   # next diff (D- and D+) masked to decode
    xor     t1, t4, t0          # check state of bits. if didnt change result==0
    mv      t4, t0              # store actual state for next check
    bnez    t1, Rawdiff2BytesL1 # branch if state changed
    srli    t5, t5, 1
    addi    t3, t3, -1          # decrement bitstuff counter [t3]
    bnez    t3, Rawdiff2BytesL2 # branch if not bitstuff
    li      t6, 1               # set (T)[t6] skip next bit. it is a bitstuffed
    li      t3, BITSTUFF_CNT_RST
Rawdiff2BytesL2:
    or      t5, t5, SET_BIT     # update current decoding data byte
    j      Rawdiff2BytesL3
Rawdiff2BytesS1:
    mv      t6, x0              # clear (T)[t6] skip bitstuff
    j      Rawdiff2BytesL4
Rawdiff2BytesL1:
    bnez    t6, Rawdiff2BytesS1 # it is bitstuff - goto skip bitstuff
    srli    t5, t5, 1           # update current decoding data byte
    li      t3, BITSTUFF_CNT_RST
Rawdiff2BytesL3:                # check number of bits
    addi   a6, a6, -1           # [a6] decrement data_bits counter
    bnez    a6, Rawdiff2BytesL4 # branch when counter==0
    li      a6, 0x08            # reset data_bits counter [a6]
    sb      t5, 0(a2)           # store decoded data
    addi    a2, a2, 1           # Increment data pointer
    addi    a7, a7, 1           # incremment decoded data counter [a7]
    mv      t5, x0              # clear Decoding data byte
Rawdiff2BytesL4:                # check diff len
    add     a0, a0, -1          # decrement len diff bits
    beqz    a0, Rawdiff2BytesEND
    srli    t2, t2, 2           # rotate to next differential (D- and D+)
    addi    a4, a4, -1          # decrement diff bits in byte counter
    bnez    a4, Rawdiff2BytesI1
    li      a4, NUMBER_DIFF_BITS_IN_BYTE
    j       Rawdiff2BytesI0
Rawdiff2BytesEND:
    mv   a0, a7          # return len of decoded data bytes
    ret
