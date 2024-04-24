<!-- Generate a mapping TEI<->pagexml mapping from a (fully featured) TEI derivation from pagexml

USAGE:
target/bin/xslt.sh -xsl:xsl/pagexml/tei-pagexml-mapping.xsl -s:TEI.xml

You can generate a fully featured TEI derivation with:

target/bin/xslt.sh -xsl:xsl/pagexml/pagecontent2tei.xsl -it \
  {http://scdh.wwu.de/transform/pagexml2tei#}collection-uri=../../test/samples/pagexml_chronicle?select=*_p*.xml \
  {http://scdh.wwu.de/transform/pagexml2tei#}coords=true \
  {http://scdh.wwu.de/transform/pagexml2tei#}words=true \
  > TEI.xml

-->
<xsl:package
  name="https://scdh.zivgitlabpages.uni-muenster.de/tei-processing/x2tei-transformations/xsl/pagexml/tei-pagexml-mapping.xsl"
  package-version="1.0.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:p2t="http://scdh.wwu.de/transform/pagexml2tei#"
  xmlns:pc="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0"
  default-mode="p2t:mapping">

  <xsl:output method="xml" indent="true"/>

  <xsl:param name="p2t:coords-att" as="xs:string" select="'facs'"/>

  <xsl:mode name="p2t:mapping" on-no-match="shallow-skip"/>

  <xsl:template mode="p2t:mapping" match="document-node()">
    <mapping>
      <xsl:attribute name="file" select="base-uri(.)"/>
      <xsl:apply-templates mode="#current"/>
    </mapping>
  </xsl:template>

  <xsl:template mode="p2t:mapping" match="*[@xml:id]">
    <xsl:variable name="current-page" as="element(pb)" select="p2t:current-page(.)"/>
    <tei>
      <xsl:attribute name="element" select="name(.)"/>
      <xsl:copy-of select="@xml:id"/>
      <xsl:if test="$current-page/@pageIdPrefix">
        <xsl:copy-of select="$current-page/@pageIdPrefix"/>
      </xsl:if>
      <xsl:for-each select="$current-page/@*">
        <xsl:variable name="namespace-name" select="namespace-uri(.)"/>
        <xsl:variable name="local-name" select="local-name(.)"/>
        <xsl:attribute namespace="{$namespace-name}" name="page_{$local-name}" select="."/>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="exists($current-page/@pc:pageIdPrefix)">
          <xsl:variable name="page-id-prefix" as="xs:string" select="$current-page/@pc:pageIdPrefix"/>
          <xsl:attribute name="pc:id" select="p2t:strip-page-id-prefix(@xml:id, $page-id-prefix)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="pc:id" select="p2t:elment-id(@xml:id)"/>
          <xsl:attribute name="pc:imageId" select="p2t:image-id(@xml:id)"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="exists(@*[name(.) eq $p2t:coords-att])">
        <xsl:attribute name="pc:points" select="@*[name(.) eq $p2t:coords-att]"/>
      </xsl:if>
    </tei>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


  <xsl:function name="p2t:elment-id" as="xs:string" visibility="public">
    <xsl:param name="id" as="xs:string"/>
    <xsl:value-of select="tokenize($id, '\.')[2]"/>
  </xsl:function>

  <xsl:function name="p2t:image-id" as="xs:string" visibility="public">
    <xsl:param name="id" as="xs:string"/>
    <xsl:value-of select="tokenize($id, '\.')[1] => replace('^p', '')"/>
  </xsl:function>

  <xsl:function name="p2t:current-page" as="element(pb)" visibility="final">
    <xsl:param name="context" as="node()"/>
    <xsl:choose>
      <xsl:when test="$context/preceding::pb">
        <xsl:sequence select="$context/preceding::pb[1]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="(root($context)//text//pb)[1]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="p2t:strip-page-id-prefix" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="prefix" as="xs:string"/>
    <!-- TODO: escape regex special characters in $prefix -->
    <xsl:value-of select="replace($id, concat('^', $prefix, '(.*)'), '$1')"/>
  </xsl:function>

</xsl:package>
