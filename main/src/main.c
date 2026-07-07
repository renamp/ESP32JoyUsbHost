#include "main.h"

void taskUsb(void *pvParameters);

void app_main(void)
{
    xTaskCreate(taskUsb, "taskUsb", 1024, NULL, 1, NULL);
}


void taskUsb(void *pvParameters)
{
    printf("Task USB is running...\n");
    while(1) {
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
