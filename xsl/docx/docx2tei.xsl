<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT for converting docx to TEI

This transformation has multiple entry points.
Most simply, you can call the initial template and pass a docx file to the 'input-file' stylesheet parameter!
Saxon's default collection finder will be used do unpack the docx file and parse the contained XML files.

USAGE:
java -jar saxon.jar -xsl:docx2tei.xsl -it input-file=YOUR.docx


alternative USAGE:
unzip your.docx -d your.d
java -jar saxon.jar -xsl:docx2tei.xsl -s:your.d/word/document.xml



The conversation is done in mode docx2t which is applied to file /word/document.xml by the entry points.
It expects a tunnel parameter named 'files' of type map(xs:string, document-node()) to be set, which maps the
paths of the documents in the docx file to document nodes of the parsed files.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xpath-default-namespace="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:output method="xml" indent="true"/>

    <!-- URI of/path to the docx file -->
    <xsl:param name="input-file" as="xs:anyURI?" select="()" required="false"/>

    <!-- list of files inside docx zip archive, absolute paths from archive root -->
    <xsl:param name="zipped-files" as="xs:string*" required="false"
        select="('/word/document.xml', '/word/footnotes.xml', '/word/styles.xml')"/>

    <!-- entry points -->

    <!-- initial template as entry point:
        USAGE:
        java -jar saxon.jar -xsl:docx2tei.xsl -it input-file=YOUR.docx
    -->
    <xsl:template name="xsl:initial-template">
        <xsl:if test="not($input-file)">
            <xsl:message terminate="yes">
                <xsl:text>You have to provide the stylesheet parameter 'input-file' if you call this transformation with the initial template 'xsl:initial-template'.</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="files" as="document-node()*"
            select="collection($input-file || '?on-error=ignore')"/>
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
        <xsl:apply-templates mode="docx2t" select="map:get($file-map, '/word/document.xml')">
            <xsl:with-param name="files" select="$file-map" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- enter conversion by passing in word/document.xml as source document
        USAGE:
        unzip your.docx -d your.d
        java -jar saxon.jar -xsl:docx2tei.xsl -s:your.d/word/document.xml
    -->
    <xsl:template match="document-node(element(w:document))">
        <xsl:variable name="file-map" as="map(xs:string, document-node())">
            <xsl:map>
                <xsl:map-entry key="'/word/document.xml'" select="."/>
                <xsl:variable name="base" select="base-uri(.)"/>
                <xsl:for-each select="$zipped-files[. ne '/word/document.xml']">
                    <!-- the relative path from document.xml will be used for finding the file -->
                    <xsl:variable name="rel-path" select="concat('..', .)"/>
                    <xsl:map-entry key="." select="resolve-uri($rel-path, $base) => doc()"/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>
        <xsl:apply-templates mode="docx2t" select=".">
            <xsl:with-param name="files" as="map(xs:string, document-node())" select="$file-map"
                tunnel="true"/>
        </xsl:apply-templates>
    </xsl:template>



    <!-- the mode docx2t does the conversion -->

    <xsl:mode name="docx2t" on-no-match="shallow-skip"/>

    <xsl:template mode="docx2t" match="w:document">
        <TEI>
            <xsl:call-template name="rootAttributes"/>
            <xsl:call-template name="teiHeader"/>
            <text>
                <body>
                    <xsl:apply-templates mode="#current"/>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template mode="docx2t" match="w:t/text()">
        <xsl:copy/>
    </xsl:template>

    <xsl:template mode="docx2t" match="w:p">
        <p>
            <xsl:apply-templates mode="#current"/>
        </p>
    </xsl:template>

    <xsl:template mode="docx2t" match="w:footnoteReference">
        <xsl:param name="files" as="map(xs:string, document-node())" tunnel="true"/>
        <xsl:variable name="id" select="@w:id"/>
        <note>
            <xsl:apply-templates mode="#current"
                select="map:get($files, '/word/footnotes.xml')//w:footnote[@w:id eq $id]"/>
        </note>
    </xsl:template>



    <!-- named templates for the header etc. -->

    <xsl:template name="rootAttributes" as="attribute()*">
        <!--xsl:attribute name="xml:base" select="base-uri(.)"/-->
    </xsl:template>

    <xsl:template name="teiHeader" as="element(tei:teiHeader)">
        <teiHeader>
            <xsl:call-template name="fileDesc"/>
            <xsl:call-template name="profileDesc"/>
            <xsl:call-template name="encodingDesc"/>
            <xsl:call-template name="revisionDesc"/>
        </teiHeader>
    </xsl:template>

    <xsl:template name="fileDesc" as="element(tei:fileDesc)">
        <fileDesc/>
    </xsl:template>

    <xsl:template name="encodingDesc" as="element(tei:encodingDesc)*"/>

    <xsl:template name="profileDesc" as="element(tei:profileDesc)*"/>

    <xsl:template name="revisionDesc">
        <revisionDesc>
            <change>
                <xsl:attribute name="who" select="system-property('user.name')"/>
                <xsl:attribute name="when"
                    select="current-dateTime() => format-dateTime('[Y]-[M]-[D]')"/>
                <xsl:text>Converted from </xsl:text>
                <ptr>
                    <xsl:attribute name="target" select="$input-file"/>
                </ptr>
                <xsl:text> using </xsl:text>
                <ptr>
                    <xsl:attribute name="target" select="static-base-uri()"/>
                </ptr>
                <xsl:text>.</xsl:text>
            </change>
        </revisionDesc>
    </xsl:template>

</xsl:stylesheet>
