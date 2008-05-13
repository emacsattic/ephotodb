<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
version="1.0">

  <!--
       driver file for the transformation of the ephotodb manual to
       fo. Most of the changes are related to adding some
       "color" to the output
       -->

  <xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>
  <!--  <xsl:include href="fotitlepages.xsl"/> -->

  <xsl:attribute-set name="section.title.level1.properties">
    <xsl:attribute name="color">#999999</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="section.title.level2.properties">
    <xsl:attribute name="color">#777777</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="section.title.level3.properties">
    <xsl:attribute name="color">#666666</xsl:attribute>
  </xsl:attribute-set>

  <xsl:template match="varlistentry" mode="vl.as.blocks">
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>

    <fo:block id="{$id}" xsl:use-attribute-sets="list.item.spacing"  
      keep-together.within-column="always" 
      keep-with-next.within-column="always"
      color="#999999">
      <xsl:apply-templates select="term"/>
    </fo:block>

    <fo:block margin-left="0.25in">
      <xsl:apply-templates select="listitem"/>
    </fo:block>
  </xsl:template>

  <xsl:template name="my.inline.monoseq">
    <xsl:param name="color">black</xsl:param>
    <xsl:param name="content">
      <xsl:apply-templates/>
    </xsl:param>
    <fo:inline xsl:use-attribute-sets="monospace.properties"
      color="{$color}">
      <xsl:if test="@dir">
        <xsl:attribute name="direction">
          <xsl:choose>
            <xsl:when test="@dir = 'ltr' or @dir = 'lro'">ltr</xsl:when>
            <xsl:otherwise>rtl</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="$content"/>
    </fo:inline>
  </xsl:template>
  
  <xsl:template match="filename">
    <xsl:call-template name="my.inline.monoseq">
      <xsl:with-param name="color">#777777</xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- we insert an additional space after each keycombo to make
       sequences of keycombos better readable. This goes at the cost
       of having a trailing space even if the keycombo is right
       before a fullstop, but the latter is far less annoying -->
  <xsl:template match="keycombo">
    <xsl:variable name="action" select="@action"/>
    <xsl:variable name="joinchar">
      <xsl:choose>
        <xsl:when test="$action='seq'"><xsl:text> </xsl:text></xsl:when>
        <xsl:when test="$action='simul'">+</xsl:when>
        <xsl:when test="$action='press'">-</xsl:when>
        <xsl:when test="$action='click'">-</xsl:when>
        <xsl:when test="$action='double-click'">-</xsl:when>
        <xsl:when test="$action='other'"></xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:for-each select="*">
      <xsl:if test="position()>1"><xsl:value-of select="$joinchar"/></xsl:if>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    <xsl:text> </xsl:text>
  </xsl:template>


  <!-- some overrides of parameters defined in param.xsl -->
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="section.label.includes.component.label" select="1"/>
  <xsl:param name="fop.extensions" select="1"/>
  <xsl:param name="callout.unicode" select="1"/>
  <xsl:param name="callout.graphics" select="0"/>
  <xsl:param name="variablelist.as.blocks" select="1"/>
  <xsl:param name="graphic.default.extension" select="'svg'"/>

  <xsl:attribute-set name="admonition.title.properties">
    <xsl:attribute name="font-family"><xsl:value-of select="$title.fontset"/></xsl:attribute>
    <xsl:attribute name="font-size">14pt</xsl:attribute>
    <xsl:attribute name="font-weight">bold</xsl:attribute>
    <xsl:attribute name="hyphenate">false</xsl:attribute>
    <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
  </xsl:attribute-set>

  
</xsl:stylesheet>
