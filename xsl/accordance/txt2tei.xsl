<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all"
    version="3.0">

    <xsl:output method="xml" indent="true" encoding="UTF-8"/>

    <xsl:param name="textfile" as="xs:string" required="true"/>

    <xsl:param name="encoding" as="xs:string" select="'UTF-16'"/>

    <xsl:param name="chapter-start" as="xs:string" select="'(\s*\p{L}+\s*)(\d+)(\s*:\s*)'"/>

    <xsl:param name="verse-start" as="xs:string" select="'(\d+)'"/>

    <xsl:param name="id-delimiter" as="xs:string" select="'.'"/>

    <xsl:param name="book-prefix" as="xs:string" select="'MT'"/>

    <xsl:param name="language" as="xs:string" select="'he'"/>

    <xsl:param name="rng" as="xs:string" select="'resources/schema/vitriol.rng'"/>
    <xsl:param name="schematron" as="xs:string" select="'resources/schema/vitriol.sch'"/>

    <xsl:template name="readfile">
        <xsl:param name="textfile" as="xs:string" select="$textfile"/>
        <xsl:variable name="text" as="xs:string" select="unparsed-text($textfile, $encoding)"/>
        <xsl:call-template name="model"/>
        <TEI xml:id="{replace($book-prefix, '\p{P}', '')}" xml:lang="{$language}">
            <xsl:call-template name="header"/>
            <text>
                <body>
                    <xsl:variable name="flat">
                        <xsl:analyze-string select="$text" regex="{$chapter-start}">
                            <xsl:matching-substring>
                                <head n="{regex-group(2)}"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <div>
                                    <xsl:variable name="chapter" select="."/>
                                    <xsl:analyze-string select="$chapter" regex="{$verse-start}">
                                        <xsl:matching-substring>
                                            <head n="{regex-group(1) => replace('\p{P}', '') => replace('(\d+)([a-e])(a)$', '$1$2')}"/>
                                        </xsl:matching-substring>
                                        <xsl:non-matching-substring>
                                            <l>
                                                <xsl:value-of select="."/>
                                            </l>
                                        </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                </div>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:apply-templates select="$flat" mode="numbered">
                        <xsl:with-param name="prefix" select="$book-prefix" tunnel="true"/>
                    </xsl:apply-templates>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xsl:template mode="numbered" match="div | l">
        <xsl:param name="prefix" as="xs:string" tunnel="true"/>
        <xsl:variable name="number" as="xs:string" select="
                if (preceding-sibling::head) then
                    preceding-sibling::head[1]/@n
                else
                    1"/>
        <xsl:copy>
            <xsl:attribute name="n" select="$number"/>
            <xsl:attribute name="xml:id" select="concat($prefix, $id-delimiter, $number)"/>
            <xsl:apply-templates mode="numbered">
                <xsl:with-param name="prefix" as="xs:string" tunnel="true"
                    select="concat($prefix, $id-delimiter, $number)"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template mode="numbered" match="head"/>

    <xsl:template mode="numbered" match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template name="model">
        <xsl:processing-instruction name="xml-model">
            <xsl:text> href=&quot;</xsl:text>
            <xsl:value-of select="$rng"/>
            <xsl:text>&quot; type=&quot;application/xml&quot; schematypens=&quot;http://relaxng.org/ns/structure/1.0&quot;</xsl:text>
        </xsl:processing-instruction>
        <xsl:processing-instruction name="xml-model">
            <xsl:text> href=&quot;</xsl:text>
            <xsl:value-of select="$schematron"/>
            <xsl:text>&quot; type=&quot;application/xml&quot; schematypens=&quot;http://purl.oclc.org/dsdl/schematron&quot;</xsl:text>
        </xsl:processing-instruction>
    </xsl:template>

    <xsl:template name="header">
        <teiHeader xml:lang="de">
            <fileDesc>
                <titleStmt>
                    <title>
                        <xsl:value-of select="$book-prefix"/>
                    </title>
                </titleStmt>
                <publicationStmt>
                    <p>Westfälische Wilhelms Universität Münster</p>
                </publicationStmt>
                <sourceDesc>
                    <p>durch Jahrtausende überliefert</p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
    </xsl:template>

</xsl:stylesheet>
