#!/bin/bash
chown -R app:app /home/app/storage

echo "client_max_body_size ${MU_APPLICATION_MAX_FILE_SIZE};" >> /etc/nginx/conf.d/webapp.conf
