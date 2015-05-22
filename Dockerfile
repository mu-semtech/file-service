FROM erikap/passenger-rails

ENV MU_APPLICATION_STORAGE_LOCATION /home/app/storage

RUN mkdir -p /home/app/storage \
        && echo "env MU_APPLICATION_STORAGE_LOCATION;\n" >> /etc/nginx/main.d/rails-env.conf \
        && echo "env MU_APPLICATION_GRAPH;\n" >> /etc/nginx/main.d/rails-env.conf

ADD . /home/app/webapp

RUN mv /home/app/webapp/startup.sh /etc/my_init.d/file-manager-startup.sh \
        && chmod +x /etc/my_init.d/*.sh

VOLUME /home/app/storage
