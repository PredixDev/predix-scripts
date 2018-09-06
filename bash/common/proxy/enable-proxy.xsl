<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:maven="http://maven.apache.org/SETTINGS/1.0.0">

  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="no" indent="yes" />

  <xsl:template match="node()|@*">
    <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="maven:settings/maven:proxies">
    <xsl:element name="proxies" namespace="http://maven.apache.org/SETTINGS/1.0.0">
      <xsl:element name="proxy" namespace="http://maven.apache.org/SETTINGS/1.0.0">
        <xsl:element name="id" namespace="http://maven.apache.org/SETTINGS/1.0.0">corporate</xsl:element>
        <xsl:element name="active" namespace="http://maven.apache.org/SETTINGS/1.0.0">true</xsl:element>
        <xsl:element name="protocol" namespace="http://maven.apache.org/SETTINGS/1.0.0">http</xsl:element>
        <xsl:element name="host" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$proxy-host"/></xsl:element>
        <xsl:element name="port" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$proxy-port"/></xsl:element>
        <xsl:element name="username" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$proxy-username"/></xsl:element>
        <xsl:element name="password" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$proxy-password"/></xsl:element>
        <xsl:element name="nonProxyHosts" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$noproxy-hosts"/></xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

