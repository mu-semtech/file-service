#!/bin/bash
chown -R app:app /data

sed -i '/client_max_body_size/d' /etc/nginx/conf.d/webapp.conf
echo "client_max_body_size ${MU_APPLICATION_MAX_FILE_SIZE};" >> /etc/nginx/conf.d/webapp.conf
