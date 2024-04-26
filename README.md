# x 2 TEI Transformations

This is an XSLT library for transforming various input formats to TEI-XML. Input formats include

- [USX](https://ubsicap.github.io/usx/) as used by *Deutsche
  Bibelgesellschaft*, currently transforming USX 3.0 documents to TEI
  P5: [XSLT](xsl/usx) [Wiki](../../wikis/usx)
- [Accordance](https://www.accordancebible.com/) plain text files of
  books of the Bible to TEI P5: [XSLT](xsl/accordance) [Wiki](../../wikis/accordance)
- docx: [XSLT](xsl/docx) [Wiki](../../wikis/docx)
- PageXML: [XSLT](xsl/pagexml) [Wiki](../../wikis/pagexml)

## Getting started

Usage notes on the transformation can be found in the comments at the
beginning of the xsl files in the [`xsl`](xsl) folder.

Operators also provide
[Wiki](https://zivgitlab.uni-muenster.de/SCDH/tei-processing/seed-xml-transformer-scdh-instance/-/wikis/home)
entries on the usage.

This project uses
[Tooling](https://zivgitlab.uni-muenster.de/SCDH/tei-processing/tooling)
for *simple*, *extensible* and *reproducible* download of tools for
using the project's components.

To get Saxon for using this project's transformation simply run:

```
./mvnw package
```

After this, you have a nice wrapper script in `target/bin/xslt.sh`

```
target/bin/xslt.sh -?
Saxon-HE 10.9J from Saxonica
Usage: see http://www.saxonica.com/documentation/index.html#!using-xsl/commandline
Format: net.sf.saxon.Transform options params
Options available: -? -a -catalog -config -cr -diag -dtd -ea -expand -explain -export -ext -im -init -it -jit -l -lib -license -m -nogo -now -ns -o -opt -or -outval -p -quit -r -relocate -repeat -s -sa -scmin -strip -t -T -target -TB -threads -TJ -Tlevel -Tout -TP -traceout -tree -u -val -versionmsg -warnings -x -xi -xmlversion -xsd -xsdversion -xsiloc -xsl -y --?
Use -XYZ:? for details of option XYZ
Params:
  param=value           Set stylesheet string parameter
  +param=filename       Set stylesheet document parameter
  ?param=expression     Set stylesheet parameter using XPath
  !param=value          Set serialization parameter
```

The usage notes in the beginning of the XSLT transformations assume
that this tooling is used.


## Web Interface

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
