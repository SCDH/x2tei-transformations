<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT for converting docx to TEI

This transformation has multiple entry points.
Most simply, you can call the initial template and pass a docx file to the 'input-file' stylesheet parameter!
Saxon's default collection finder will be used do unpack the docx file and parse the contained XML files.

USAGE:
java -jar saxon.jar -xsl:docx2tei.xsl -it {http://scdh.wwu.de/transform/docx2tei#}input-file=YOUR.docx


alternative USAGE:
unzip your.docx -d your.d
java -jar saxon.jar -xsl:docx2tei.xsl -s:your.d/word/document.xml



The conversation is done in mode docx2t which is applied to file /word/document.xml by the entry points.
It expects a tunnel parameter named 'files' of type map(xs:string, document-node()) to be set, which maps the
paths of the documents in the docx file to document nodes of the parsed files.
-->
<xsl:package
    name="https://scdh.zivgitlabpages.uni-muenster.de/tei-processing/x2tei-transformations/xsl/docx/docx2tei.xsl"
    package-version="1.0.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:docx2t="http://scdh.wwu.de/transform/docx2tei#" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xpath-default-namespace="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="#all" version="3.1" default-mode="docx2t:source">

    <xsl:output method="xml" indent="true"/>

    <!-- URI of/path to the docx file -->
    <xsl:param name="docx2t:input-file" as="xs:anyURI?" select="()" required="false"/>

    <!-- list of files inside docx zip archive, absolute paths from archive root -->
    <xsl:param name="docx2t:zipped-files" as="xs:string*" required="false"
        select="('/word/document.xml', '/word/footnotes.xml', '/word/styles.xml')"/>

    <!-- XML ID of the user that does the file conversion -->
    <xsl:param name="docx2t:user-name" as="xs:string?" select="system-property('user.name')"/>

    <!-- the name of the transformer, used in revision description -->
    <xsl:variable name="docx2t:stylesheet" as="xs:string" select="static-base-uri()"
        visibility="public"/>

    <!-- entry points -->

    <!-- initial template as entry point:
        USAGE:
        java -jar saxon.jar -xsl:docx2tei.xsl -it input-file=YOUR.docx
    -->
    <xsl:template name="xsl:initial-template" visibility="final">
        <xsl:if test="not($docx2t:input-file)">
            <xsl:message terminate="yes">
                <xsl:text>You have to provide the stylesheet parameter 'input-file' if you call this transformation with the initial template 'xsl:initial-template'.</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="files" as="document-node()*"
            select="collection($docx2t:input-file || '?on-error=ignore')"/>
        <xsl:message use-when="true() or system-property('debug') eq 'true'">
            <xsl:text>Input collection: </xsl:text>
            <xsl:for-each select="$files">
                <xsl:text>&#xa;  </xsl:text>
                <xsl:value-of select="base-uri(.)"/>
            </xsl:for-each>
        </xsl:message>
        <xsl:variable name="file-map" as="map(xs:string, document-node())">
            <xsl:map>
                <xsl:for-each select="$files">
                    <xsl:map-entry key="(base-uri(.) => tokenize('!'))[2]" select="."/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>
        <xsl:apply-templates mode="docx2t:convert" select="map:get($file-map, '/word/document.xml')">
            <xsl:with-param name="files" select="$file-map" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:mode name="docx2t:source" on-no-match="fail" visibility="final"/>

    <!-- enter conversion by passing in word/document.xml as source document
        USAGE:
        unzip your.docx -d your.d
        java -jar saxon.jar -xsl:docx2tei.xsl -s:your.d/word/document.xml
    -->
    <xsl:template mode="docx2t:source" match="document-node(element(w:document))">
        <xsl:variable name="file-map" as="map(xs:string, document-node())">
            <xsl:map>
                <xsl:map-entry key="'/word/document.xml'" select="."/>
                <xsl:variable name="base" select="base-uri(.)"/>
                <xsl:for-each select="$docx2t:zipped-files[. ne '/word/document.xml']">
                    <!-- the relative path from document.xml will be used for finding the file -->
                    <xsl:variable name="rel-path" select="concat('..', .)"/>
                    <xsl:variable name="uri" as="xs:anyURI" select="resolve-uri($rel-path, $base)"/>
                    <xsl:if test="doc-available($uri)">
                        <xsl:map-entry key="." select="doc($uri)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>
        <xsl:apply-templates mode="docx2t:convert" select=".">
            <xsl:with-param name="files" as="map(xs:string, document-node())" select="$file-map"
                tunnel="true"/>
        </xsl:apply-templates>
    </xsl:template>



    <!-- the mode docx2t does the conversion -->

    <xsl:mode name="docx2t:convert" on-no-match="shallow-skip" visibility="public"/>

    <xsl:template mode="docx2t:convert" match="w:document">
        <TEI>
            <xsl:call-template name="docx2t:rootAttributes"/>
            <xsl:call-template name="docx2t:teiHeader"/>
            <text>
                <body>
                    <xsl:apply-templates mode="#current"/>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template mode="docx2t:convert" match="w:t/text()">
        <xsl:copy/>
    </xsl:template>

    <xsl:template mode="docx2t:convert" match="w:p">
        <p>
            <xsl:apply-templates mode="#current"/>
        </p>
    </xsl:template>

    <xsl:template mode="docx2t:convert" match="w:footnoteReference">
        <xsl:param name="files" as="map(xs:string, document-node())" tunnel="true"/>
        <xsl:variable name="id" select="@w:id"/>
        <note>
            <xsl:apply-templates mode="#current"
                select="map:get($files, '/word/footnotes.xml')//w:footnote[@w:id eq $id]"/>
        </note>
    </xsl:template>



    <!-- named templates for the header etc. -->

    <xsl:template name="docx2t:rootAttributes" as="attribute()*" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
        <!--xsl:attribute name="xml:base" select="base-uri(.)"/-->
    </xsl:template>

    <xsl:template name="docx2t:teiHeader" as="element(tei:teiHeader)" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
        <teiHeader>
            <xsl:call-template name="docx2t:fileDesc"/>
            <xsl:call-template name="docx2t:profileDesc"/>
            <xsl:call-template name="docx2t:encodingDesc"/>
            <xsl:call-template name="docx2t:revisionDesc"/>
        </teiHeader>
    </xsl:template>

    <xsl:template name="docx2t:fileDesc" as="element()?" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
        <fileDesc/>
    </xsl:template>

    <xsl:template name="docx2t:encodingDesc" as="element()*" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
    </xsl:template>

    <xsl:template name="docx2t:profileDesc" as="element()*" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
    </xsl:template>

    <xsl:template name="docx2t:revisionDesc" as="element()*" visibility="public">
        <xsl:context-item as="element(w:document)" use="required"/>
        <revisionDesc>
            <change>
                <xsl:if test="$docx2t:user-name and $docx2t:user-name ne ''">
                    <xsl:attribute name="who" select="'#' || $docx2t:user-name"/>
                </xsl:if>
                <xsl:attribute name="when"
                    select="current-dateTime() => format-dateTime('[Y0001]-[M01]-[D01]')"/>
                <xsl:text>Converted from </xsl:text>
                <ptr>
                    <xsl:choose>
                        <xsl:when test="$docx2t:input-file">
                            <xsl:attribute name="target" select="$docx2t:input-file"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="target" select="base-uri(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </ptr>
                <xsl:text> using </xsl:text>
                <ptr>
                    <xsl:attribute name="target" select="$docx2t:stylesheet"/>
                </ptr>
                <xsl:text>.</xsl:text>
            </change>
        </revisionDesc>
    </xsl:template>

</xsl:package>
