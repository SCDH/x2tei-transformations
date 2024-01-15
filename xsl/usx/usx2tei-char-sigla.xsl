<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT for transforming USX (used by Bibelgesellschaft) to TEI

This transformation is based on usx2tei.xsl
In addition to usx2tei.xsl, it assumes, that the apparatus is using 1-character sigla.

USAGE:
java -jar saxon.jar -xsl:/home/clueck/src/scdh/tei-processing/x2tei-transformations/xsl/usx/usx2tei-char-sigla.xsl -s:sources/4Esra_USX.usx ?witnesses="'AS','CMEl'"



Notes on structure:

semicolon (;) is used as a separator for readings, all semicola are directly in rdg: (//rdg//text()[matches(., ';')]/parent::* ! name()) => distinct-values()
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:scdh="http://scdh.wwu.de/scdh"
    xpath-default-namspace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all"
    version="3.1">

    <xsl:output method="xml" indent="yes"/>

    <xsl:import href="usx2tei.xsl"/>

    <!-- whether or not to wrap notes into critical apparatus entries -->
    <xsl:param name="wrap-notes-app" as="xs:boolean" select="true()" required="false"/>

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
                <sourceDesc>
                    <xsl:call-template name="witnesses"/>
                </sourceDesc>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:variable name="sigla-re" as="xs:string">
        <xsl:variable name="regex" as="xs:string">
            <xsl:value-of>
                <xsl:text>(^|\s)</xsl:text>
                <xsl:value-of select="$witnesses-re"/>
                <xsl:text>(\s</xsl:text>
                <xsl:value-of select="$witnesses-re"/>
                <xsl:text>)*</xsl:text>
                <xsl:text>(\s|\p{P}|$)</xsl:text>
            </xsl:value-of>
        </xsl:variable>
        <xsl:message use-when="system-property('debug') eq 'true'">
            <xsl:text>Regular expression for sigla: </xsl:text>
            <xsl:value-of select="$regex"/>
        </xsl:message>
        <xsl:value-of select="$regex"/>
    </xsl:variable>

    <xsl:function name="tei:make-wit-id" as="xs:string">
        <xsl:param name="siglum" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($siglum, '^[a-zA-Z]')">
                <xsl:value-of select="$siglum"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('_', $siglum)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tei:make-wit" as="attribute()?">
        <xsl:param name="witnesses" as="element(tei:wit)*"/>
        <xsl:if test="$witnesses">
            <xsl:attribute name="wit">
                <xsl:for-each select="$witnesses">
                    <xsl:if test="position() gt 1">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:text>#</xsl:text>
                    <xsl:value-of select="tei:make-wit-id(.)"/>
                </xsl:for-each>
            </xsl:attribute>
        </xsl:if>
    </xsl:function>

    <xsl:template name="witnesses">
        <listWit>
            <xsl:choose>
                <xsl:when test="count($witnesses) gt 1">
                    <xsl:for-each select="$witnesses">
                        <listWit>
                            <xsl:for-each select="string-to-codepoints(.) ! codepoints-to-string(.)">
                                <witness xml:id="{tei:make-wit-id(.)}">
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
        select="concat('([', string-join($witnesses), ']+)')"/>

    <xsl:variable name="sigla-grouped-re" as="xs:string">
        <xsl:value-of>
            <xsl:text>(</xsl:text>
            <xsl:for-each select="$witnesses">
                <xsl:if test="position() gt 1">
                    <xsl:text>|</xsl:text>
                </xsl:if>
                <xsl:text>[</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>]+</xsl:text>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
        </xsl:value-of>
    </xsl:variable>

    <xsl:variable name="witnesses-re" as="xs:string" select="$sigla-alternatives-re"/>


    <!-- upcycling apparatus -->

    <xsl:template mode="postproc" match="tei:body//tei:note">
        <app>
            <xsl:variable name="postproc">
                <xsl:document>
                    <xsl:apply-templates mode="postproc">
                        <xsl:with-param name="lem-searching"
                            select="normalize-space(.) => matches('^(\s*\d+,\d+\s*[ab]?\s*)(\[[^\]]+\])\s*$') => not()"
                            tunnel="true"/>
                    </xsl:apply-templates>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="verse-ref" select="$postproc/tei:note[1][self::tei:note]"/>
            <xsl:variable name="entries" select="$postproc/node() except $verse-ref"/>
            <xsl:variable name="entries-text" select="normalize-space(string-join($entries))"/>
            <xsl:variable name="no-flatten" select="
                    some $t in $entries[self::text()]
                        satisfies matches($t, '\S') or count($entries[self::element()]) gt 1"/>
            <xsl:variable name="entries-flattend">
                <xsl:choose>
                    <xsl:when test="$no-flatten">
                        <xsl:sequence select="$entries"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$entries/node()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="lemma">
                <xsl:choose>
                    <xsl:when test="$entries-flattend/descendant-or-self::tei:lemSep">
                        <lem>
                            <xsl:sequence
                                select="tei:make-wit($entries-flattend/descendant-or-self::tei:lemSep/preceding-sibling::*/descendant-or-self::tei:wit)"/>
                            <!-- we have to insert the verse reference into the lem, because lem has to be first element in app -->
                            <xsl:copy-of select="$verse-ref"/>
                            <xsl:copy-of
                                select="$entries-flattend/descendant-or-self::tei:lemSep/preceding-sibling::node()"
                            />
                        </lem>
                    </xsl:when>
                    <xsl:otherwise>
                        <lem>
                            <xsl:copy-of select="$verse-ref"/>
                        </lem>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="readings">
                <xsl:choose>
                    <xsl:when test="$entries-flattend/descendant-or-self::tei:lemSep">
                        <xsl:copy-of
                            select="$entries-flattend/descendant-or-self::tei:lemSep/following-sibling::node()"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$entries-flattend"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- output: verse-ref. lemma. Note: lem must be first in app -->
            <!--xsl:sequence select="$verse-ref"/-->
            <xsl:sequence select="$lemma"/>

            <xsl:variable name="reading">
                <xsl:choose>
                    <!-- when the entry is enclosed in [ ], it is a witDetail -->
                    <xsl:when test="matches($entries-text, '^\[[^\]]+\]$')">
                        <witDetail>
                            <xsl:sequence
                                select="tei:make-wit($readings/descendant-or-self::tei:wit)"/>
                            <xsl:sequence select="$readings"/>
                        </witDetail>
                    </xsl:when>
                    <xsl:otherwise>
                        <rdg>
                            <xsl:sequence
                                select="tei:make-wit($readings/descendant-or-self::tei:wit)"/>
                            <xsl:sequence select="$readings"/>
                        </rdg>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- run second stage -->
            <xsl:apply-templates mode="app2" select="$reading"/>
        </app>
    </xsl:template>

    <xsl:template name="rdg">
        <xsl:param name="element-name" as="xs:QName"/>
        <xsl:param name="entries" as="node()*"/>
        <xsl:param name="lem-searching" as="xs:boolean"/>
        <xsl:variable name="rdg">
            <xsl:element name="{$element-name}">
                <xsl:sequence select="tei:make-wit($entries/descendant-or-self::tei:wit)"/>
                <xsl:apply-templates mode="postproc" select="$entries">
                    <xsl:with-param name="lem-searching" select="$lem-searching"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:variable>
        <xsl:apply-templates mode="app2" select="$rdg"/>
    </xsl:template>

    <xsl:template mode="postproc" match="tei:body//tei:note//text()">
        <xsl:param name="lem-searching" as="xs:boolean" select="true()" tunnel="yes"/>
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
                <xsl:choose>
                    <xsl:when test="$lem-searching and not(matches(., '\['))">
                        <xsl:analyze-string select="." regex="\]">
                            <xsl:matching-substring>
                                <lemSep/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:analyze-string select="." regex=";">
                                    <xsl:matching-substring>
                                        <rdgSep/>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                                <!--xsl:value-of select="."/-->
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <xsl:template mode="postproc" match="
            tei:note/tei:hi[matches(., '^\s*\d+,\d+\s*[ab]*\s*$') and (every $ps in preceding-sibling::node()
                satisfies normalize-space($ps) eq '')]">
        <note type="verse-reference">
            <xsl:apply-templates mode="postproc"/>
        </note>
    </xsl:template>

    <xsl:mode name="app2" on-no-match="shallow-copy"/>

    <xsl:template mode="app2" match="tei:lem"/>

    <xsl:template mode="app2" match="tei:rdg[tei:rdgSep]">
        <xsl:for-each-group select="./node()" group-starting-with="tei:rdgSep">
            <rdg>
                <xsl:sequence select="tei:make-wit(current-group()/descendant-or-self::tei:wit)"/>
                <xsl:apply-templates mode="app2"
                    select="current-group() except current-group()/self::tei:rdgSep"/>
            </rdg>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template mode="app2" match="tei:witDetail//tei:rdgSep">
        <xsl:text>;</xsl:text>
    </xsl:template>


</xsl:stylesheet>
