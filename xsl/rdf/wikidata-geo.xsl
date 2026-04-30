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

    <xsl:param name="geo-property" as="xs:string" select="'P5140'"/>

    <!-- overrides the default value -->
    <xsl:param name="output-format" as="xs:string" select="'tei-geo'" static="true"/>

    <xsl:import href="wikidata.xsl"/>

    <xsl:template name="tei-geo">
        <xsl:param name="data" as="xs:string*"/>
        <xsl:variable name="property" as="item()*"
            select="parse-json($data) => map:get('statements') => map:get($geo-property) => array:head()"/>
        <location source="{$wkd-url}">
            <geo>
                <xsl:value-of
                    select="$property => map:get('value') => map:get('content') => map:get('latitude') || ' ' || $property => map:get('value') => map:get('content') => map:get('longitude')"
                />
            </geo>
        </location>
    </xsl:template>


</xsl:stylesheet>
