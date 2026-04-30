<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:http="http://expath.org/ns/http-client"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:output method="json" indent="true"/>

    <xsl:import href="wikidata.xsl"/>

    <xsl:template name="tei-geo">
        <xsl:param name="data" as="xs:string*"/>
        <xsl:variable name="j" as="item()*" select="parse-json($data)"/>
        <xsl:sequence select="$j"/>
    </xsl:template>


</xsl:stylesheet>
