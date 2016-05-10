#!/bin/bash
chown -R app:app /data

echo "client_max_body_size ${MU_APPLICATION_MAX_FILE_SIZE};" >> /etc/nginx/conf.d/webapp.conf
