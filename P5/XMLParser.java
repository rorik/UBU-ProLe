
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

/**
 * The main class of the program,
 * parses XML files in JATS format.
 */
public class XMLParser {
    /**
     * Parse a given file and output the results.
     *
     * @param uri the URI of the file to be parsed.
     * @param validation enable XML validation and DTD grammar.
     */
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
            } else {
                parser.setFeature("http://apache.org/xml/features/nonvalidating/load-dtd-grammar", false);
                parser.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
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

    /**
     * The main method of the program.
     * Initializes and starts a XMLParser.
     *
     * @param args the arguments of the program, the first one being the URI of the XML file,
     *              and the second one the validation activator
     *              (if any second parameter is present, validation will be active).
     */
    public static void main(String[] args) {
        if (args.length == 0 || args.length > 2) {
            System.err.println("XML file expected, usage: java XMLParser [XML URI] ([VALIDATION FLAG (ANY)])");
            System.exit(0);
        }
        XMLParser parser = new XMLParser();
        parser.parse(args[0], args.length == 2 && args[1] != null && !args[1].equals(""));
    }
}

/**
 * The XML validation error handler.
 * Used when validation is active.
 */
class JATSValidatorErrorHandler implements ErrorHandler {

    /**
     * Shows a warning message.
     *
     * @param exception the validation exception.
     */
    public void warning (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION WARNING ------");
        System.err.println(exception.getMessage());
        System.err.println("--------------------------------");
    }

    /**
     * Shows an error message.
     *
     * @param exception the validation exception.
     */
    public void error (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("------------------------------");
    }

    /**
     * Shows a fatal error message.
     *
     * @param exception the validation exception.
     */
    public void fatalError (SAXParseException exception) throws SAXException {
        System.err.println("------ VALIDATION FATAL ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("------------------------------------");
    }
}

/**
 * The content handler and lexical handler of a XML file in JATS format.
 * It will obtain and output the following information:
 * <p>
 * <ul>
 *   <li>The longest namespace, if validation is active, DTD will be taken into account.</li>
 *   <li>The article with the longest abstract.</li>
 *   <li>The amount of XML comments, DTD comments won't be taken into account.</li>
 *   <li>A list with each article.</li>
 * </ul>
 */
class JATSHandler implements ContentHandler, LexicalHandler {

    /**
     * The file locator.
     */
    private Locator locator;

    /**
     * The XML file locator.
     */
    private XMLLocator xmlLocator = new XMLLocator();

    /**
     * The longest namespace found.
     */
    private String longestNamespace = "";

    /**
     * All the articles that have been found.
     */
    private final List<Article> articles = new ArrayList<>();

    /**
     * The amount of XML comments found.
     */
    private int comments = 0;

    /**
     * The article that is currently being parsed.
     */
    private Article currentArticle;

    /**
     * Whether it's currenly parsing the DTD files.
     */
    private Boolean readingDTD = false;

    /**
     * Returns a path starting from the article level.
     * e.g. if the current level is articles.article.front.name,
     *      it will return "article.front.name".
     *
     * @return the the current level relative to the article root.
     */
    private String getRelativePath() {
        String articlePath = this.xmlLocator.getPath();
        if (articlePath.startsWith("articles.")) {
            return articlePath.substring(9);
        } else if (articlePath.equals("articles")) {
            return "..";
        }
        return articlePath;
    }

    /**
     * Sets the file locator.
     *
     * @param locator the document locator.
     */
    public void setDocumentLocator(Locator locator) {
        this.locator = locator;
    }

    /**
     * Ends the parsing of the file and shows the result.
     *
     * @throws org.xml.sax.SAXException any SAX exception, possibly
     *            wrapping another exception.
     */
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

    /**
     * Parsing a mapping of a prefix, e.g.:
     * xmlns:mml="localhost/abc"
     *
     * @param prefix the prefix of the mapping (e.g. xmlns)
     * @param uri the uri of the mapping (e.g. localhost/abc)
     */
    public void startPrefixMapping(String prefix, String uri) {
        if (this.longestNamespace.length() < uri.length()) {
            this.longestNamespace = uri;
        }
    }

    /**
     * Parse the start tag of an element. If it's an article, creates a new currentArticle.
     * If it's a section, increases the section count of the current article.
     *
     * @param uri the Namespace URI, or the empty string if the
     *        element has no Namespace URI or if Namespace
     *        processing is not being performed.
     * @param localName the local name (without prefix), or the
     *        empty string if Namespace processing is not being
     *        performed.
     * @param qName the qualified name (with prefix), or the
     *        empty string if qualified names are not available.
     * @param atts the attributes attached to the element.  If
     *        there are no attributes, it shall be an empty
     *        Attributes object.  The value of this object after
     *        startElement returns is undefined.
     * @throws org.xml.sax.SAXException any SAX exception, possibly
     *            wrapping another exception.
     */
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
    }

    /**
     * Parse the end tag of an element. If it's an article,
     * saves it in the articles list.
     *
     * @param uri the Namespace URI, or the empty string if the
     *        element has no Namespace URI or if Namespace
     *        processing is not being performed.
     * @param localName the local name (without prefix), or the
     *        empty string if Namespace processing is not being
     *        performed.
     * @param qName the qualified XML name (with prefix), or the
     *        empty string if qualified names are not available.
     * @throws org.xml.sax.SAXException any SAX exception, possibly
     *            wrapping another exception.
     */
    public void endElement(String namespaceURI, String localName, String qName) throws SAXException {
        if (this.getRelativePath().equals("article")) {
            this.articles.add(this.currentArticle);
            this.currentArticle = null;
        }
        this.xmlLocator.pop();
    }

    /**
     * Parses the characters inside a tag.
     *
     * @param ch the characters from the XML document.
     * @param start the start position in the array
     * @param length the number of characters to read from the array
     * @throws org.xml.sax.SAXException any SAX exception, possibly
     *            wrapping another exception
     */
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


    /**
     * Parses a XML comment.
     *
     * @param ch the characters from the XML document.
     * @param start the start position in the array
     * @param length the number of characters to read from the array
     */
    public void comment(char ch[], int start, int length) {
        if (!this.readingDTD) {
            this.comments++;
        }
    }

    /**
     * Start parsing a DTD file.
     *
     * @param name The document type name.
     * @param publicId The declared public identifier for the
     *        external DTD subset, or null if none was declared.
     * @param systemId The declared system identifier for the
     *        external DTD subset, or null if none was declared.
     *        (Note that this is not resolved against the document
     *        base URI).
     */
    public void startDTD(String name, String publicId, String systemId) {
        this.readingDTD = true;
    }

    /**
     * Ends the parsing of a DTD file.
     */
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

/**
 * The XML locator, keeps track of the current level of the tag that us being parsed.
 */
class XMLLocator {
    /**
     * The list of each level in ascending depth order.
     */
    private final Stack<String> position = new Stack<>();

    /**
     * Sets the new current level.
     *
     * @param element the name of the tag.
     */
    public void push(String element) {
        this.position.push(element);
    }

    /**
     * Goes back one level.
     */
    public void pop() {
        this.position.pop();
    }

    /**
     * Returns the current level.
     */
    public String getElement() {
        return this.position.peek();
    }

    /**
     * Returns the depth of the current level.
     */
    public int getLevel() {
        return this.position.size();
    }

    /**
     * Returns a list with the current route in ascending depth order.
     *
     * @return a list with the current route in ascending depth order.
     * #see position
     * #see getPath
     */
    public List<String> getRoute() {
        return new LinkedList<>(this.position);
    }

    /**
     * Returns a string with the current route in ascending depth order.
     *
     * @return a string with the current route in ascending depth order.
     * #see position
     * #see getRoute
     */
    public String getPath() {
        return String.join(".", this.position);
    }
}

/**
 * The container of all the information about an article.
 */
class Article {

    /**
     * The title of the article.
     */
    private String title = "";

    /**
     * The subtitle of the article.
     */
    private String subtitle = "";

    /**
     * The abstract of the article.
     */
    private String abstract_text = "";

    /**
     * A list of all the authors of the article.
     */
    private final List<String> authors = new ArrayList<>();

    /**
     * The year of publication.
     */
    private int publicationYear = -1;

    /**
     * The amount of sections in the body of the article.
     */
    private int sections = 0;

    /**
     * Adds text to the article.
     *
     * @param title the text to be added to the article.
     */
    public void appendTitle(String title) {
        if (this.title.isEmpty()) {
            this.title = title;
        } else if (!title.isEmpty()) {
            this.title += " " + title;
        }
    }

    /**
     * Returns the title of the article.
     *
     * @return the title of the article.
     */
    public String getTitle() {
        return title;
    }

    /**
     * Adds text to the subtitle.
     *
     * @param subtitle the text to be added to the subtitle.
     */
    public void appendSubtitle(String subtitle) {
        if (this.subtitle.isEmpty()) {
            this.subtitle = subtitle;
        } else if (!subtitle.isEmpty()) {
            this.subtitle += " " + subtitle;
        }
    }

    /**
     * Returns the subtitle of the article.
     *
     * @return the subtitle of the article.
     */
    public String getSubtitle() {
        return subtitle;
    }

    /**
     * Adds text to the abstract.
     *
     * @param abstract_text the text to be added to the abstract.
     */
    public void appendAbstract(String abstract_text) {
        if (this.abstract_text.isEmpty()) {
            this.abstract_text = abstract_text;
        } else if (!abstract_text.isEmpty()) {
            this.abstract_text += " " + abstract_text;
        }
    }

    /**
     * Returns the abstract of the article.
     *
     * @return the abstract of the article.
     */
    public String getAbstract() {
        return abstract_text;
    }

    /**
     * Adds an author to the article.
     *
     * @param author the full name of the author to be added to the article.
     */
    public void addAuthor(String author) {
        this.authors.add(author);
    }

    /**
     * Returns the list of all the authors of the article.
     *
     * @return the list of all the authors of the article.
     */
    public List<String> getAuthors() {
        return authors;
    }

    /**
     * Sets the year of the publication year, if a publication year was previously set,
     * it will set the minimum of those two.
     */
    public void setPublicationYear(String year) {
        int yearNumeric = Integer.parseInt(year);
        if (this.publicationYear == -1 || yearNumeric < this.publicationYear) {
            this.publicationYear = yearNumeric;
        }
    }

    /**
     * Returns the year of publication of the article.
     *
     * @return the year of publication of the article.
     */
    public int getPublicationYear() {
        return publicationYear;
    }

    /**
     * Increase the number of sections by one.
     */
    public void addSection() {
        this.sections++;
    }

    /**
     * Returns the amount of sections of the article.
     *
     * @return the amount of sections of the article.
     */
    public int getSections() {
        return sections;
    }

    /**
     * Returns the full title of the article (title: subtitle).
     *
     * @return the full title of the article (title: subtitle).
     */
    public String getFullTitle() {
        return getTitle() + (getSubtitle().isEmpty() ? "" : ": " + getSubtitle());
    }

    /**
     * Returns a summary of the article meta:
     * Title, authors, publication year and sections.
     *
     * @return returns a summary of the article meta.
     */
    @Override
    public String toString() {
        return "\"" + getTitle() + "\" escrito por " + String.join(", ", getAuthors()) +
            ". Se publicó en el " + getPublicationYear() +
            ". Nº de secciones: " + getSections() + ".";
    }
}