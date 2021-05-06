idf.py build && \
 scp build/dragon-cookie.bin root@xaseiresh.hopto.org:/var/esp_ota/dragon-cookie.bin && \
 mosquitto_pub -h xaseiresh.hopto.org -t /esp32/dragon-cookie/ota -m $(date +%s) -r && \
 mosquitto_sub -h xaseiresh.hopto.org -v -N -t "/esp32/dragon-cookie/+/logs"
