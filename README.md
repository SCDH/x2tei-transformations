# x 2 TEI Transformations

This is an XSLT library for transforming various input formats to TEI-XML. Input formats include

- [USX](https://ubsicap.github.io/usx/) as used by *Deutsche
  Bibelgesellschaft*, currently transforming USX 3.0 documents to TEI
  P5
- [Accordance](https://www.accordancebible.com/) plain text files of
  books of the Bible to TEI P5
- docx

## Getting started

### Web UI

A user interface is online on the web:



### Local Deployment

Get dependencies and build:

```
./mvnw clean package
```

After running the following command in a terminal, the web UI locally
under
[http://localhost:8080/x2tei-transformations/index.html](http://localhost:8080/x2tei-transformations/index.html):

```
./mvnw jetty:run
```



