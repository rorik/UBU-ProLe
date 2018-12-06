
import java.io.IOException;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.apache.xerces.parsers.SAXParser;
import org.xml.sax.ContentHandler;
import org.xml.sax.Attributes;
import org.xml.sax.Locator;

public class XMLParser {
    public void parse(String uri) {
        System.out.println("Parsing file: " + uri + "\n\n");
        try {
            XMLReader parser = new SAXParser();
            parser.setContentHandler(new XMLContentHandler());
            parser.parse(uri);
        } catch (IOException e) {
            System.out.println("Error accessing the file: " + e.getMessage());
        } catch (SAXException e) {
            System.out.println("Parsing error: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("XML file expected, usage: java XMLParser [XML URI]");
            System.exit(0);
        }
        XMLParser parser = new XMLParser();
        parser.parse(args[0]);
    }
}

class XMLContentHandler implements ContentHandler {
    private Locator locator;

    public void setDocumentLocator(Locator locator) {
        this.locator = locator;
    }

    public void startDocument() throws SAXException {
        System.out.println("Parsing started");
    }

    public void endDocument() throws SAXException {
        System.out.println("Parsing ended");
    }

    public void processingInstruction(String target, String data) throws SAXException {
        System.out.println("Processing instruction: target:" + target + ", data:" + data);
    }

    public void startPrefixMapping(String prefix, String uri) {
        System.out.println("Mapping prefix \"" + prefix + "\" to the URI \"" + uri + "\"");
    }

    public void endPrefixMapping(String prefix) {
        System.out.println("Mapped prefix \"" + prefix + "\"");
    }

    public void startElement(String namespaceURI, String localName, String rawName, Attributes atts)
            throws SAXException {
        System.out.println("/----------- " + localName + " ------------");
        if (!namespaceURI.isEmpty()) {
            System.out.println(" Namespace: " + namespaceURI + " \"" + rawName + "\"");
        }

        for (int i = 0; i < atts.getLength(); i++) {
            System.out.println(" Attribute: " + atts.getLocalName(i) + "=" + atts.getValue(i));
        }
    }

    public void endElement(String namespaceURI, String localName, String rawName) throws SAXException {
        System.out.println("------------ " + localName + " -----------/");
    }

    public void characters(char[] ch, int start, int end) throws SAXException {
        System.out.println("{");
        System.out.println(new String(ch, start, end));
        System.out.println("}");
    }

    public void ignorableWhitespace(char[] ch, int start, int end) throws SAXException {}

    public void skippedEntity(String name) throws SAXException {}
}
