<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:maven="http://maven.apache.org/SETTINGS/1.0.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="no" indent="yes" />

  <xsl:template match="node()|@*">
    <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="maven:settings/maven:proxies">
    <xsl:element name="proxies" namespace="http://maven.apache.org/SETTINGS/1.0.0">
      <xsl:comment>
        &lt;proxy&gt;
          &lt;id&gt;optional&lt;/id&gt;
          &lt;active&gt;true&lt;/active&gt;
          &lt;protocol&gt;http&lt;/protocol&gt;
          &lt;username&gt;proxyuser&lt;/username&gt;
          &lt;password&gt;proxypass&lt;/password&gt;
          &lt;host&gt;proxy.host.net&lt;/host&gt;
          &lt;port&gt;80&lt;/port&gt;
          &lt;nonProxyHosts&gt;local.net|some.host.com&lt;/nonProxyHosts&gt;
        &lt;/proxy&gt;
      </xsl:comment>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

