# File manager microservice
File manager microservice to store files and their file-specific metadata

## Running the file manager microservice
    docker run --name mu-file-manager \
        -p 80:80 \
        --link my-triple-store:database \
        -v /path/to/storage:/home/app/storage \
        -e MU_APPLICATION_GRAPH=http://mu.semte.ch/app \
        -e SECRET_KEY_BASE=my-secret-production-key-for-rails \ 
        -d semtech/mu-file-manager

The triple store used in the backend is linked to the file manager service container as `database`. Make sure the file manager service is able to execute update queries against this store.

The file manager stores the files in the mounted volume `/home/app/storage`.

The `MU_APPLICATION_GRAPH` environment variable specifies the graph in the triple store the file manager service will work in.

The `SECRET_KEY_BASE` environment variable is used by Rails to verify the integrity of signed cookies.
