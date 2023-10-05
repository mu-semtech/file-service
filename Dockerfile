FROM semtech/mu-ruby-template:feature-ruby-3
LABEL maintainer="erika.pauwels@gmail.com"

ENV USE_LEGACY_UTILS 'false'
ENV MU_APPLICATION_FILE_STORAGE_PATH ''
ENV FILE_RESOURCE_BASE 'http://mu.semte.ch/services/file-service/files/'
