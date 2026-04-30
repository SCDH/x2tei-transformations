<?xml version="1.0" encoding="UTF-8"?>
<!-- Gets geo coordinates from wikidata, property P625 or P5140

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:http="http://expath.org/ns/http-client"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:output method="xml" indent="true"/>

    <xsl:param name="geo-properties" as="xs:string*" select="'P5140', 'P625'"/>

    <!-- overrides the default value -->
    <xsl:param name="output-format" as="xs:string" select="'tei-geo'" static="true"/>

    <xsl:import href="wikidata.xsl"/>

    <xsl:template name="tei-geo">
        <xsl:param name="data" as="xs:string*"/>
        <xsl:variable name="json" as="item()*" select="parse-json($data)"/>
        <xsl:variable name="properties" as="map(*)*">
            <xsl:for-each select="$geo-properties">
                <xsl:variable name="p" as="xs:string*" select="."/>
                <xsl:sequence
                    select="($json => map:get('statements') => map:get($p)) ! array:head(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="first" as="map(*)?"
            select="$properties[1] => map:get('value') => map:get('content')"/>
        <location source="{$wkd-url}">
            <xsl:choose>
                <xsl:when test="exists($first)">
                    <geo>
                        <xsl:value-of
                            select="concat(map:get($first, 'latitude'), ' ', map:get($first, 'longitude'))"
                        />
                    </geo>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>
                        <xsl:text>none of the geo properties is present: </xsl:text>
                        <xsl:value-of select="$geo-properties"/>
                    </xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </location>
    </xsl:template>


</xsl:stylesheet>
