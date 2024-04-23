# Changes

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
