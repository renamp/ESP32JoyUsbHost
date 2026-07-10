/**
  ******************************************************************************
  * @file      usb_util.s  [3/7/2026]
  * @author    Renan A. Pacheco
  * @brief   Utility functions
  *
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */

#include "usb_conf.h"

.global _fDelay
.global _fDelay_a4
.global fUsb_setMode_Init
.global fUsb_setMode_Input
.global fUsb_setMode_Output
.global fUsb_setMode_Reset
.global fUsb_DBGsetMode_Output

/**
 * @brief  busy delay ((A0 * 3) + 1) + (3 for the call [jal]) cycles
 *
 * @param  a0: loops number
 *
 */
.section .iram1.text
_fDelay:             # ([a0]*3) + 1
    addi   a0, a0, -1       #1,   0/--| dec delay counter
    bnez   a0, _fDelay      #1/2, 1/3| loop until delay is over
    ret                     #2,   2/--| return from delay function

.section .iram1.text
_fDelay_a4:           # (1+([a4]*3))  Same function but using A4
    addi   a4, a4, -1       #1,   0/--| dec delay counter
    bnez   a4, _fDelay_a4   #1/2, 1/3| loop until delay is over
    ret                     #2,   2/--| return from delay function



/**
 * @brief  Set USB pins (D- and D+) as INPUTs
 */
.section .iram1.text
fUsb_setMode_Input:
    li      t1, USB_GPIO_BASE
    li      t0, USB_D_MSK
    sw      t0, USB_MODE_IN(t1)         # INPUT
    ret


/**
 * @brief  Set USB pins (D- and D+) as OUTPUTs
 */
.section .iram1.text
fUsb_setMode_Output:
    li      t1, USB_GPIO_BASE
    lw      t0, USB_OUT(t1)             # Read current Output state
    andi    t0, t0, ~USB_D_MSK          # Mask D- and D+ bits
    ori     t0, t0, USB_DIFF_0          # Set D- and D+ bits
    sw      t0, USB_OUT(t1)             # Store new Output state
    li      t0, USB_D_MSK
    sw      t0, USB_MODE_OUT(t1)        # set output mode
    ret


/**
 * @brief  Initialize Performance counter and D- D+ pins
 */
.text
fUsb_setMode_Init:
    mv      t6, ra
    li      t0, 1
    csrw    MPCER, t0                   # Set cycle count
    csrw    MPCMR, t0                   # Enable Performance counter
    li      t0, (1 << 9) | (1 << 7)     # Bit 9 = IE, Bit 8 = WPD
    li      t1, USB_DM_IO_MUX
    sw      t0, 0(t1)                   # set input config for D-
    li      t1, USB_DP_IO_MUX
    sw      t0, 0(t1)                   # set input config for D+
#if defined(USB_DEBUG_PIN)
    la      t0, fUsb_DBGsetMode_Output
    jalr    t0    
#endif
    mv      ra, t6
    la      t0, fUsb_setMode_Reset
    jr      t0


/**
 * @brief  Set USB pins (D- and D+) as RESET (SE0)
 */
.section .iram1.text
fUsb_setMode_Reset:
    mv      t6, ra                      # Save return address
    jal    fUsb_setMode_Output
    li      t1, USB_GPIO_BASE
    li      t0, USB_D_MSK
    sw      t0, USB_SE0(t1)             # Set SE0
    mv      ra, t6                      # Restore return address
    ret


/**
 * @brief  Set DEBUG pin as OUTPUT
 */
.text
fUsb_DBGsetMode_Output:
#if defined(USB_DEBUG_PIN)
    li      t1, USB_GPIO_BASE
    li      t0, USB_DBG_MSK
    sw      t0, USB_MODE_OUT(t1)        # Output
    sw      t0, USB_OUT_SET(t1)         # Set Debug pin
#endif
    ret
