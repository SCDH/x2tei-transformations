<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:pc="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    exclude-result-prefixes="xs" version="3.0">

    <xsl:output method="xml" indent="true" encoding="UTF-8"/>

    <xsl:param name="with-metadata" as="xs:boolean" select="true()"/>

    <xsl:param name="join-pages" as="xs:boolean" select="true()"/>

    <xsl:param name="dir" as="xs:string*" select="''"/>

    <xsl:param name="collection" as="xs:string"/>

    <!-- Use this initial template to transform all documents found in a directory -->
    <xsl:template name="xsl:initial-template">
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>Input Collection: </xsl:text>
            <xsl:value-of select="$dir"/>
        </xsl:message>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="collection($dir)"/>
        </xsl:call-template>
    </xsl:template>

    <!--
        If there is no collection finder supplied, use this start template which reads a saxon collection file.
        Cf. https://www.saxonica.com/documentation11/index.html#!sourcedocs/collections/collection-catalogs
    -->
    <xsl:template name="collection">
        <xsl:variable name="documents">
            <xsl:variable name="col" as="document-node()" select="doc($collection)"/>
            <xsl:for-each select="$col/*:collection/*:doc/@href">
                <xsl:sequence select="doc(resolve-uri(., base-uri($col)))"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="$documents"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="collection-string">
        <xsl:param name="collection" as="xs:string"/>
        <xsl:variable name="documents">
            <xsl:variable name="col" as="document-node()" select="parse-xml($collection)"/>
            <xsl:for-each select="$col/*:collection/*:doc/@href">
                <xsl:sequence select="doc(resolve-uri(., base-uri($col)))"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="$documents"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="tei-template">
        <xsl:param name="pages" as="node()*"/>
        <TEI>
            <xsl:call-template name="tei-header">
                <xsl:with-param name="pages" as="node()*" select="$pages"/>
            </xsl:call-template>
            <text>
                <body>
                    <div>
                        <xsl:variable name="flat-regions">
                            <xsl:apply-templates select="$pages" mode="page">
                                <!-- assert, that the collection is ordered lexically by file name -->
                                <xsl:sort select="base-uri()"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <!--xsl:apply-templates select="$flat-regions/node()" mode="text-regions"/-->
                        <xsl:variable name="with-paragraphs">
                            <xsl:for-each-group select="$flat-regions/node()"
                                group-starting-with="TextRegionStart[not(preceding::node()[1][self::tei:pb])]">
                                <p>
                                    <xsl:apply-templates mode="text-regions"
                                        select="current-group()"/>
                                </p>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:apply-templates mode="p-joiner" select="$with-paragraphs"/>
                        <xsl:text>&#xa;</xsl:text>
                    </div>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template name="tei-header">
        <xsl:param name="pages" as="node()*"/>
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>TODO</title>
                </titleStmt>
                <publicationStmt>
                    <p>TODO</p>
                </publicationStmt>
                <sourceDesc>
                    <p>Created with Transkribus</p>
                    <p>
                        <xsl:value-of select="($pages//Metadata/Creator)[1]"/>
                    </p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
    </xsl:template>

    <xsl:template match="/">
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" as="node()" select="/*"/>
            <xsl:with-param name="single-source" as="xs:boolean" select="true()" tunnel="true"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:mode name="page" on-no-match="shallow-skip"/>

    <xsl:template mode="page" match="Metadata"/>

    <xsl:template mode="page" match="Page">
        <xsl:param name="single-source" as="xs:boolean" select="false()" tunnel="true"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:if test="not($join-pages) and not($single-source)">
            <pc:TextRegionStart/>
        </xsl:if>
        <pb>
            <xsl:if test="$with-metadata">
                <xsl:attribute name="pc:imageFilename" select="@imageFilename"/>
                <xsl:attribute name="pc:source" select="tokenize(base-uri(.), '/')[last()]"/>
            </xsl:if>
        </pb>
        <xsl:if test="not($join-pages) or $single-source">
            <pc:TextRegionStart/>
        </xsl:if>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="TextRegion">
        <!-- 
            In order to join paragraphs that join pages we do not wrap the content of ta TextRegion into tei:p
            but add a flat TextRegionStart and use a second pass and xsl:for-each-group 
        -->
        <pc:TextRegionStart/>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="TextLine">
        <xsl:text>&#xa;</xsl:text>
        <lb xml:id="{@id}"/>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="TextLine/TextEquiv"/>

    <xsl:template mode="page" match="Word[position() > 1]">
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="Word[1]">
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <!-- drop white space text nodes -->
    <xsl:template mode="page" match="text()[normalize-space(.) eq '']" priority="2"/>

    <xsl:template mode="page" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>



    <xsl:mode name="text-regions" on-no-match="shallow-copy"/>

    <xsl:template mode="text-regions" match="TextRegionStart"/>



    <xsl:mode name="p-joiner" on-no-match="shallow-copy"/>

    <xsl:template mode="p-joiner" match="tei:p[child::tei:pb and normalize-space(.) eq '']">
        <xsl:copy-of select="tei:pb"/>
    </xsl:template>

    <xsl:template mode="p-joiner" match="tei:pb">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="n" select="count(preceding::tei:pb) + 1"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
