<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.0">

    <xsl:output method="xml" indent="true"/>

    <xsl:param name="input-file" as="xs:anyURI" required="true"/>


    <xsl:template name="xsl:initial-template">
        <xsl:variable name="files" select="uri-collection($input-file)"/>
        <xsl:message use-when="true() or system-property('debug') eq 'true'">
            <xsl:text>Input collection: </xsl:text>
            <xsl:for-each select="$files">
                <xsl:text>&#xa;  </xsl:text>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:message>
        <xsl:apply-templates select="$files[matches(., 'document.xml')][1] => doc()"/>
    </xsl:template>

    <xsl:mode on-no-match="shallow-skip"/>

    <xsl:template match="/*">
        <TEI>
            <xsl:attribute name="xml:base" select="base-uri(.)"/>
            <xsl:apply-templates/>
        </TEI>
    </xsl:template>

    <xsl:template match="text()">
        <xsl:copy/>
    </xsl:template>

</xsl:stylesheet>
