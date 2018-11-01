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

  <xsl:template match="maven:settings/maven:servers">
    <xsl:element name="servers" namespace="http://maven.apache.org/SETTINGS/1.0.0">
      <xsl:element name="server" namespace="http://maven.apache.org/SETTINGS/1.0.0">
        <xsl:element name="id" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$server-id"/></xsl:element>
        <xsl:element name="username" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$server-username"/></xsl:element>
        <xsl:element name="password" namespace="http://maven.apache.org/SETTINGS/1.0.0"><xsl:value-of select="$server-password"/></xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
