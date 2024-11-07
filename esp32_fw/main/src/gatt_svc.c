/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/* Includes */
#include "gatt_svc.h"
#include "common.h"
#include "temp_humid.h"

/* Private function declarations */
static int temperature_measurement_chr_access(uint16_t conn_handle, uint16_t attr_handle,
                                 struct ble_gatt_access_ctxt *ctxt, void *arg);

/* Private variables */

/* temp service */
static const ble_uuid16_t health_thermometer_svc_uuid = BLE_UUID16_INIT(0x1809);
// Union to hold the float as a 4-byte array
static union {
    float f;
    uint8_t bytes[4];
} temperature_union;
static uint8_t temperature_measurement_chr_val[4] = {0};
static uint16_t temperature_measurement_chr_val_handle;
static const ble_uuid16_t temperature_measurement_chr_uuid = BLE_UUID16_INIT(0x2A1C);
static uint16_t temperature_measurement_chr_conn_handle = 0;
static bool temperature_measurement_chr_conn_handle_inited = false;
static bool temperature_measurement_ind_status = false;

/* GATT services table */
static const struct ble_gatt_svc_def gatt_svr_svcs[] = {
    /* Temperature service */
    {.type = BLE_GATT_SVC_TYPE_PRIMARY,
     .uuid = &health_thermometer_svc_uuid.u,
     .characteristics =
         (struct ble_gatt_chr_def[]){
             {/* Heart rate characteristic */
              .uuid = &temperature_measurement_chr_uuid.u,
              .access_cb = temperature_measurement_chr_access,
              .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_INDICATE,
              .val_handle = &temperature_measurement_chr_val_handle},
             {
                 0, /* No more characteristics in this service. */
             }}},

    {
        0, /* No more services. */
    },
};

/* Private functions */
static int temperature_measurement_chr_access(uint16_t conn_handle, uint16_t attr_handle,
                                 struct ble_gatt_access_ctxt *ctxt, void *arg) {
    /* Local variables */
    int rc;

    ESP_LOGI(TAG, "temperature_measurement_chr_access conn_handle=%d attr_handle=%d", conn_handle, attr_handle);
    ESP_LOGI(TAG, "temperature_measurement_chr_val_handle=%d", temperature_measurement_chr_val_handle);
    /* Handle access events */
    /* Note: Heart rate characteristic is read only */
    switch (ctxt->op) {

    /* Read characteristic event */
    case BLE_GATT_ACCESS_OP_READ_CHR:
        /* Verify connection handle */
        if (conn_handle != BLE_HS_CONN_HANDLE_NONE) {
            ESP_LOGI(TAG, "characteristic read; conn_handle=%d attr_handle=%d",
                     conn_handle, attr_handle);
        } else {
            ESP_LOGI(TAG, "characteristic read by nimble stack; attr_handle=%d",
                     attr_handle);
        }

        /* Verify attribute handle */
                /* Verify attribute handle */
        if (attr_handle == temperature_measurement_chr_val_handle) {
            /* Update access buffer value */
            // Set the float value and copy it to the characteristic array
            temperature_union.f = get_temperature();
            ESP_LOGI(TAG, "temperature_union.f=%f", temperature_union.f);
            for (int i = 0; i < 4; i++) {
                temperature_measurement_chr_val[i] = temperature_union.bytes[i];
                ESP_LOGI(TAG, "i=%d chr_val=%d", i, temperature_union.bytes[i]);
            }
            rc = os_mbuf_append(ctxt->om, &temperature_measurement_chr_val,
                                sizeof(temperature_measurement_chr_val));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
        goto error;

    /* Unknown event */
    default:
        goto error;
    }

error:
    ESP_LOGE(
        TAG,
        "unexpected access operation to heart rate characteristic, opcode: %d",
        ctxt->op);
    return BLE_ATT_ERR_UNLIKELY;
}

/* Public functions */
void send_temperature_measurement_indication(void) {
    if (temperature_measurement_ind_status && temperature_measurement_chr_conn_handle_inited) {
        ble_gatts_indicate(temperature_measurement_chr_conn_handle,
                           temperature_measurement_chr_val_handle);
        ESP_LOGI(TAG, "Temperature indication sent!");
    }
}

/*
 *  Handle GATT attribute register events
 *      - Service register event
 *      - Characteristic register event
 *      - Descriptor register event
 */
void gatt_svr_register_cb(struct ble_gatt_register_ctxt *ctxt, void *arg) {
    /* Local variables */
    char buf[BLE_UUID_STR_LEN];
    //ESP_LOGI(TAG, "gatt_svr_register_cb op=%d", ctxt->op);

    /* Handle GATT attributes register events */
    switch (ctxt->op) {

    /* Service register event */
    case BLE_GATT_REGISTER_OP_SVC:
        ESP_LOGI(TAG, "registered service %s with handle=%d",
                 ble_uuid_to_str(ctxt->svc.svc_def->uuid, buf),
                 ctxt->svc.handle);
        break;

    /* Characteristic register event */
    case BLE_GATT_REGISTER_OP_CHR:
        ESP_LOGI(TAG,
                 "registering characteristic %s with "
                 "def_handle=%d val_handle=%d",
                 ble_uuid_to_str(ctxt->chr.chr_def->uuid, buf),
                 ctxt->chr.def_handle, ctxt->chr.val_handle);
        break;

    /* Descriptor register event */
    case BLE_GATT_REGISTER_OP_DSC:
        ESP_LOGI(TAG, "registering descriptor %s with handle=%d",
                 ble_uuid_to_str(ctxt->dsc.dsc_def->uuid, buf),
                 ctxt->dsc.handle);
        break;

    /* Unknown event */
    default:
        assert(0);
        break;
    }
    ESP_LOGI(TAG, "temp_val_handle=%d", temperature_measurement_chr_val_handle);
}

/*
 *  GATT server subscribe event callback
 *      1. Update heart rate subscription status
 */

void gatt_svr_subscribe_cb(struct ble_gap_event *event) {
    /* Check connection handle */
    if (event->subscribe.conn_handle != BLE_HS_CONN_HANDLE_NONE) {
        ESP_LOGI(TAG, "subscribe event; conn_handle=%d attr_handle=%d",
                 event->subscribe.conn_handle, event->subscribe.attr_handle);
    } else {
        ESP_LOGI(TAG, "subscribe by nimble stack; attr_handle=%d",
                 event->subscribe.attr_handle);
    }

    /* Check attribute handle */
    if (event->subscribe.attr_handle == temperature_measurement_chr_val_handle) {
        /* Update heart rate subscription status */
        temperature_measurement_chr_conn_handle = event->subscribe.conn_handle;
        temperature_measurement_chr_conn_handle_inited = true;
        temperature_measurement_ind_status = event->subscribe.cur_indicate;
    }
}

/*
 *  GATT server initialization
 *      1. Initialize GATT service
 *      2. Update NimBLE host GATT services counter
 *      3. Add GATT services to server
 */
int gatt_svc_init(void) {
    /* Local variables */
    int rc;

    /* 1. GATT service initialization */
    ble_svc_gatt_init();

    /* 2. Update GATT services counter */
    rc = ble_gatts_count_cfg(gatt_svr_svcs);
    if (rc != 0) {
        return rc;
    }

    /* 3. Add GATT services */
    rc = ble_gatts_add_svcs(gatt_svr_svcs);
    if (rc != 0) {
        return rc;
    }

    return 0;
}
