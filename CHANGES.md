# Changes

## 0.7.0

- `xsl/docx/docx2tei.xsl`:
  - made reusable by downstream packages by providing initial template
    `docx2t:read-docx`
  - pass converted document through `docx2t:postproc` mode, which is
    the identity transformation and can be overwritten by downstream
    packages

## 0.6.4
- `xsl/usx/usx2tei.xsl`:
  - serialization property `indent="no"` fixes issue #6
  - using TEI's `@rendition` for formatting from the controled
    vocabulary of USX

## 0.6.3
- `xsl/usx/usx2tei-char-sigla.xsl`:
  - introduced new parameter for passing in a sequence of sigla groups as csv
  - unit tests
- `xsl/usx/usx2tei.xsl`:
  - fixed typo
  - unit tests

## 0.6.2
- `xsl/pagexml/pagecontent2tei.xsl`:
  - offer `p2t:post-proc` mode for running custom post processing
    transformations
  - separate templates for parts of the encoding description increase
    the re-useability

## 0.6.1

- `xsl/pagexml/pagecontent2tei.xsl`:
  - fixed visibility of components
  - minor fixes

## 0.6.0

- `xsl/pagexml/pagecontent2tei.xsl`:
  - use `<facsimile>` container for information about the image source
    as described in TEI guidelines, chapeter 11.1 and 11.2
  - use `@facs` on elements in the `<text>` container as links to
    facsimile, i.e. linking text and image sources
  - optionally use `@start` to link from facsimile to text elements

## 0.5.1

- `xsl/pagexml/pagecontent2tei.xsl`:
  - issue #1: fixed problems with importing xsl:initial-template in downstream packages
  - issue #2: use `TextLine/TextEquiv` when there are not `Word`
    elements present; added unit test with hsde test sample
  - issue #3: changed visibility of named template `p2t:tei-header` to
    *public*, so that downstream packages can provide their own header

## 0.5.0

- `xsl/pagexml/pagecontent2tei.xsl`:
  - option to keep line beginnings
  - option to keep words
  - option to include coordinates into a configurable attribute
  - simple and readable prefix for elements on a page: `p1.`, `p2.`,
    `p3.`, ...
  - `xml:id` on `<pb>`

## 0.4.0

- `xsl/pagexml/tei-pagexml-mapping.xsl` new:
  - generate a mapping from derived TEI back to PageXML preimage

## 0.3.3

- `xsl/pagexml/pagecontent2tei.xsl` new:
  - convert PageXML to TEI

## 0.2.1

- `xsl/docx/doxc2tei.xsl`:
  - All visible named components, that were in the null namespace, are
    now in the `docx2t` namespace.
  - do not reproduce paragraphs inside footnotes

## 0.2.0

- `xsl/docx/doxc2tei.xsl`:
  - The return types of the templates for the header parts are less
	strict now in order to allow XIncludes there.
  - A context type is declared for these same templates, so that
	downstream packages have a guarantee about the context.

## 0.1.0

- XSLT for transforming USX to TEI
- started with template for XSLT projects
