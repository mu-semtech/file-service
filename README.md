# Table of content

- [File-service](#file-service)
- [Installation](#installation)
  * [Docker-compose](#docker-compose)
  * [Dispatcher.ex](#dispatcherex)
- [Configuration](#configuration)
- [Models](#models)
  * [Logical File](#logical-file)
  * [Physical File](#physical-file)
  * [Resources](#resources)
- [Ontology & Prefixes](#ontology--prefixes)
- [Environment Variables](#environment-variables)
- [REST API](#rest-api)
- [Examples](#examples)
- [Upgrade from 2.x to 3.x](#upgrade-from-2x-to-3x)

# file-service
Microservice to upload and download files and store their file-specific metadata. <br>
Build using [https://github.com/mu-semtech/mu-ruby-template](https://github.com/mu-semtech/mu-ruby-template)

<br><br>
# Installation

## Docker-compose
Add the following snippet to your `docker-compose.yml` to include the file service in your project.

```yaml
file:
  image: semtech/mu-file-service:3.1.0
  links:
    - database:database
  volumes:
    - ./data/files:/share
```
## Dispatcher.ex
Add a rule to `dispatcher.ex` to dispatch all requests starting with `/files/` to the file service. E.g. 

```elixir
  match "/files/*path" do
    Proxy.forward conn, path, "http://file/files/"
  end
```
The host `file` in the forward URL reflects the name of the file service in the `docker-compose.yml` file.

More information how to setup a mu.semte.ch project can be found in [mu-project](https://github.com/mu-semtech/mu-project).

<br><br>
# Configuration
The triple store used in the backend is linked to the file service container as `database`. If you configure another SPARQL endpoint URL through `MU_SPARQL_ENDPOINT` update the link name accordingly. Make sure the file service is able to execute update queries against this store.

By default the file service stores the files in the root of the mounted volume `/share/`. You can configure the service to store the files in a mounted subfolder through the `MU_APPLICATION_FILE_STORAGE_PATH` environment variable. It must be a relative path to `/share/` in the Docker container. 

E.g.

```yaml
file:
  image: semtech/mu-file-service:3.1.0
  links:
    - database:database
  environment:
    MU_APPLICATION_FILE_STORAGE_PATH: "my-project/uploads/"
  volumes:
    - ./data/my-project/uploads:/share/my-project/uploads
   
```

<br><br>

# Models

## Logical File

![logicalFileStructure](https://user-images.githubusercontent.com/52280338/101150437-88636200-3620-11eb-9b21-b857b3a09f89.png)

## Physical File

![physicalFileStructure](https://user-images.githubusercontent.com/52280338/101150489-9c0ec880-3620-11eb-8d1f-c8d2323aa0ce.png)

## Resources
The file service represents an uploaded file as 2 resources in the triplestore: a resource reflecting the (virtual) uploaded file and another resource reflecting the resulting file stored on disk.

The uploaded file resource is of type `nfo:FileDataObject` and has the following properties:
* `nfo:fileName` (string): name of the uploaded file
* `dct:format` (string): MIME-type of the file
* `nfo:fileSize` (int): size of the file in bytes
* `dbpedia:fileExtension` (string): extension of the file
* `dct:created` (datetime): upload datetime

The resource representing the stored file is of type `nfo:FileDataObject` and has the following properties:
* `nfo:fileName` (string): name of the file as stored on disk
* `dct:format` (string): MIME-type of the file
* `nfo:fileSize` (int): size of the file in bytes
* `dbpedia:fileExtension` (string): extension of the file
* `dct:created` (datetime): storage datetime
* `nie:dataSource` (nfo:FileDataObject): uploaded file this file originates from

The URI of the stored file uses the `share://` protocol and reflects the location where the file resides as a relative path to the share folder. E.g. `share://uploads/my-file.pdf`.


<br><br>
# Ontology & Prefixes

This file-service is mainly build around the [Nepomuk File Ontology](https://www.semanticdesktop.org/ontologies/2007/03/22/nfo/)

| Prefix  | URI |
|---|---|
| nfo | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo# |
| nie | http://www.semanticdesktop.org/ontologies/2007/01/19/nie# |
| dct | http://purl.org/dc/terms/ |
| dbpedia | http://dbpedia.org/ontology/ |

<br> <br>

# Environment Variables

List of docker-compose service environment variables

| ENV  | Description | default | required |
|---|---|---|---|
| MU_APPLICATION_FILE_STORAGE_PATH | Mounted subfolder where you want to store your files. It must be a relative path to `/share/` in the Docker container  | None | |
| MU_SPARQL_ENDPOINT | SPARQL read endpoint URL  | http://database:8890/sparql | |
| MU_SPARQL_TIMEOUT | Timeout (in seconds) for SPARQL queries | 60 | |
| LOG_LEVEL | The level of logging. Options: debug, info, warn, error, fatal  | info | |
| MU_APPLICATION_GRAPH | Configuration of the graph in the triple store the microservice will work in.  | http://mu.semte.ch/application | |

<br><br>
# REST API

## POST /files
Upload a file. Accepts a `multipart/form-data` with a `file` parameter containing the uploaded file.

### Response
#### 201 Created
On successful upload with the newly created file in the response body:

```javascript
{
  "links": {
    "self": "files/b178ba66-206e-4551-b41e-4a46983912c0"
  },
  "data": {
    "type": "files",
    "id": "b178ba66-206e-4551-b41e-4a46983912c0",
    "attributes": {
        "name": "upload-name.pdf",
        "format": "application/pdf",
        "size": 1930
        "extension": "pdf"
    }
  }
}
```

#### 400 Bad Request
- if file param is missing.

## GET /files/:id
Get metadata of the file with the given id.

### Response
#### 200 OK
Returns the metadata of the file with the given id.

```javascript
{
  "links": {
    "self": "files/b178ba66-206e-4551-b41e-4a46983912c0"
  },
  "data": {
    "type": "files",
    "id": "b178ba66-206e-4551-b41e-4a46983912c0",
    "attributes": {
        "name": "upload-name.pdf",
        "format": "application/pdf",
        "size": 1930
        "extension": "pdf"
    }
  }
}
```

#### 404 Bad Request
If a file with the given id cannot be found.

## GET /files/:id/download
Download the content of the file with the given id.

### Query paramaters
* `name` (optional): name for the downloaded file (e.g. `/files/1/download?name=report.pdf`)

### Response

#### 200 Ok
Expected response, the file is returned.

#### 404 Bad Request
No file could be found with the given id.

#### 500 Server error
A file with the given id could be found in the database but not on disk.  This is most likely due to configuration issue on the server.


## DELETE /files/:id
Delete the file (metadata and content) with the given id.

### Response

#### 204 No Content
On successful delete.

<br><br>
# Examples
* To upload a file (assuming mu-dispatcher is running on localhost:80)
```
curl -i -X POST -H "Content-Type: multipart/form-data" -F "file=@/a/file.somewhere" http://localhost/files
```

<br><br>

## Integration with mu-cl-resources
If you want to model the files of the file service in the domain of your [mu-cl-resources](https://github.com/mu-semtech/mu-cl-resources) service, add the following to your `domain.lisp`:

```lisp
(define-resource file ()
  :class (s-prefix "nfo:FileDataObject")
  :properties `((:name :string ,(s-prefix "nfo:fileName"))
                (:format :string ,(s-prefix "dct:format"))
                (:size :number ,(s-prefix "nfo:fileSize"))
                (:extension :string ,(s-prefix "dbpedia:fileExtension"))
                (:created :datetime ,(s-prefix "nfo:fileCreated")))
  :has-one `((file :via ,(s-prefix "nie:dataSource")
                   :inverse t
                   :as "download"))
  :resource-base (s-url "http://data.example.com/files/")
  :features `(include-uri)
  :on-path "files")
```

And configure these prefixes in your `repository.lisp`:

```lisp
(add-prefix "nfo" "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
(add-prefix "nie" "http://www.semanticdesktop.org/ontologies/2007/01/19/nie#")
(add-prefix "dct" "http://purl.org/dc/terms/")
(add-prefix "dbpedia" "http://dbpedia.org/ontology/")
```

<br><br>
# Upgrade from 2.x to 3.x
To upgrade the file service from 2.x to 3.x a migration must be executed in the form of a SPARQL query.

If you use [mu-migrations-service](https://github.com/mu-semtech/mu-migrations-service) add the following SPARQL query in a `*.sparql` file in your migrations folder. Else directly execute the SPARQL query against the datastore. *Note: this will break support for file service 2.x!*

```
PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
PREFIX nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
PREFIX nie: <http://www.semanticdesktop.org/ontologies/2007/01/19/nie#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX dbpedia: <http://dbpedia.org/ontology/>

WITH <http://mu.semte.ch/application>
DELETE {
  ?uploadUri nfo:fileUrl ?fileUrl .
} INSERT {
  ?uploadUri dbpedia:fileExtension ?extension .
  ?fileUri a nfo:FileDataObject ;
    mu:uuid ?fileUuid ;
    nfo:fileName ?fileName ;
    dct:format ?format ;
    nfo:fileSize ?fileSize ;
    dbpedia:fileExtension ?extension ;
    dct:created ?created ;
    dct:modified ?modified ;
    nie:dataSource ?uploadUri .
} WHERE {
  ?uploadUri a nfo:FileDataObject ;
    nfo:fileName ?fileName ;
    dct:format ?format ;
    nfo:fileSize ?fileSize ;
    nfo:fileUrl ?fileUrl ; 
    dct:created ?created ;
    dct:modified ?modified .

  OPTIONAL { ?fileUrl mu:uuid ?id }
  BIND(IF(BOUND(?id), ?id, STRUUID()) as ?fileUuid)
  
  BIND(IRI(REPLACE(STR(?fileUrl), "file:///data/", "share://")) as ?fileUri)

  BIND(STRAFTER(?fileName, ".") as ?extension) 
}
```
