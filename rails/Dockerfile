FROM ruby:2.5

ENV MU_SPARQL_ENDPOINT http://database:8890/sparql
ENV MU_APPLICATION_GRAPH http://mu.semte.ch/application
ENV MU_APPLICATION_STORAGE_LOCATION /data
ENV MU_APPLICATION_MAX_FILE_SIZE 20M

RUN mkdir -p /data 

COPY . /home/app/webapp
WORKDIR /home/app/webapp

RUN bundle install --deployment --without development test \
    && RAILS_ENV=production bundle exec rake assets:precompile

CMD ["rails", "server","-e","production", "-b", "0.0.0.0", "-p", "80"]