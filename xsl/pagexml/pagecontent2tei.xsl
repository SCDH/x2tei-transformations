<?xml version="1.0" encoding="UTF-8"?>
<!-- Transform PageXML to TEI

USAGE:

java -jar saxon.jar -xsl:xsl/pagexml/pagecontent2tei.xsl -s:test/samples/pagexml_chronicle/0007_p007.xml

USAGE for joining all page xml files from a folder using a file pattern:
target/bin/xslt.sh -xsl:xsl/pagexml/pagecontent2tei.xsl -it {http://scdh.wwu.de/transform/pagexml2tei#}collection-uri=../../test/samples/pagexml_chronicle?select=*_p*.xml

USAGE with a collection catalog:
target/bin/xslt.sh -xsl:xsl/pagexml/pagecontent2tei.xsl -it:{http://scdh.wwu.de/transform/pagexml2tei#}collection {http://scdh.wwu.de/transform/pagexml2tei#}collection-uri=../../test/samples/pagexml_chronicle/collection.xml

or with an absolute path gotten by the realpath shell program:

target/bin/xslt.sh -xsl:xsl/pagexml/pagecontent2tei.xsl -it:{http://scdh.wwu.de/transform/pagexml2tei#}collection {http://scdh.wwu.de/transform/pagexml2tei#}collection-uri=$(realpath test/samples/pagexml_chronicle/collection.xml)

See also:
Collection URIs: https://www.saxonica.com/documentation12/index.html#!sourcedocs/collections/collection-directories
Collection Catalogs: https://www.saxonica.com/documentation12/index.html#!sourcedocs/collections/collection-catalogs

-->
<xsl:package
    name="https://scdh.zivgitlabpages.uni-muenster.de/tei-processing/x2tei-transformations/xsl/pagexml/pagecontent2tei.xsl"
    package-version="1.0.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:p2t="http://scdh.wwu.de/transform/pagexml2tei#"
    xmlns:pc="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    exclude-result-prefixes="#all" version="3.0" default-mode="p2t:source">

    <xsl:output method="xml" indent="true" encoding="UTF-8"/>

    <!-- whether or not to include metadata from the pagexml header -->
    <xsl:param name="p2t:with-metadata" as="xs:boolean" select="true()"/>

    <!-- whether or not to join pages -->
    <xsl:param name="p2t:join-pages" as="xs:boolean" select="true()"/>

    <!-- collection URI when started with xsl:initial-template or
        a URI of a collection catalog when started with p2t:collection -->
    <xsl:param name="p2t:collection-uri" as="xs:anyURI"/>

    <!-- string serialization of a collection catalog -->
    <xsl:param name="p2t:collection" as="xs:string"/>

    <!-- Use this initial template to transform all documents found in a directory.
        @seed:it@ -->
    <xsl:template name="xsl:initial-template" visibility="public">
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>Input Collection: </xsl:text>
            <xsl:value-of select="uri-collection($p2t:collection-uri)"/>
        </xsl:message>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="collection($p2t:collection-uri)"/>
        </xsl:call-template>
    </xsl:template>

    <!--
        If there is no collection finder supplied, use this start template which reads a saxon collection file.
        Cf. https://www.saxonica.com/documentation11/index.html#!sourcedocs/collections/collection-catalogs
        @seed:it@
    -->
    <xsl:template name="p2t:collection" visibility="final">
        <xsl:variable name="documents" as="document-node()*">
            <xsl:variable name="col" as="document-node()" select="doc($p2t:collection-uri)"/>
            <xsl:for-each select="$col/*:collection/*:doc/@href">
                <xsl:sequence select="doc(resolve-uri(., base-uri($col)))"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="$documents"/>
        </xsl:call-template>
    </xsl:template>

    <!-- an initial template for the frontend which passed in a collection as a string
        @seed:it@ @front:it@
    -->
    <xsl:template name="p2t:collection-string" visibility="final">
        <!-- ??? xsl:param name="collection" as="xs:string"/-->
        <xsl:variable name="documents">
            <xsl:variable name="col" as="document-node()" select="parse-xml($p2t:collection)"/>
            <xsl:for-each select="$col/*:collection/*:doc/@href">
                <xsl:sequence select="doc(resolve-uri(., base-uri($col)))"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="$documents"/>
        </xsl:call-template>
    </xsl:template>

    <!-- The p2t:source mode is the initial mode to be used when applying
        this stylesheet to a single pagexml source file.
        @seed:im@
    -->
    <xsl:mode name="p2t:source" on-no-match="fail" visibility="final"/>

    <xsl:template mode="p2t:source" match="document-node()">
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="."/>
            <xsl:with-param name="single-source" as="xs:boolean" select="true()" tunnel="true"/>
        </xsl:call-template>
    </xsl:template>


    <!-- a common entry point used by initial templates and the initial p2t:source mode -->
    <xsl:template name="tei-template" visibility="final">
        <xsl:param name="pages" as="document-node()*"/>
        <TEI>
            <xsl:call-template name="p2t:tei-header">
                <xsl:with-param name="pages" as="node()*" select="$pages"/>
            </xsl:call-template>
            <text>
                <body>
                    <div>
                        <!-- first pass with mode flat-regions which flattens regions (paragraphs) to a
                            milestone markup which can be upcycled again in the second pass. -->
                        <xsl:variable name="flat-regions">
                            <xsl:apply-templates select="$pages" mode="page">
                                <!-- assert, that the collection is ordered lexically by file name -->
                                <!--xsl:sort select="base-uri()"/-->
                            </xsl:apply-templates>
                        </xsl:variable>
                        <!--xsl:apply-templates select="$flat-regions/node()" mode="text-regions"/-->
                        <!-- second pass: upcycled region milestones to paragraphs, but only when they
                            result from real paragraphs, not from page breaks (a page in pagexml
                            always starts with a new region). -->
                        <xsl:variable name="with-paragraphs">
                            <xsl:for-each-group select="$flat-regions/node()"
                                group-starting-with="TextRegionStart[not(preceding::node()[1][self::tei:pb])]">
                                <p>
                                    <xsl:apply-templates mode="text-regions"
                                        select="current-group()"/>
                                </p>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <!-- third/final pass -->
                        <xsl:apply-templates mode="p-joiner" select="$with-paragraphs"/>
                        <xsl:text>&#xa;</xsl:text>
                    </div>
                </body>
            </text>
        </TEI>
    </xsl:template>


    <!-- named templates for making the header -->

    <xsl:template name="p2t:tei-header">
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


    <!-- page is the mode is a first pass -->
    <xsl:mode name="page" on-no-match="shallow-skip"/>

    <xsl:template mode="page" match="Metadata"/>

    <xsl:template mode="page" match="Page">
        <xsl:param name="single-source" as="xs:boolean" select="false()" tunnel="true"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:if test="not($p2t:join-pages) and not($single-source)">
            <pc:TextRegionStart/>
        </xsl:if>
        <pb>
            <xsl:if test="$p2t:with-metadata">
                <xsl:attribute name="pc:imageFilename" select="@imageFilename"/>
                <xsl:attribute name="pc:source" select="tokenize(base-uri(.), '/')[last()]"/>
            </xsl:if>
        </pb>
        <xsl:if test="not($p2t:join-pages) or $single-source">
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


    <!-- text-regions is the mode for the second pass -->
    <xsl:mode name="text-regions" on-no-match="shallow-copy"/>

    <xsl:template mode="text-regions" match="TextRegionStart"/>


    <!-- p-joiner is the mode for the third pass -->
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

</xsl:package>
