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
  xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
  exclude-result-prefixes="#all" version="3.0" default-mode="p2t:mapping">

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
    <tei>
      <xsl:copy-of select="@xml:id"/>
      <xsl:attribute name="element" select="name(.)"/>
      <xsl:attribute name="pc:id" select="p2t:elment-id(@xml:id)"/>
      <xsl:attribute name="pc:imageId" select="p2t:image-id(@xml:id)"/>
      <xsl:if test="exists(@*[name(.) eq $p2t:coords-att])">
        <xsl:attribute name="pc:points" select="@*[name(.) eq $p2t:coords-att]"/>
      </xsl:if>
    </tei>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


  <xsl:function name="p2t:elment-id" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:value-of select="tokenize($id, '\.')[2]"/>
  </xsl:function>

  <xsl:function name="p2t:image-id" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:value-of select="tokenize($id, '\.')[1] => replace('^p', '')"/>
  </xsl:function>

</xsl:package>
