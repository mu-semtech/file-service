FROM semtech/mu-ruby-template:2.14.0
LABEL maintainer="erika.pauwels@gmail.com"

ENV USE_LEGACY_UTILS 'false'
ENV MU_APPLICATION_FILE_STORAGE_PATH ''
ENV FILE_RESOURCE_BASE 'http://mu.semte.ch/services/file-service/files/'
