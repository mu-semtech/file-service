# File microservice
File microservice to store files and their file-specific metadata

## Running the file microservice
    docker run --name mu-file-service \
        -p 80:80 \
        --link my-triple-store:database \
        -v /path/to/storage:/data \
        -e SECRET_KEY_BASE=my-secret-production-key-for-rails \ 
        -d semtech/mu-file-service

The triple store used in the backend is linked to the login service container as `database`. If you configure another SPARQL endpoint URL through `MU_SPARQL_ENDPOINT` update the link name accordingly. Make sure the file service is able to execute update queries against this store.

The file service stores the files in the mounted volume `/data`. The maximum allowed file size can be configured through the `MU_APPLICATION_MAX_FILE_SIZE` environment variable (default: `20M`).

The `MU_APPLICATION_GRAPH` environment variable (default: `http://mu.semte.ch/application`) specifies the graph in the triple store the file service will work in.

The `SECRET_KEY_BASE` environment variable is used by Rails to verify the integrity of signed cookies.
