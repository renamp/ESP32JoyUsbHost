#include "unity.h"
#include "main.h"
#include "test_main.h"


void test_USB_crc16_with_setup_data()
{
    uint8_t data[] = {0xc3,0x80,0x06,0x00,0x01,0x00,0x00,0x40,0x00};
    TEST_ASSERT_EQUAL_HEX16(0x94DD, USB_crc16(9, data));
}

void test_USB_AppendCRC5_noPid_addr0_endpont0()
{
    uint8_t data[] = {0, 0, 0};
    uint8_t expected[] = {0, 0, 0x10};
    
    USB_AppendCRC5(data);
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, data, 3);
}

void test_USB_AppendCRC5_noPid_addr5_endpont0()
{
    uint8_t data[] = {0, 0x05, 0};
    uint8_t expected[] = {0, 0x05, 0xD0};

    USB_AppendCRC5(data);
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, data, 3);
}

void test_USB_AppendCRC5_noPid_addr5_endpont1()
{
    uint8_t data[] = {0, 0x85, 0};
    uint8_t expected[] = {0, 0x85, 0x60};

    USB_AppendCRC5(data);
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, data, 3);
}

void test_USB_AppendCRC5_Pid_addr5_endpont1()
{
    uint8_t data[] = {0x69, 0x85, 0};
    uint8_t expected[] = {0x69, 0x85, 0x60};

    USB_AppendCRC5(data);
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, data, 3);
}

void test_Bytes2Rawdiff_func_to_receive_rawdiff(
                                        uint16_t length, uint8_t *ptrData)
{
    TEST_ASSERT_EQUAL_INT(80, length);

     uint8_t expected[] = {0x66, 0x66, 0x69, 0x99, 0x99, 0x99, 0x99, 0x99, 
                           0x99, 0x99, 0x66, 0x66, 0x66, 0x6A, 0x59, 0x99, 
                           0xA9, 0x9A, 0xA6, 0x66};
    uint8_t *base_ptr = ptrData - 19;
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, base_ptr, 20);
}
void test_Bytes2Rawdiff_with_data_packet()
{
    uint8_t data[] = {0xc3,0x80,0x06,0x00,0x01,0x00,0x00,0x40,0x00};
    Bytes2Rawdiff(9, data, test_Bytes2Rawdiff_func_to_receive_rawdiff);
}

void test_Rawdiff2Bytes_with_data_packet()
{
    uint8_t rawdiff[] = {0x66, 0x66, 0x69, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99,
                         0x99, 0x66, 0x66, 0x66, 0x6A, 0x59, 0x99, 0xA9, 0x9A,
                         0xA6, 0x66};
    uint8_t expected[] = {0x81,0xc3,0x80,0x06,0x00,0x01,0x00,0x00,0x40,0x00};
    uint8_t *ptr_base = rawdiff + 19;
    uint8_t ptrOut[20];
    uint16_t length = Rawdiff2Bytes(80, ptr_base, ptrOut);

    TEST_ASSERT_EQUAL_INT(10, length);
    TEST_ASSERT_EQUAL_HEX8_ARRAY(expected, ptrOut, 10);
}

int app_main(void)
{
    UNITY_BEGIN();

    RUN_TEST(test_USB_crc16_with_setup_data);
    RUN_TEST(test_USB_AppendCRC5_noPid_addr0_endpont0);
    RUN_TEST(test_USB_AppendCRC5_noPid_addr5_endpont0);
    RUN_TEST(test_USB_AppendCRC5_noPid_addr5_endpont1);
    RUN_TEST(test_USB_AppendCRC5_Pid_addr5_endpont1);
    RUN_TEST(test_Bytes2Rawdiff_with_data_packet);
    RUN_TEST(test_Rawdiff2Bytes_with_data_packet);
//    UNITY_END();
    printf("DONE.\n");
    
    while(1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
    return 0;
}
