#ifndef TEST_MAIN_H
#define TEST_MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

void test_main(void);

extern uint16_t USB_crc16(uint16_t length, uint8_t *data);

extern void USB_AppendCRC5(uint8_t *data);

extern void Bytes2Rawdiff(uint16_t length, uint8_t *data,
                          void (*func)(uint16_t, uint8_t *));
                          
extern uint16_t Rawdiff2Bytes(uint16_t lenght, uint8_t *rawbits,
                              uint8_t *ptrOut);


#ifdef __cplusplus
}
#endif

#endif // TEST_MAIN_H
