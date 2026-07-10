/**
  ******************************************************************************
  * @file           : usb_conf.h
  * @brief          : Header for usb configuration.
  *                   This file contains the common defines for usb.
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __USB_CONF_H
#define __USB_CONF_H

/******************************************************************************/
/************************ Lib Configuration ***********************************/

/* USB gpio port base address of D- and D+ pins ------------------------------*/
#define USB_GPIO_D_MINUS_PIN    0
#define USB_GPIO_D_PLUS_PIN     1


/*----------------------------------------------------------------------------*/
/* Debug pin to assist on timing analyses ------------------------------------*/
#define USB_DEBUG_PIN           8

/* Insert brake point to sync and eop erro procedures ------------------------*/
//#define USB_DEBUG_SYNC_EOP_ERROR


/*----------------------------------------------------------------------------*/
/* USB core handling definitions ---------------------------------------------*/
#define NUMBER_DIFF_BITS_IN_BYTE  0x04
#define STACK_FRAME_SIZE          16


/*----------------------------------------------------------------------------*/
/* Device specific definitions -----------------------------------------------*/
#define USB_GPIO_BASE       0x60004000
#define GPIO_IO_MUX_BASE    0x60009000
#define GPIO_OUT_W1TS       0x08
#define GPIO_OUT_W1TC       0x0C
#define GPIO_EN_W1TS        0x24
#define GPIO_EN_W1TC        0x28
#define GPIO_IN             0x3C
#define GPIO_OUT            0x04
#define MPCER               0x7E0 
#define MPCMR               0x7E1
#define MPCCR               0x7E2


/*----------------------------------------------------------------------------*/
/* Alias for (D-) (D+) defined pins ------------------------------------------*/
#define USB_DMP             USB_GPIO_D_MINUS_PIN
#define USB_DPP             USB_GPIO_D_PLUS_PIN

/*----------------------------------------------------------------------------*/
/* Definitions for operation*/
#define USB_DM_MSK          1 << USB_DMP
#define USB_DP_MSK          1 << USB_DPP
#define USB_MODE_IN         GPIO_EN_W1TC
#define USB_MODE_OUT        GPIO_EN_W1TS
#define USB_OUT_SET         GPIO_OUT_W1TS
#define USB_OUT_CLR         GPIO_OUT_W1TC
#define USB_IN              GPIO_IN
#define USB_OUT             GPIO_OUT
#define USB_DM_IO_MUX       (USB_DMP * 4) + GPIO_IO_MUX_BASE + 4
#define USB_DP_IO_MUX       (USB_DPP * 4) + GPIO_IO_MUX_BASE + 4

#define USB_D_MSK           USB_DM_MSK | USB_DP_MSK
#define USB_DIFF_1          USB_DP_MSK                // (D+)=1, (D-)=0
#define USB_DIFF_1_C        USB_DM_MSK                // (D+)=1, (D-)=0
#define USB_DIFF_0          USB_DM_MSK                // (D+)=0, (D-)=1
#define USB_DIFF_0_C        USB_DP_MSK                // (D+)=0, (D-)=1
#define USB_DATA_K          USB_DP_MSK                // State when DIFF_1
#define USB_DATA_J          USB_DM_MSK                // State when DIFF_0
#define USB_SE0             GPIO_OUT_W1TC             // (D+)=0, (D-)=0
#define USB_EOP             0


#if defined(USB_DEBUG_PIN)
  #define USB_DBG_MSK       (1 << USB_DEBUG_PIN)
#else
  #define USB_DBG_MSK       1 << 31
#endif

#endif /* __USB_CONF_H */
