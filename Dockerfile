FROM erikap/passenger-rails

ENV MU_SPARQL_ENDPOINT http://database:8890/sparql
ENV MU_APPLICATION_GRAPH http://mu.semte.ch/application
ENV MU_APPLICATION_STORAGE_LOCATION /data
ENV MU_APPLICATION_MAX_FILE_SIZE 20M

RUN mkdir -p /data \
        && echo "env MU_APPLICATION_STORAGE_LOCATION;\n" >> /etc/nginx/main.d/rails-env.conf \
        && echo "env MU_SPARQL_ENDPOINT;\n" >> /etc/nginx/main.d/rails-env.conf \
        && echo "env MU_APPLICATION_GRAPH;\n" >> /etc/nginx/main.d/rails-env.conf \
        && echo "chunked_transfer_encoding off;\n" >> /etc/nginx/conf.d/webapp.conf \
        && echo "client_max_body_size ${MU_APPLICATION_MAX_FILE_SIZE};\n" >> /etc/nginx/conf.d/webapp.conf

COPY . /home/app/webapp

RUN cd /home/app/webapp \
    && bundle install --deployment --without development test \
    && RAILS_ENV=production bundle exec rake assets:precompile \
    && mv /home/app/webapp/startup.sh /etc/my_init.d/file-service-startup.sh \
    && chmod +x /etc/my_init.d/*.sh

VOLUME /data
