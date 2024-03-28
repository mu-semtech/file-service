FROM semtech/mu-ruby-template:2.11.0
LABEL maintainer="erika.pauwels@gmail.com"

ENV MU_APPLICATION_FILE_STORAGE_PATH ''
ENV VALIDATE_READABLE_METADATA 'false'
ENV FILE_RESOURCE_BASE 'http://mu.semte.ch/services/file-service/files/'
