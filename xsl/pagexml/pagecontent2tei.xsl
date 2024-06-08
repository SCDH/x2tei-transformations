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

    <!-- whether or not to add @facs attribute to text elements -->
    <xsl:param name="p2t:with-facsimile" as="xs:boolean" select="true()"/>

    <!-- whether or not to add @start attribute to facsimile elements -->
    <xsl:param name="p2t:with-start" as="xs:boolean" select="true()"/>

    <!-- whether ot not to add @xml:id attributes to text elements -->
    <xsl:param name="p2t:with-text-ids" as="xs:boolean" select="true()"/>

    <!-- say p2t:only="'text'" or "'facsimile'" to only output facsimile or text -->
    <xsl:param name="p2t:only" as="xs:string?" select="()"/>

    <!-- whether or not to join pages -->
    <xsl:param name="p2t:join-pages" as="xs:boolean" select="true()"/>

    <!-- whether or not to have &lt;lb>, i.e., line beginnings -->
    <xsl:param name="p2t:lb" as="xs:boolean" select="true()"/>

    <!-- whether or not to move &lt;lb>, i.e., line beginnings, to the end of the previous line -->
    <xsl:param name="p2t:lb-at-eol" as="xs:boolean" select="false()"/>

    <!-- whether or not to keep words -->
    <xsl:param name="p2t:words" as="xs:boolean" select="false()"/>

    <!-- collection URI when started with xsl:initial-template or
        a URI of a collection catalog when started with p2t:collection -->
    <xsl:param name="p2t:collection-uri" as="xs:anyURI"/>

    <!-- string serialization of a collection catalog -->
    <xsl:param name="p2t:collection" as="xs:string"/>

    <!-- the match part of how to make facs links -->
    <xsl:param name="p2t:facs-prefix-match" as="xs:string" select="'(.*)'"/>

    <!-- the replacement part of how to make facs links -->
    <xsl:param name="p2t:facs-prefix-replacement" as="xs:string"
        select="'https://facsimiles.your.com/$1'"/>

    <!-- the match part of how to make facs links -->
    <xsl:param name="p2t:pxml-prefix-match" as="xs:string" select="'(.*)'"/>

    <!-- the replacement part of how to make facs links -->
    <xsl:param name="p2t:pxml-prefix-replacement" as="xs:string" select="'$1'"/>


    <!-- Use this initial template to transform all documents found in a directory.
        @seed:it@ -->
    <xsl:template name="p2t:collection-uri" visibility="final">
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>Input Collection: </xsl:text>
            <xsl:value-of select="uri-collection($p2t:collection-uri)"/>
        </xsl:message>
        <xsl:call-template name="tei-template">
            <xsl:with-param name="pages" select="collection($p2t:collection-uri)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Use this initial template to transform all documents found in a directory. -->
    <xsl:template name="xsl:initial-template" visibility="public">
        <xsl:call-template name="p2t:collection-uri"/>
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
            <xsl:if test="$p2t:with-facsimile and (empty($p2t:only) or $p2t:only eq 'facsimile')">
                <facsimile>
                    <xsl:for-each select="$pages">
                        <xsl:apply-templates select="." mode="facsimile">
                            <xsl:with-param name="page-number" as="xs:integer" select="position()"
                                tunnel="true"/>
                            <!-- assert, that the collection is ordered lexically by file name -->
                            <!--xsl:sort select="base-uri()"/-->
                        </xsl:apply-templates>
                    </xsl:for-each>
                </facsimile>
            </xsl:if>
            <xsl:if test="empty($p2t:only) or $p2t:only eq 'text'">
                <text>
                    <body>
                        <!-- first pass with mode flat-regions which flattens regions (paragraphs) to a
                            milestone markup which can be upcycled again in the second pass. -->
                        <xsl:variable name="flat-regions">
                            <xsl:for-each select="$pages">
                                <xsl:apply-templates select="." mode="page">
                                    <xsl:with-param name="page-number" as="xs:integer"
                                        select="position()" tunnel="true"/>
                                    <!-- assert, that the collection is ordered lexically by file name -->
                                    <!--xsl:sort select="base-uri()"/-->
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </xsl:variable>
                        <!--xsl:apply-templates select="$flat-regions/node()" mode="text-regions"/-->
                        <!-- second pass: upcycled region milestones to paragraphs, but only when they
                            result from real paragraphs, not from page breaks (a page in pagexml
                            always starts with a new region). -->
                        <xsl:variable name="with-paragraphs">
                            <xsl:for-each-group select="$flat-regions/node()"
                                group-starting-with="TextRegionStart[not(preceding::node()[1][self::tei:pb])]">
                                <p>
                                    <xsl:if
                                        test="current-group()/descendant-or-self::TextRegionStart/@xml:id">
                                        <xsl:attribute name="xml:id"
                                            select="(current-group()/descendant-or-self::TextRegionStart/@xml:id) => p2t:merge-ids()"
                                        />
                                    </xsl:if>
                                    <xsl:if
                                        test="current-group()/descendant-or-self::TextRegionStart/@facs">
                                        <xsl:attribute name="facs"
                                            select="current-group()/descendant-or-self::TextRegionStart/@facs"
                                        />
                                    </xsl:if>
                                    <xsl:apply-templates mode="text-regions"
                                        select="current-group()"/>
                                </p>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <!-- third/final pass -->
                        <xsl:apply-templates mode="p-joiner" select="$with-paragraphs"/>
                        <xsl:text>&#xa;</xsl:text>
                    </body>
                </text>
            </xsl:if>
        </TEI>
    </xsl:template>


    <!-- named templates for making the header -->

    <xsl:template name="p2t:tei-header" visibility="public">
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
            <xsl:call-template name="p2t:encoding-desc"/>
        </teiHeader>
    </xsl:template>

    <xsl:template name="p2t:encoding-desc" visibility="public">
        <encodingDesc>
            <listPrefixDef>
                <xsl:if test="$p2t:with-facsimile">
                    <prefixDef ident="facs" matchPattern="{$p2t:facs-prefix-match}"
                        replacementPattern="{$p2t:facs-prefix-replacement}"/>
                    <prefixDef ident="pxml" matchPattern="{$p2t:pxml-prefix-match}"
                        replacementPattern="{$p2t:pxml-prefix-replacement}"/>
                </xsl:if>
            </listPrefixDef>
        </encodingDesc>
    </xsl:template>


    <!-- page is the mode is a first pass -->
    <xsl:mode name="page" on-no-match="shallow-skip" visibility="public"/>

    <xsl:template mode="page" match="Metadata"/>

    <xsl:template mode="page" match="Page">
        <xsl:param name="single-source" as="xs:boolean" select="false()" tunnel="true"/>
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:if test="not($p2t:join-pages) and not($single-source)">
            <pc:TextRegionStart>
                <xsl:call-template name="p2t:id">
                    <xsl:with-param name="context" select="child::TextRegion[1]"/>
                </xsl:call-template>
                <xsl:call-template name="p2t:facs">
                    <xsl:with-param name="context" select="child::TextRegion[1]"/>
                </xsl:call-template>
            </pc:TextRegionStart>
        </xsl:if>
        <pb>
            <xsl:call-template name="p2t:facs"/>
        </pb>
        <xsl:if test="not($p2t:join-pages) or $single-source">
            <pc:TextRegionStart>
                <xsl:call-template name="p2t:id">
                    <xsl:with-param name="context" select="child::TextRegion[1]"/>
                </xsl:call-template>
                <xsl:call-template name="p2t:facs">
                    <xsl:with-param name="context" select="child::TextRegion[1]"/>
                </xsl:call-template>
            </pc:TextRegionStart>
        </xsl:if>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="TextRegion">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <!-- 
            In order to join paragraphs that cross page boundaries
            we do not wrap the content of ta TextRegion into tei:p
            but add a flat TextRegionStart and use a second pass
            and xsl:for-each-group 
        -->
        <pc:TextRegionStart>
            <xsl:call-template name="p2t:id"/>
            <xsl:call-template name="p2t:facs"/>
        </pc:TextRegionStart>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <xsl:template mode="page" match="TextLine">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:choose>
            <xsl:when test="$p2t:lb and not($p2t:lb-at-eol)">
                <xsl:text>&#xa;</xsl:text>
                <lb>
                    <xsl:call-template name="p2t:id"/>
                    <xsl:call-template name="p2t:facs"/>
                </lb>
            </xsl:when>
            <xsl:when test="$p2t:lb and $p2t:lb-at-eol">
                <lb>
                    <xsl:call-template name="p2t:id"/>
                    <xsl:call-template name="p2t:facs"/>
                </lb>
                <xsl:text>&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates mode="page"/>
    </xsl:template>

    <!-- if we have Words, drop TextLine/TextEquiv -->
    <xsl:template mode="page" match="TextLine/TextEquiv[preceding-sibling::Word]"/>

    <xsl:template mode="page" match="Word[position() > 1]">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:choose>
            <xsl:when test="$p2t:words">
                <xsl:text>&#x20;</xsl:text>
                <w>
                    <xsl:call-template name="p2t:id"/>
                    <xsl:call-template name="p2t:facs"/>
                    <xsl:apply-templates mode="page"/>
                </w>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="page"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template mode="page" match="Word[1]">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:choose>
            <xsl:when test="$p2t:words">
                <w>
                    <xsl:call-template name="p2t:id"/>
                    <xsl:call-template name="p2t:facs"/>
                    <xsl:apply-templates mode="page"/>
                </w>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="page"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- drop white space text nodes -->
    <xsl:template mode="page" match="text()[normalize-space(.) eq '']" priority="2"/>

    <xsl:template mode="page" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template name="p2t:id">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="context" as="element()" select="." required="false"/>
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:if test="$p2t:with-start or $p2t:with-text-ids">
            <xsl:attribute name="xml:id" select="p2t:make-id($context/@id, $page-number)"/>
        </xsl:if>
    </xsl:template>


    <!-- text-regions is the mode for the second pass -->
    <xsl:mode name="text-regions" on-no-match="shallow-copy" visibility="public"/>

    <xsl:template mode="text-regions" match="TextRegionStart"/>

    <xsl:template mode="text-regions" match="Coords"/>


    <!-- p-joiner is the mode for the third pass -->
    <xsl:mode name="p-joiner" on-no-match="shallow-copy" visibility="public"/>

    <xsl:template mode="p-joiner" match="tei:p[child::tei:pb and normalize-space(.) eq '']">
        <xsl:copy-of select="tei:pb"/>
    </xsl:template>

    <xsl:template mode="p-joiner" match="tei:pb">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="n" select="count(preceding::tei:pb) + 1"/>
        </xsl:copy>
    </xsl:template>


    <!-- facsimile -->

    <!-- a template for making the facs attribute in other modes -->
    <xsl:template name="p2t:facs" as="attribute(facs)?" visibility="final">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="context" as="element()" select="." required="false"/>
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:if test="$p2t:with-facsimile">
            <xsl:attribute name="facs" select="'#' || p2t:make-facs-id(@id, $page-number)"/>
        </xsl:if>
    </xsl:template>

    <!-- mode for making facsimile section -->
    <xsl:mode name="facsimile" on-no-match="shallow-skip" visibility="public"/>

    <xsl:template mode="facsimile" match="Page">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <surface>
            <xsl:attribute name="n" select="$page-number"/>
            <xsl:call-template name="p2t:page-xml-source-link"/>
            <xsl:call-template name="p2t:facs-surface-coords"/>
            <graphic>
                <xsl:attribute name="url" select="'facs:' || @imageFilename"/>
            </graphic>
            <xsl:call-template name="p2t:facs-zone-page"/>
            <xsl:apply-templates mode="#current"/>
        </surface>
    </xsl:template>

    <xsl:template name="p2t:page-xml-source-link" as="attribute()*" visibility="public">
        <xsl:context-item as="node()" use="required"/>
        <xsl:choose>
            <xsl:when test="exists(@id)">
                <xsl:attribute name="sameAs"
                    select="'pxml:' || tokenize(base-uri(.), '/')[last()] || '#' || @id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="source" select="'pxml:' || tokenize(base-uri(.), '/')[last()]"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="p2t:facs-surface-coords" as="attribute()*" visibility="public">
        <xsl:context-item as="element(Page)" use="required"/>
        <xsl:attribute name="ulx">0</xsl:attribute>
        <xsl:attribute name="uly">0</xsl:attribute>
        <xsl:attribute name="lrx" select="@imageWidth"/>
        <xsl:attribute name="lry" select="@imageHeight"/>
    </xsl:template>

    <xsl:template name="p2t:facs-zone-page" visibility="public">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <zone type="Page">
            <xsl:attribute name="xml:id" select="p2t:facs-id-prefix(., $page-number)"/>
            <!--xsl:call-template name="p2t:page-xml-source-link"/-->
            <xsl:call-template name="p2t:facs-surface-coords"/>
        </zone>
    </xsl:template>

    <xsl:template mode="facsimile" match="TextRegion">
        <xsl:call-template name="p2t:facs-zone"/>
    </xsl:template>

    <xsl:template mode="facsimile" match="TextLine[$p2t:lb]">
        <xsl:call-template name="p2t:facs-zone"/>
    </xsl:template>

    <xsl:template mode="facsimile" match="Word[$p2t:words]">
        <xsl:call-template name="p2t:facs-zone"/>
    </xsl:template>

    <xsl:template name="p2t:facs-zone" visibility="final">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <zone>
            <xsl:attribute name="xml:id" select="p2t:make-facs-id(@id, $page-number)"/>
            <xsl:attribute name="type" select="local-name(.)"/>
            <xsl:call-template name="p2t:start"/>
            <xsl:call-template name="p2t:page-xml-source-link"/>
            <xsl:call-template name="p2t:make-coords"/>
        </zone>
        <xsl:apply-templates mode="facsimile"/>
    </xsl:template>

    <xsl:template name="p2t:start" visibility="public">
        <xsl:param name="page-number" as="xs:integer" tunnel="true"/>
        <xsl:if test="$p2t:with-start">
            <xsl:attribute name="start" select="'#' || p2t:make-id(@id, $page-number)"/>
        </xsl:if>
    </xsl:template>

    <!-- override this with some math to make a rectangle -->
    <xsl:template name="p2t:make-coords" as="attribute()*" visibility="public">
        <xsl:context-item as="element()" use="required"/>
        <xsl:attribute name="points" select="Coords[1]/@points"/>
    </xsl:template>


    <!-- functions -->

    <xsl:function name="p2t:make-id" as="xs:string" visibility="final">
        <xsl:param name="att" as="attribute()"/>
        <xsl:param name="page-number" as="xs:integer"/>
        <xsl:sequence select="p2t:id-prefix($att, $page-number) || string($att)"/>
    </xsl:function>

    <xsl:function name="p2t:id-prefix" as="xs:string" visibility="public">
        <xsl:param name="context" as="node()"/>
        <xsl:param name="page-number" as="xs:integer"/>
        <xsl:value-of select="'p' || $page-number || '.'"/>
    </xsl:function>

    <xsl:function name="p2t:make-facs-id" as="xs:string" visibility="final">
        <xsl:param name="att" as="attribute()?"/>
        <xsl:param name="page-number" as="xs:integer"/>
        <xsl:sequence select="p2t:facs-id-prefix($att, $page-number) || string($att)"/>
    </xsl:function>

    <xsl:function name="p2t:facs-id-prefix" as="xs:string" visibility="public">
        <xsl:param name="context" as="node()?"/>
        <xsl:param name="page-number" as="xs:integer"/>
        <xsl:value-of select="'f' || $page-number || '.'"/>
    </xsl:function>

    <xsl:function name="p2t:merge-ids" as="xs:string" visibility="public">
        <xsl:param name="ids" as="xs:string*"/>
        <xsl:sequence select="string-join($ids, '.MERGE.')"/>
    </xsl:function>

</xsl:package>
