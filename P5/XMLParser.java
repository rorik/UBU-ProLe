
/* XMLParser imports */
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.LexicalHandler;
import org.xml.sax.helpers.XMLReaderFactory;
/* JATSValidatorErrorHandler imports */
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXParseException;
/* JATSHandler imports */
import org.xml.sax.ContentHandler;
import org.xml.sax.Attributes;
import org.xml.sax.Locator;
/* XMLLocator imports */
import java.util.Stack;
/* Article imports */
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedList;

public class XMLParser {
    public void parse(String uri, Boolean validation) {
        final XMLReader parser;
        try {
           parser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
        } catch (SAXException e) {
            System.out.println(e.getMessage());
            return;
        }
        final JATSHandler handler = new JATSHandler();

        try {
            parser.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
            parser.setContentHandler(handler);
            if (validation) {
                parser.setFeature("http://xml.org/sax/features/validation", true);
                parser.setErrorHandler(new JATSValidatorErrorHandler());
            }
        } catch (SAXNotRecognizedException e) {
            System.out.println(e.getMessage());
            return;
        } catch (SAXNotSupportedException e) {
            System.out.println(e.getMessage());
            return;
        }

        try {
            InputSource inputSource = new InputSource();
            inputSource.setCharacterStream(new InputStreamReader(new FileInputStream(new File(uri))));
            parser.parse(inputSource);
        } catch (IOException e) {
            System.out.println("Error accessing the file: " + e.getMessage());
        } catch (SAXException e) {
            System.out.println("Parsing error: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        if (args.length == 0 || args.length > 2) {
            System.err.println("XML file expected, usage: java XMLParser [XML URI] ([VALIDATION FLAG (ANY)])");
            System.exit(0);
        }
        XMLParser parser = new XMLParser();
        parser.parse(args[0], args.length == 2 && args[1] != null && !args[1].equals(""));
    }
}

class JATSValidatorErrorHandler implements ErrorHandler {

    public void warning (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION WARNING ------");
        System.err.println(exception.getMessage());
        System.err.println("--------------------------------");
    }

    public void error (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("------------------------------");
    }

    public void fatalError (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION FATAL ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("------------------------------------");
    }
}

class JATSHandler implements ContentHandler, LexicalHandler {
    private Locator locator;
    private XMLLocator xmlLocator = new XMLLocator();
    private String longestNamespace = "";
    private final List<Article> articles = new ArrayList<>();
    private int comments = 0;
    private Article currentArticle;
    private Boolean readingDTD = false;

    private String getRelativePath() {
        String articlePath = this.xmlLocator.getPath();
        if (articlePath.startsWith("articles.")) {
            return articlePath.substring(9);
        } else if (articlePath.equals("articles")) {
            return "..";
        }
        return articlePath;
    }

    public void setDocumentLocator(Locator locator) {
        this.locator = locator;
    }

    public void endDocument() throws SAXException {
        System.out.println("- El espacio de nombres más largo: " + longestNamespace);
        String longestAbstract = this.articles.stream()
            .max((a, b) -> a.getAbstract().length() - b.getAbstract().length())
            .map(article -> article.getFullTitle())
            .orElse("");
        System.out.println("- El abstract más largo es el del artículo: \"" + longestAbstract + "\".");
        System.out.println("- Número de comentarios: " + this.comments);
        System.out.println("- Artículos que aparecen: " + this.articles.size());
        for (Article article : this.articles) {
            System.out.println("  - " + article.toString());
        }
    }

    public void startPrefixMapping(String prefix, String uri) {
        if (this.longestNamespace.length() < uri.length()) {
            this.longestNamespace = uri;
        }
    }

    public void startElement(String namespaceURI, String localName, String qName, Attributes atts)
            throws SAXException {
        this.xmlLocator.push(localName);
        switch (this.getRelativePath()) {
            case "article":
                this.currentArticle = new Article();
                break;
            case "article.body.sec":
                this.currentArticle.addSection();
                break;
        }

        if (!namespaceURI.isEmpty()) {
            if (this.longestNamespace.length() < namespaceURI.length()) {
                this.longestNamespace = namespaceURI;
            }
            System.out.println(" Namespace: " + namespaceURI + " \"" + qName + "\"");
        }
    }

    public void endElement(String namespaceURI, String localName, String qName) throws SAXException {
        if (this.getRelativePath().equals("article")) {
            this.articles.add(this.currentArticle);
            this.currentArticle = null;
        }
        this.xmlLocator.pop();
    }

    public void characters(char[] ch, int start, int length) throws SAXException {
        String relativePath = this.getRelativePath();
        if (relativePath.startsWith("article.front.article-meta.")) {
            String frontMeta = relativePath.substring(27);
            if (frontMeta.startsWith("abstract")) {
                this.currentArticle.appendAbstract(new String(ch, start, length).trim());
            }
            else if (frontMeta.startsWith("title-group.article-title")) {
                this.currentArticle.appendTitle(new String(ch, start, length).trim());
            }
            else if (frontMeta.startsWith("title-group.subtitle")) {
                this.currentArticle.appendSubtitle(new String(ch, start, length).trim());
            }
            else if (frontMeta.startsWith("contrib-group.contrib.name.surname")
                    || frontMeta.startsWith("contrib.name.surname")) {
                this.currentArticle.addAuthor(new String(ch, start, length).trim());
            }
            else if (frontMeta.equals("pub-date.year")) {
                this.currentArticle.setPublicationYear(new String(ch, start, length).trim());
            }
        }
    }

    public void comment(char ch[], int start, int length) {
        if (!this.readingDTD) {
            this.comments++;
        }
    }

    public void startDTD(String name, String publicId, String systemId) {
        this.readingDTD = true;
    }

    public void endDTD() {
        this.readingDTD = false;
    }

    /* Unused methods: */
    public void startDocument() throws SAXException {}
    public void endPrefixMapping(String prefix) {}
    public void processingInstruction(String target, String data) throws SAXException {}
    public void ignorableWhitespace(char[] ch, int start, int end) throws SAXException {}
    public void skippedEntity(String name) throws SAXException {}
    public void startCDATA() {}
    public void endCDATA() {}
    public void startEntity(String name) {}
    public void endEntity(String name) {}
}

class XMLLocator {
    private final Stack<String> position = new Stack<>();

    public void push(String element) {
        this.position.push(element);
    }

    public void pop() {
        this.position.pop();
    }

    public String getElement() {
        return this.position.peek();
    }

    public int getLevel() {
        return this.position.size();
    }

    public List<String> getRoute() {
        return new LinkedList<>(this.position);
    }

    public String getPath() {
        return String.join(".", this.position);
    }
}

class Article {
    private String title = "";
    private String subtitle = "";
    private String abstract_text = "";
    private final List<String> authors = new ArrayList<>();
    private int publicationYear = -1;
    private int sections = 0;

    public void appendTitle(String title) {
        if (this.title.isEmpty()) {
            this.title = title;
        } else if (!title.isEmpty()) {
            this.title += " " + title;
        }
    }

    public String getTitle() {
        return title;
    }

    public void appendSubtitle(String subtitle) {
        if (this.subtitle.isEmpty()) {
            this.subtitle = subtitle;
        } else if (!subtitle.isEmpty()) {
            this.subtitle += " " + subtitle;
        }
    }

    public String getSubtitle() {
        return subtitle;
    }

    public void appendAbstract(String abstract_text) {
        if (this.abstract_text.isEmpty()) {
            this.abstract_text = abstract_text;
        } else if (!abstract_text.isEmpty()) {
            this.abstract_text += " " + abstract_text;
        }
    }

    public String getAbstract() {
        return abstract_text;
    }

    public void addAuthor(String author) {
        this.authors.add(author);
    }

    public List<String> getAuthors() {
        return authors;
    }

    public void setPublicationYear(String year) {
        int yearNumeric = Integer.parseInt(year);
        if (this.publicationYear == -1 || yearNumeric < this.publicationYear) {
            this.publicationYear = yearNumeric;
        }
    }

    public int getPublicationYear() {
        return publicationYear;
    }

    public void addSection() {
        this.sections++;
    }

    public int getSections() {
        return sections;
    }

    public String getFullTitle() {
        return getTitle() + (getSubtitle().isEmpty() ? "" : ": " + getSubtitle());
    }

    @Override
    public String toString() {
        return "\"" + getTitle() + "\" escrito por " + String.join(", ", getAuthors()) +
            ". Se publicó en el " + getPublicationYear() +
            ". Nº de secciones: " + getSections() + ".";
    }
}