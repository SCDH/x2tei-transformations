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
                    <xsl:call-template name="chapters"/>
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
    
    

    <xsl:template name="chapters">
        <xsl:context-item as="element(usx)"/>
        <!-- Chapters are enclosed in empty <chapter> elements, where
            the starting has a @sid, the ending as a @eid attribute. -->
        <xsl:for-each-group select="node()" group-starting-with="chapter[@sid]">
            <xsl:message>
                <xsl:text>chaper </xsl:text>
                <xsl:value-of select="current-group()[1]/@number"/>
            </xsl:message>
            <xsl:if test="current-group()[1][self::chapter]">
                <div type="chapter">
                    <xsl:attribute name="n" select="current-group()[1]/@number"/>
                    <xsl:sequence select="current-group()[1]/@sid => scdh:make-id()"/>
                    <xsl:apply-templates select="current-group()"/>
                </div>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template match="para">
        <p>
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
        </p>
    </xsl:template>

    <xsl:template match="note"/>
    
    
    <!-- output some formatting attributes for the current context element -->
    <xsl:template name="formatting">
        <xsl:context-item as="element()" use="required"/>
        <xsl:choose>
            <xsl:when test="@style">
                <xsl:attribute name="rend" select="@style"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
