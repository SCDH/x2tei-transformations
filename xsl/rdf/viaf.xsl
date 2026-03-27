<?xml version="1.0" encoding="UTF-8"?>
<!-- get RDF/XML from viaf.org and transform it to TEI

USAGE:
target/bin/xslt.sh -config:saxon-local.xml -xsl:xsl/viaf/viaf.xsl -it id=VAIF_ID

USAGE: get RDF/XML
target/bin/xslt.sh -config:saxon-local.xml -xsl:xsl/viaf/viaf.xsl -it output-format=rdf id=VAIF_ID

USAGE: transform a RDF/XML source file to TEI
target/bin/xslt.sh -xsl:xsl/viaf/viaf.xsl -s:VAIF-RDF.XML

http:send-request#3 must be registered as extension function.

<resources>
    <extensionFunction>org.expath.httpclient.saxon.SendRequestFunction</extensionFunction>
</resources>

See https://github.com/expath/expath-http-client-java/tree/main

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:http="http://expath.org/ns/http-client"
    xmlns="http://www.tei-c.org/ns/1.0" xmlns:bgn="http://bibliograph.net/"
    xmlns:dbo="http://dbpedia.org/ontology/" xmlns:genont="http://www.w3.org/2006/gen/ont#"
    xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:wdt="http://www.wikidata.org/prop/direct/" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" exclude-result-prefixes="#all" version="3.0"
    default-mode="tei">

    <xsl:output method="xml" indent="true"/>

    <xsl:param name="id" as="xs:string" select="'90045354'" required="false"/>

    <xsl:param name="viaf-base-url" as="xs:string" select="'https://viaf.org/viaf/'"/>

    <xsl:param name="viaf-base-uri" as="xs:string" select="'http://viaf.org/viaf/'"/>

    <xsl:param name="output-format" as="xs:string" select="'tei'" static="true"/>

    <xsl:param name="config-url" as="xs:string?" select="()"/>

    <xsl:param name="config" as="document-node(element(config))"
        select="(doc($config-url), $default-config)[1]"/>

    <xsl:variable name="default-config" as="document-node(element(config))">
        <xsl:document>
            <config xmlns="">
                <files>
                    <base>http://id.loc.gov/authorities/names/</base>
                    <base>http://d-nb.info/gnd/</base>
                    <base>http://www.wikidata.org/entity/</base>
                    <base>http://isni.org/isni/</base>
                </files>
                <prefLabel xml:lang="ar">
                    <match>LNL</match>
                    <match>EGAXA</match>
                    <match>UAE</match>
                </prefLabel>
                <prefLabel xml:lang="fr">
                    <match>BNF</match>
                </prefLabel>
                <prefLabel xml:lang="de">
                    <match>DNB</match>
                    <match>BNF</match>
                </prefLabel>
                <prefLabel xml:lang="en">
                    <match>LC</match>
                </prefLabel>
            </config>
        </xsl:document>
    </xsl:variable>

    <xsl:param name="viaf-source-id-base" as="xs:string" select="'http://viaf.org/viaf/sourceID/'"/>

    <xsl:variable name="viaf-resource" as="xs:string" select="$viaf-base-uri || $id"/>

    <xsl:variable name="viaf-url" as="xs:string" select="$viaf-base-url || $id"/>


    <xsl:param name="request" as="element(http:request)">
        <http:request method="GET">
            <http:header name="accept" value="application/rdf+xml"/>
        </http:request>
    </xsl:param>

    <xsl:template name="xsl:initial-template">
        <xsl:call-template name="from-viaf"/>
    </xsl:template>

    <!-- entry point -->
    <xsl:template name="from-viaf" use-when="function-available('http:send-request', 3)">
        <xsl:variable name="graph" as="node()*" select="http:send-request($request, $viaf-url, ())"/>
        <xsl:apply-templates select="$graph" _mode="{$output-format}">
            <xsl:with-param name="type" as="xs:anyURI*"
                select="$graph/rdf:RDF/rdf:Description[@rdf:about eq $viaf-resource] ! rdf:type(.)"
                tunnel="true"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- alternative entry when http:send-request is not available -->
    <xsl:template name="from-viaf" use-when="not(function-available('http:send-request', 3))">
        <xsl:message terminate="yes">
            <xsl:text xml:space="preserve">function Q{http://expath.org/ns/http-client}send-request#3 not available</xsl:text>
        </xsl:message>
    </xsl:template>

    <!-- returns all rdf:type s assigned to a resource -->
    <xsl:function name="rdf:type" as="xs:anyURI*" visibility="public">
        <xsl:param name="resource" as="element(rdf:Description)"/>
        <xsl:sequence select="$resource/rdf:type/@rdf:resource ! xs:anyURI(.)"/>
    </xsl:function>

    <!-- the rdf mode outputs the RDF/XML data from VIAF as is -->
    <xsl:template match="/" mode="rdf">
        <xsl:copy-of select="."/>
    </xsl:template>

    <!-- the tei mode outputs TEI from from VIAF RDF/XML -->
    <xsl:mode name="tei" on-no-match="shallow-skip"/>

    <xsl:template mode="tei"
        match="rdf:Description[rdf:type(.) = xs:anyURI('http://schema.org/Person')]">
        <person>
            <xsl:call-template name="identifier"/>
            <xsl:call-template name="names"/>
            <xsl:call-template name="dates"/>
            <xsl:call-template name="idno"/>
        </person>
    </xsl:template>

    <xsl:template mode="tei"
        match="rdf:Description[rdf:type(.) = xs:anyURI('http://schema.org/Place')]">
        <place>
            <xsl:call-template name="identifier"/>
            <xsl:call-template name="names"/>
            <xsl:call-template name="idno"/>
        </place>
    </xsl:template>


    <xsl:template name="identifier">
        <xsl:attribute name="xml:id" select="'viaf:' || $id"/>
    </xsl:template>

    <xsl:template name="idno">
        <xsl:context-item as="element(rdf:Description)"/>
        <xsl:variable name="context" as="element(rdf:Description)" select="."/>
        <xsl:if test="starts-with($context/@rdf:about, $viaf-base-uri)">
            <idno xml:base="http://viaf.org/viaf/">
                <xsl:value-of select="$context/dcterms:identifier"/>
            </idno>
        </xsl:if>
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>count of nafs </xsl:text>
            <xsl:value-of select="$config/* => count()"/>
        </xsl:message>
        <xsl:for-each select="$config/*:config/*:files/*:base">
            <xsl:variable name="naf" as="xs:string" select="."/>
            <xsl:variable name="naf-id" as="xs:string?"
                select="($context/schema:sameAs/rdf:Description/@rdf:about[starts-with(., $naf)] ! substring(., string-length($naf) + 1))[1]"/>
            <xsl:message use-when="system-property('debug') eq 'true'">
                <xsl:text>idno of </xsl:text>
                <xsl:value-of select="$naf"/>
            </xsl:message>
            <xsl:if test="$naf-id">
                <idno>
                    <xsl:attribute name="xml:base" select="$naf"/>
                    <xsl:value-of select="$naf-id"/>
                </idno>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="dates">
        <xsl:context-item as="element(rdf:Description)" use="required"/>
        <xsl:if test="schema:birthDate">
            <birth calendar="gregorian">
                <xsl:attribute name="when">
                    <xsl:value-of select="schema:birthDate"/>
                </xsl:attribute>
            </birth>
        </xsl:if>
        <xsl:if test="schema:deathDate">
            <death calendar="gregorian">
                <xsl:attribute name="when">
                    <xsl:value-of select="schema:deathDate"/>
                </xsl:attribute>
            </death>
        </xsl:if>
    </xsl:template>

    <xsl:template name="names">
        <xsl:context-item as="element(rdf:Description)" use="required"/>
        <xsl:variable name="context" as="element(rdf:Description)" select="."/>
        <xsl:variable name="about" as="xs:string" select="@rdf:about"/>
        <!-- graph: all resources focusing the current resource -->
        <xsl:variable name="graph" as="element(rdf:Description)*"
            select="., parent::rdf:RDF/rdf:Description[foaf:focus/@rdf:resource = $about]"/>
        <xsl:for-each select="$config/*:config/*:prefLabel">
            <xsl:variable name="preferredLabel" as="element()" select="."/>
            <xsl:variable as="element()*" name="labels">
                <xsl:for-each select="match">
                    <xsl:variable name="match" as="xs:string" select="."/>
                    <xsl:variable name="naf-data" as="element(rdf:Description)?"
                        select="$graph[matches(@rdf:about, concat($viaf-source-id-base, $match))][1]"/>
                    <xsl:choose>
                        <xsl:when test="$naf-data">
                            <xsl:element
                                name="{rdf:type($context) => rdf:type-to-tei-name-element()}">
                                <xsl:copy-of select="$preferredLabel/@*"/>
                                <xsl:attribute name="sameAs" select="$naf-data/@rdf:about"/>
                                <xsl:value-of select="$naf-data/skos:prefLabel"/>
                            </xsl:element>
                            <xsl:message>
                                <xsl:text>no name found in </xsl:text>
                                <xsl:value-of select="$match"/>
                            </xsl:message>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="$labels[1]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:function name="rdf:type-to-tei-name-element" as="xs:string" visibility="public">
        <xsl:param name="type" as="xs:anyURI*"/>
        <xsl:choose>
            <xsl:when test="$type = xs:anyURI('http://schema.org/Person')">
                <xsl:value-of select="'persName'"/>
            </xsl:when>
            <xsl:when test="$type = xs:anyURI('http://schema.org/Place')">
                <xsl:value-of select="'placeName'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'unknown'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
