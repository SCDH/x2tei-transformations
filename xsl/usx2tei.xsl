<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT for transforming USX (used by Bibelgesellschaft) to TEI

The example USX document present during development has these features:
- it does not have namespaces
- it does not have language information
- it uses identifiers in @sid that are not valid XML Identifiers
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:scdh="http://scdh.wwu.de/scdh" exclude-result-prefixes="#all" version="3.1">

    <xsl:output method="xml" indent="yes"/>

    <!-- main language of the document -->
    <xsl:param name="language" as="xs:string" select="'la'" required="false"/>

    <!-- language of metadata contained in this document, defaults to the main language -->
    <xsl:param name="metadata-language" as="xs:string" select="$language" required="false"/>

    <!-- if true, paragraphs are omitted regardless to the structure of the content -->
    <xsl:param name="no-paragraphs" as="xs:boolean" select="false()" required="false"/>

    <!-- this stylesheets is applicable on /usx as global context item -->
    <xsl:global-context-item as="document-node(element(usx))" use="required"/>

    <!-- verses for which the ending milestone is not in the same <para> element as the starting milestone -->
    <xsl:variable name="overlapping-verses" as="element(verse)*" select="
            /usx/para/verse[@sid and not(let $sid := @sid
            return
                following-sibling::verse[@eid eq $sid])]"/>

    <!-- chapters for which the ending milestone is not in the same <para> element as the starting milestone -->
    <xsl:variable name="overlapping-chapters" as="element(chapter)*" select="
            /usx/para/chapter[@sid and not(let $sid := @sid
            return
                following-sibling::chapter[@eid eq $sid])]"/>


    <!-- Make an ID from an attribute.
        This replaces whitespace in Identifiers and makes an valid XML ID
        when the given Id starts with a number. -->
    <xsl:function name="scdh:make-id" as="attribute(xml:id)?">
        <xsl:param name="id" as="attribute()?"/>
        <xsl:choose>
            <xsl:when test="$id">
                <xsl:attribute name="xml:id"
                    select="replace($id, '(\s+|[:])', '.') => replace('^(\d+)', '_$1')"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- TODO -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/usx">
        <TEI xml:lang="{$language}">
            <xsl:call-template name="root-attributes"/>
            <xsl:call-template name="header"/>
            <text>
                <body>
                    <xsl:call-template name="content"/>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template name="root-attributes">
        <xsl:if test="book[@code]">
            <xsl:sequence select="scdh:make-id(book/@code)"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="header">
        <teiHeader xml:lang="{$metadata-language}">
            <fileDesc>
                <titleStmt>
                    <xsl:apply-templates mode="title"
                        select="//chapter[1]/preceding-sibling::para[matches(@style, '^h\d*')]">
                        <xsl:sort select="@style"/>
                    </xsl:apply-templates>
                </titleStmt>
                <publicationStmt>
                    <p>
                        <xsl:text>Converted from </xsl:text>
                        <xsl:value-of select="(base-uri(.) => tokenize('/'))[last()]"/>
                    </p>
                    <xsl:apply-templates mode="publicationStmt"
                        select="//chapter[1]/preceding-sibling::para"/>
                </publicationStmt>
                <sourceDesc>
                    <p>
                        <xsl:text>Converted from </xsl:text>
                        <xsl:value-of select="(base-uri(.) => tokenize('/'))[last()]"/>
                    </p>
                </sourceDesc>
            </fileDesc>
            <revisionDesc>
                <change when="{current-date()}">
                    <xsl:text>Converted from </xsl:text>
                    <xsl:value-of select="(base-uri(.) => tokenize('/'))[last()]"/>
                    <xsl:text> unsing </xsl:text>
                    <xsl:value-of select="(static-base-uri() => tokenize('/'))[last()]"/>
                    <xsl:text>.</xsl:text>
                </change>
            </revisionDesc>
        </teiHeader>
    </xsl:template>

    <xsl:template mode="title" match="para">
        <title>
            <xsl:attribute name="n" select="@style"/>
            <xsl:apply-templates mode="meta"/>
        </title>
    </xsl:template>

    <xsl:template mode="publicationStmt" match="para">
        <p>
            <xsl:attribute name="n" select="@style"/>
            <xsl:apply-templates mode="meta"/>
        </p>
    </xsl:template>

    <xsl:template mode="meta" match="note">
        <note>
            <xsl:call-template name="formatting"/>
            <xsl:apply-templates mode="#current"/>
        </note>
    </xsl:template>

    <xsl:template mode="#all" match="char">
        <hi>
            <xsl:call-template name="formatting"/>
            <xsl:apply-templates mode="#current"/>
        </hi>
    </xsl:template>


    <xsl:template name="content">
        <xsl:context-item as="element(usx)" use="required"/>
        <xsl:message>
            <xsl:call-template name="overlapping-info"/>
        </xsl:message>
        <xsl:comment>
            <xsl:call-template name="overlapping-info"/>
        </xsl:comment>
        <xsl:choose>
            <xsl:when test="$no-paragraphs">
                <xsl:call-template name="chapters-and-verses"/>
            </xsl:when>
            <xsl:when test="empty(($overlapping-verses, $overlapping-chapters))">
                <xsl:call-template name="chapters-paragraphs-verses"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="chapters-and-verses"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="overlapping-info">
        <xsl:context-item as="element(usx)" use="required"/>
        <xsl:choose>
            <xsl:when test="empty($overlapping-verses) and empty($overlapping-chapters)">
                <xsl:text>no overlapping structures found</xsl:text>
            </xsl:when>
            <xsl:when test="$overlapping-verses and empty($overlapping-chapters)">
                <xsl:text>found verses overlapping paragraph boundaries: </xsl:text>
                <xsl:for-each select="$overlapping-verses">
                    <xsl:value-of select="@sid"/>
                    <xsl:if test="position() ne last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$overlapping-chapters and empty($overlapping-verses)">
                <xsl:text>found chapters overlapping paragraph boundaries: </xsl:text>
                <xsl:for-each select="$overlapping-verses">
                    <xsl:value-of select="@sid"/>
                    <xsl:if test="position() ne last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>found chapters and verses overlapping paragraph boundaries: </xsl:text>
                <xsl:for-each select="$overlapping-chapters, $overlapping-verses">
                    <xsl:value-of select="@sid"/>
                    <xsl:if test="position() ne last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- restructure the main text to chapters and verses, paragraphs are encoded as milestone markup -->
    <xsl:template name="chapters-and-verses">
        <xsl:context-item as="element(usx)"/>
        <!-- first reduce structure of <para> elements to flatten milestone markup -->
        <xsl:variable as="node()*" name="content">
            <xsl:apply-templates mode="flatten-paragraphs"/>
        </xsl:variable>
        <xsl:message>
            <xsl:text>Nodes in content: </xsl:text>
            <xsl:value-of select="count($content)"/>
        </xsl:message>
        <!-- Erect structure of chapters and verses encoded as milestone markup.
            Chapters are enclosed in empty <chapter> elements, where
            the starting has a @sid, the ending as a @eid attribute. -->
        <xsl:for-each-group select="$content" group-starting-with="chapter[@sid]">
            <xsl:message use-when="true() or system-property('debug') eq 'true'">
                <xsl:text>chaper </xsl:text>
                <xsl:value-of select="current-group()[1]/@number"/>
            </xsl:message>
            <!-- To filter out book identification, headers, titles and introduction, we simply test if the group
                starts with a chapter element. -->
            <xsl:if test="current-group()[1][self::chapter]">
                <lg>
                    <xsl:attribute name="n" select="current-group()[1]/@number"/>
                    <xsl:sequence select="current-group()[1]/@sid => scdh:make-id()"/>
                    <!-- verses are enclosed in empty <verse> elements,
                        the starting has @sid and the ending has @eid attribute -->
                    <xsl:for-each-group select="current-group()" group-starting-with="verse[@sid]">
                        <!-- drop whitespace before first starting verse element -->
                        <xsl:if test="current-group() => string-join() => normalize-space() ne ''">
                            <l>
                                <xsl:attribute name="n" select="current-group()[1]/@number"/>
                                <xsl:sequence select="current-group()[1]/@sid => scdh:make-id()"/>
                                <xsl:apply-templates select="current-group()"/>
                            </l>
                        </xsl:if>
                    </xsl:for-each-group>
                </lg>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:mode name="flatten-paragraphs" on-no-match="deep-copy"/>

    <!-- flatten <para> structure to milestone markup -->
    <xsl:template mode="flatten-paragraphs" match="para">
        <xsl:variable name="number" as="xs:integer" select="count(preceding::para) + 1"/>
        <milestone type="para" n="${$number}" xml:id="{scdh:make-id(//book/@code)||'.p'||$number}"/>
        <xsl:copy-of select="node()"/>
    </xsl:template>

    <xsl:template mode="flatten-paragraphs" match="para[matches(@style, '^mte\d+')]">
        <ab type="para">
            <xsl:call-template name="formatting"/>
            <xsl:apply-templates mode="#current"/>
        </ab>
    </xsl:template>

    <xsl:template name="chapters-paragraphs-verses">
        <xsl:context-item as="element(usx)" use="required"/>
        <xsl:for-each-group select="node()" group-starting-with="chapter[@sid]">
            <xsl:message use-when="true() or system-property('debug') eq 'true'">
                <xsl:text>chaper </xsl:text>
                <xsl:value-of select="current-group()[1]/@number"/>
            </xsl:message>
            <!-- To filter out book identification, headers, titles and introduction, we simply test if the group
                starts with a chapter element. -->
            <xsl:if test="current-group()[1][self::chapter]">
                <lg>
                    <xsl:attribute name="n" select="current-group()[1]/@number"/>
                    <xsl:sequence select="current-group()[1]/@sid => scdh:make-id()"/>
                    <!-- verses are enclosed in empty <verse> elements,
                        the starting has @sid and the ending has @eid attribute -->
                    <xsl:apply-templates select="current-group()"/>
                </lg>
            </xsl:if>
        </xsl:for-each-group>

    </xsl:template>

    <xsl:template match="para">
        <lg>
            <xsl:call-template name="formatting"/>
            <!-- verses are enclosed in empty <verse> elements,
                the starting has @sid and the ending has @eid attribute -->
            <xsl:for-each-group select="node()" group-starting-with="verse[@sid]">
                <!-- drop whitespace before first starting verse element -->
                <xsl:if test="current-group() => string-join() => normalize-space() ne ''">
                    <seg type="verse">
                        <xsl:attribute name="n" select="current-group()[1]/@number"/>
                        <xsl:sequence select="current-group()[1]/@sid => scdh:make-id()"/>
                        <xsl:apply-templates select="current-group()"/>
                    </seg>
                </xsl:if>
            </xsl:for-each-group>
        </lg>
    </xsl:template>

    <!-- TODO: handle notes -->
    <xsl:template match="note"/>


    <!-- output some formatting attributes for the current context element -->
    <xsl:template name="formatting" as="attribute()*">
        <xsl:context-item as="element()" use="required"/>
        <xsl:choose>
            <xsl:when test="@style">
                <xsl:attribute name="rend" select="@style"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
