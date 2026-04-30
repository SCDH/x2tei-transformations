<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:http="http://expath.org/ns/http-client"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:saxon="http://saxon.sf.net/"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:output method="json" indent="true"/>

    <xsl:param name="id" as="xs:string" select="'Q1186'" required="false"/>

    <xsl:param name="wkd-item-base-url" as="xs:string"
        select="'https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/'" required="false"/>

    <xsl:param name="wkd-base-url" as="xs:string"
        select="'https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/'"/>

    <xsl:param name="wkd-base-uri" as="xs:string"
        select="'https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/'"/>

    <xsl:param name="output-format" as="xs:string" select="'data'" static="true"/>

    <xsl:param name="user-agent" as="xs:string"
        select="'x2TEI Transformations https://github.com/scdh/x2tei-transformations'"/>

    <xsl:variable name="wkd-resource" as="xs:string" select="$wkd-base-uri || $id"/>

    <xsl:variable name="wkd-url" as="xs:string" select="$wkd-base-url || $id"/>


    <xsl:param name="request" as="element(http:request)">
        <http:request method="GET">
            <http:header name="accept" value="application/json"/>
            <http:header name="If-None-Match" value="&quot;1276705620&quot;"/>
            <http:header name="If-Modified-Since" value="Sat, 06 Jun 2020 16:38:47 GMT"/>
            <http:header name="If-Match" value="&quot;1276705620&quot;"/>
            <http:header name="If-Unmodified-Since" value="Sat, 06 Jun 2020 16:38:47 GMT"/>
            <http:header name="user-agent" value="{$user-agent}"/>
        </http:request>
    </xsl:param>


    <!-- entry point -->
    <xsl:template name="from-wkd" use-when="function-available('http:send-request', 3)">
        <xsl:variable name="graph" as="xs:base64Binary*"
            select="http:send-request($request, $wkd-url, ())"/>
        <!--xsl:variable name="graph" as="item()*" select="json-doc($wkd-url)"/-->
        <xsl:call-template _name="{$output-format}">
            <xsl:with-param name="data" as="xs:string?"
                select="$graph ! saxon:base64Binary-to-string(., 'UTF8') => string-join()"/>
        </xsl:call-template>
    </xsl:template>

    <!-- alternative entry when http:send-request is not available -->
    <xsl:template name="from-wkd" use-when="not(function-available('http:send-request', 3))">
        <xsl:message terminate="yes">
            <xsl:text xml:space="preserve">function Q{http://expath.org/ns/http-client}send-request#3 not available</xsl:text>
        </xsl:message>
    </xsl:template>

    <xsl:template name="data">
        <xsl:param name="data" as="xs:string?"/>
        <xsl:sequence select="parse-json($data)"/>
    </xsl:template>

    <xsl:template match="/">
        <xsl:call-template name="from-wkd"/>
    </xsl:template>

</xsl:stylesheet>
