<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT for transforming USX (used by Bibelgesellschaft) to TEI

This transformation is based on usx2tei.xsl
In addition to usx2tei.xsl, it assumes, that the apparatus is using 1-character sigla.

USAGE:
java -jar saxon.jar -xsl:/home/clueck/src/scdh/tei-processing/x2tei-transformations/xsl/usx/usx2tei-char-sigla.xsl -s:sources/4Esra_USX.usx ?witnesses="'AS','CMEl'"

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:scdh="http://scdh.wwu.de/scdh"
    xpath-default-namspace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all"
    version="3.1">

    <xsl:output method="xml" indent="yes"/>

    <xsl:import href="usx2tei.xsl"/>

    <!-- a sequence of witnesses, the sequence is used for groups, strings will be split at whitespace -->
    <xsl:param name="witnesses" as="xs:string*" select="()" required="false"/>

    <!-- this stylesheets is applicable on /usx as global context item -->
    <xsl:global-context-item as="document-node(element(usx))" use="required"/>


    <xsl:template name="sourceDesc">
        <xsl:choose>
            <xsl:when test="empty($witnesses)">
                <sourceDesc>
                    <p>
                        <xsl:text>Converted from </xsl:text>
                        <xsl:value-of select="(base-uri(.) => tokenize('/'))[last()]"/>
                    </p>
                </sourceDesc>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="witnesses"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:variable name="sigla-re" as="xs:string">
        <xsl:variable name="regex" as="xs:string">
            <xsl:value-of>
                <xsl:text>(^|\s)(</xsl:text>
                <xsl:for-each select="$witnesses">
                    <xsl:if test="position() gt 1">
                        <xsl:text>|</xsl:text>
                    </xsl:if>
                    <xsl:text>[</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>]+</xsl:text>
                </xsl:for-each>
                <xsl:text>)(\s(</xsl:text>
                <xsl:for-each select="$witnesses">
                    <xsl:if test="position() gt 1">
                        <xsl:text>|</xsl:text>
                    </xsl:if>
                    <xsl:text>[</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>]+</xsl:text>
                </xsl:for-each>
                <xsl:text>))*</xsl:text>
                <xsl:text>(\s|\p{P}|$)</xsl:text>
            </xsl:value-of>
        </xsl:variable>
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>Regular expression for sigla: </xsl:text>
            <xsl:value-of select="$regex"/>
        </xsl:message>
        <xsl:value-of select="$regex"/>
    </xsl:variable>

    <xsl:template name="witnesses">
        <listWit>
            <xsl:choose>
                <xsl:when test="count($witnesses) gt 1">
                    <xsl:for-each select="$witnesses">
                        <listWit>
                            <xsl:for-each select="string-to-codepoints(.) ! codepoints-to-string(.)">
                                <witness xml:id="{.}">
                                    <xsl:value-of select="."/>
                                </witness>
                            </xsl:for-each>
                        </listWit>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="string-to-codepoints(.) ! codepoints-to-string(.)">
                        <witness xml:id="{.}">
                            <xsl:value-of select="."/>
                        </witness>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </listWit>
        <xsl:comment>
            <xsl:text>Regular expression for sigla: </xsl:text>
            <xsl:value-of select="$sigla-re"/>
        </xsl:comment>
    </xsl:template>

    <xsl:variable name="sigla-alternatives-re" as="xs:string"
        select="concat('[', string-join($witnesses), ']')"/>



    <!-- upcycling apparatus -->

    <xsl:template mode="postproc" match="tei:rdg//text()">
        <xsl:analyze-string select="." regex="{$sigla-re}">
            <!-- encode witnesses in <wit> -->
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
                <xsl:for-each
                    select="(concat(regex-group(2), regex-group(3)) => string-to-codepoints()) ! codepoints-to-string(.)">
                    <xsl:choose>
                        <xsl:when test="matches(., $sigla-alternatives-re)">
                            <wit>
                                <xsl:value-of select="."/>
                            </wit>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <xsl:value-of select="regex-group(5)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template mode="postproc" match="tei:rdg/tei:hi[matches(., '^\s*\d+,\d+\s*$') and (every $ps in preceding-sibling::node() satisfies normalize-space($ps) eq '')]">
        <note type="verse-reference">
            <xsl:apply-templates mode="postproc"/>
        </note>
    </xsl:template>

</xsl:stylesheet>
