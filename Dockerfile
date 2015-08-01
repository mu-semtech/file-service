FROM erikap/passenger-rails

ENV MU_APPLICATION_STORAGE_LOCATION /home/app/storage

RUN mkdir -p /home/app/storage \
        && echo "env MU_APPLICATION_STORAGE_LOCATION;\n" >> /etc/nginx/main.d/rails-env.conf \
        && echo "env MU_APPLICATION_GRAPH;\n" >> /etc/nginx/main.d/rails-env.conf

ADD . /home/app/webapp

RUN cd /home/app/webapp \
    && bundle install --deployment --without development test \
    && RAILS_ENV=production bundle exec rake assets:precompile \
    && mv /home/app/webapp/startup.sh /etc/my_init.d/file-service-startup.sh \
    && chmod +x /etc/my_init.d/*.sh

VOLUME /home/app/storage
