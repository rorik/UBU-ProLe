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
import java.util.LinkedList;
/* Molecule imports */
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Map.Entry;
import static java.util.stream.Collectors.joining;

/**
 * The main class of the program,
 * parses XML files in CML format.
 */
public class CMLParser {
    /**
     * Parse a given file and output the results.
     *
     * @param uri the URI of the file to be parsed.
     * @param validation enable XML validation and DTD grammar.
     */
    public void parse(String uri, Boolean validation) {
        final XMLReader parser;
        final CMLHandler handler = new CMLHandler();

        /* Create the parser */
        try {
            parser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
        } catch (SAXException e) {
            System.err.println("Unexpected exception while creating XML Reader, " + e.getMessage());
            throw new RuntimeException(e);
        }

        /* Set the content and error handler */
        parser.setContentHandler(handler);
        parser.setErrorHandler(new CMLErrorHandler());

        /* Starts parsing the given file */
        try {
            InputSource inputSource = new InputSource();
            inputSource.setCharacterStream(new InputStreamReader(new FileInputStream(new File(uri))));
            parser.parse(inputSource);
        } catch (IOException ex) {
            System.err.println("Error accessing the file: " + ex.getMessage());
            throw new RuntimeException("Error accessing the file", ex);
        } catch (SAXException ex) {
            System.err.println("Parsing error: " + ex.getMessage());
            throw new RuntimeException("Parsing error", ex);
        }
    }

    /**
     * The main method of the program.
     * Initializes and starts a CMLParser.
     *
     * @param args the arguments of the program, the first one being the URI of the XML file,
     *              and the second one the validation activator
     *              (if any second parameter is present, validation will be active).
     */
    public static void main(String[] args) {
        if (args.length == 0 || args.length > 2) {
            System.err.println("XML file expected, usage: java CMLParser [XML URI]");
            System.exit(0);
        }
        CMLParser parser = new CMLParser();
        parser.parse(args[0], args.length == 2 && args[1] != null && !args[1].equals(""));
    }
}

/**
 * The XML validation error handler.
 * Used when validation is active.
 */
class CMLErrorHandler implements ErrorHandler {

    /**
     * Shows a warning message.
     *
     * @param exception the validation exception.
     */
    public void warning(SAXParseException exception) {
        System.err.println("------ WARNING ------");
        System.err.println(exception.getMessage());
        System.err.println("---------------------");
    }

    /**
     * Shows an error message.
     *
     * @param exception the validation exception.
     */
    public void error(SAXParseException exception) {
        System.err.println("------ ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("-------------------");
    }

    /**
     * Shows a fatal error message.
     *
     * @param exception the validation exception.
     */
    public void fatalError(SAXParseException exception) {
        System.err.println("------ FATAL ERROR ------");
        System.err.println(exception.getMessage());
        System.err.println("-------------------------");
    }
}

/**
 * The content handler and lexical handler of a XML file in CML format.
 * It will obtain and output the following information:
 * <p>
 * <ul>
 *   <li>The molecule with the highest amount of atoms.</li>
 *   <li>The molecule with the highest amount of sub-molecules.</li>
 *   <li>The molecule with the highest amount of different elements.</li>
 *   <li>A list with each molecule, indicating:
 *     <ul>
 *       <li>The name of the molecule.</li>
 *       <li>The atoms it's made of.</li>
 *       <li>Wether it's organic or inorganic.</li>
 *       <li>The number of sub-molecules.</li>
 *       <li>The list with each sub-molecule, recursive.</li>
 *     </ul>
 *   </li>
 * </ul>
 */
class CMLHandler implements ContentHandler {

    /**
     * The file locator.
     */
    private Locator locator;

    /**
     * The XML file locator.
     */
    private XMLLocator xmlLocator = new XMLLocator();


    /**
     * All the molecules that have been found.
     */
    private final List<Molecule> molecules = new ArrayList<>();


    /**
     * The molecule that is currently being parsed.
     */
    private final Stack<Molecule> currentMolecules = new Stack<>();

    /**
     * Returns a path starting from the molecule level.
     * e.g. if the current level is molecules.molecule.front.name,
     *      it will return "molecule.front.name".
     *
     * @return the the current level relative to the molecule root.
     */
    private String getRelativePath() {
        final List<String> route = this.xmlLocator.getRoute();
        for (int i = route.size() - 1; i >= 0; i--) {
            if (route.get(i) == "molecule") {
                return String.join(".", route.subList(i, route.size()));
            }
        }
        return this.xmlLocator.getPath();
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
     */
    public void endDocument() {
        final String mostAtoms = this.molecules.stream()
            .max((a, b) -> a.getAllElements().size() - b.getAllElements().size())
            .map(a -> a.getName())
            .orElse("");
        System.out.println("- The molecule with the highest amount of atoms: " + mostAtoms);
        final String mostSubMolecules = this.molecules.stream()
            .max((a, b) -> a.getSubMolecules().size() - b.getSubMolecules().size())
            .map(a -> a.getName())
            .orElse("");
        System.out.println("- The molecule with the highest amount of sub-molecules: " + mostSubMolecules);
        final String mostElements = this.molecules.stream()
            .max((a, b) -> a.getElementMap().size() - b.getElementMap().size())
            .map(a -> a.getName())
            .orElse("");
        System.out.println("- The molecule with the highest amount of different elements: " + mostElements);
        System.out.println("- Molecules found: " + this.molecules.size());
        for (Molecule molecule : this.molecules) {
            printSubMolecules(molecule, 1);
        }
    }

    /**
     * Prints a list of all the sub-molecules, and the sub-molecules of the sub-molecules, and so on.
     *
     * @param molecule the molecule to print along with its sub-molecules.
     * @param currentLevel the number of identation spaces used for the molecule.
     *        Subsequent sub-molecules will have a higher currentLevel.
     */
    public void printSubMolecules(Molecule molecule, int currentLevel) {
        System.out.println(String.format("%1$" + currentLevel*4 + "s- %s", " ") + molecule.toString());
        for (Molecule subMolecule : molecule.getSubMolecules()) {
            printSubMolecules(subMolecule, currentLevel + 1);
        }
    }


    /**
     * Parse the start tag of an element. If it's an molecule, creates a new currentArticle.
     * If it's a section, increases the section count of the current molecule.
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
     */
    public void startElement(String namespaceURI, String localName, String qName, Attributes atts) {
        this.xmlLocator.push(localName);
        switch (this.getRelativePath()) {
            case "molecule":
                this.currentMolecules.push(new Molecule());
                break;
            case "molecule.formula":
                String title = atts.getValue("title");
                if (!title.isEmpty()) {
                    this.currentMolecules.peek().setName(title);
                }
                break;
            case "molecule.atomArray.atom":
                this.currentMolecules.peek().addElement(atts.getValue("elementType"));
                break;
        }
    }

    /**
     * Parse the end tag of an element. If it's an molecule,
     * saves it in the molecules list.
     *
     * @param uri the Namespace URI, or the empty string if the
     *        element has no Namespace URI or if Namespace
     *        processing is not being performed.
     * @param localName the local name (without prefix), or the
     *        empty string if Namespace processing is not being
     *        performed.
     * @param qName the qualified XML name (with prefix), or the
     *        empty string if qualified names are not available.
     */
    public void endElement(String namespaceURI, String localName, String qName) {
        if (this.getRelativePath().equals("molecule")) {
            Molecule molecule = this.currentMolecules.pop();
            if (this.currentMolecules.isEmpty()) {
                this.molecules.add(molecule);
            } else {
                this.currentMolecules.peek().addMolecule(molecule);
            }
        }
        this.xmlLocator.pop();
    }

    /* Unused methods: */
    public void startDocument() {}
    public void startPrefixMapping(String prefix, String uri) {}
    public void endPrefixMapping(String prefix) {}
    public void characters(char[] ch, int start, int length) {}
    public void processingInstruction(String target, String data) {}
    public void ignorableWhitespace(char[] ch, int start, int end) {}
    public void skippedEntity(String name) {}
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
 * The container of all the information about an molecule.
 */
class Molecule {

    /**
     * The name of the molecule.
     */
    private String name;

    /**
     * A map with the count of all the atoms of the molecule.
     */
    private final Map<String, Integer> atoms;

    /**
     * A list with all the sub-molecules of the molecule.
     */
    private final List<Molecule> submolecules = new ArrayList<>();

    /**
     * The default empty constructor.
     */
    public Molecule() {
        this.atoms = new HashMap<>();
    }

    /**
     * The constructor for a molecule with an already defined amount of atoms.
     */
    private Molecule(Map<String, Integer> atoms) {
        this.atoms = new HashMap<>(atoms);
    }

    /**
     * Sets the name to the molecule.
     *
     * @param name the name of the molecule.
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Returns the name of the molecule,
     * will return the formula if no name has been provided.
     *
     * @return the name of the molecule.
     */
    public String getName() {
        return this.name == null ? this.getFormula() : this.name;
    }

    /**
     * Add an element to the molecule with any amount of atoms.
     *
     * @param element the element to be added to the molecule.
     * @param count the number of atoms of the element to be added to the molecule.
     */
    public void addElement(String element, int count) {
        final Integer entry = this.atoms.get(element);
        if (entry == null) {
            this.atoms.put(element, count);
        } else {
            this.atoms.put(element, entry + count);
        }
    }

    /**
     * Add an element to the molecule.
     *
     * @param element the element to be added to the molecule.
     */
    public void addElement(String element) {
        this.addElement(element, 1);
    }

    /**
     * Adds a sub-molecule to the molecule.
     *
     * @param molecule the sub-molecule to be added to the molecule.
     */
    public void addMolecule(Molecule molecule) {
        this.submolecules.add(molecule);
    }

    /**
     * Returns the list of all the sub-molecules of the molecule.
     *
     * @return the list of all the sub-molecules of the molecule.
     */
    public List<Molecule> getSubMolecules() {
        return this.submolecules;
    }

    /**
     * Returns the list of all the atoms of the molecule.
     *
     * @return the list of all the atoms of the molecule.
     */
    public List<String> getAllElements() {
        final List<String> elements = new ArrayList<>();
        for (Entry<String, Integer> entry : this.atoms.entrySet()) {
            for (int i = 0; i < entry.getValue(); i++) {
                elements.add(entry.getKey());
            }
        }
        for (Molecule molecule : this.submolecules) {
            elements.addAll(molecule.getAllElements());
        }
        return elements;
    }

    /**
     * Returns the map of the count of all the atoms of the molecule.
     *
     * @return the map of the count of all the atoms of the molecule.
     */
    public Map<String, Integer> getElementMap() {
        final Molecule fullMolecule = new Molecule(this.atoms);
        for (Molecule molecule : this.submolecules) {
            for (Entry<String, Integer> entry : molecule.getElementMap().entrySet()) {
                fullMolecule.addElement(entry.getKey(), entry.getValue());
            }
        }
        return fullMolecule.atoms;
    }

    /**
     * Returns the chemical formula of the molecule.
     *
     * @return the chemical formula of the molecule.
     */
    public String getFormula() {
        return this.getElementMap().entrySet()
            .stream()
            .sorted((a, b) -> a.getKey().compareTo(b.getKey()))
            .map(a -> a.getKey() + (a.getValue() > 1 ? a.getValue() : ""))
            .collect(joining(""));
    }

    /**
     * Returns wether the molecule is organic or not.
     * Some inorganic compounds will give a false positive,
     * those are carbides, carbonates, cyanides, or carbon oxides.
     *
     * @return wether the molecule is organic or not.
     */
    public Boolean isOrganic() {
        return this.getElementMap().containsKey("C");
    }

    /**
     * Returns the type of molecule according to the number of atoms.
     *
     * @return the type of molecule according to the number of atoms.
     */
    public String getAtomicCategorization() {
        List<String> allElements = getAllElements();
        if (allElements.size() == 1) {
            return "monatomic";
        } else if (allElements.size() == 2) {
            return "diatomic";
        } else if (allElements.size() == 3) {
            return "triatomic";
        } else if (allElements.size() > 3) {
            return "polyatomic";
        }
        return "";
    }

    /**
     * Returns a summary of the molecule:
     * Name, formula, atoms, elements, organic/inorganic, sub-molecules.
     *
     * @return returns a summary of the molecule.
     */
    @Override
    public String toString() {
        return "\"" + getName() + "\" made of " + getFormula() +
            " (" + getAllElements().size() + " atoms, " + getElementMap().size() + " elements)" +
            ". It is an " + (isOrganic() ? "organic " : "inorganic ") + getAtomicCategorization() + " compound." +
            (getSubMolecules().size() == 0 ? "" : " It has " + getSubMolecules().size() + " sub-molecules:");
    }
}