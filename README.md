# File microservice
File microservice to store files and their file-specific metadata

## Running the file microservice
    docker run --name mu-file-service \
        -p 80:80 \
        --link my-triple-store:database \
        -v /path/to/storage:/home/app/storage \
        -e MU_APPLICATION_GRAPH=http://mu.semte.ch/app \
        -e SECRET_KEY_BASE=my-secret-production-key-for-rails \ 
        -d semtech/mu-file-service

The triple store used in the backend is linked to the login service container as `database`. If you configure another SPARQL endpoint URL through `MU_SPARQL_ENDPOINT` update the link name accordingly. Make sure the login service is able to execute update queries against this store.

The file service stores the files in the mounted volume `/home/app/storage`.

The `MU_APPLICATION_GRAPH` environment variable specifies the graph in the triple store the file service will work in.

The `SECRET_KEY_BASE` environment variable is used by Rails to verify the integrity of signed cookies.
