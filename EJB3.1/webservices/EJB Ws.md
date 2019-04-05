Everything started off with Microsoft introducing a Distributed Remote Procedure calls by virtue of XML called XML-RPC. Later with the other vendors entering the arena, Web Services burst into life.
Since then Webservices introduced the a handful of jargons into the world of communication which most of us are already aware of.
Simple Object Access Protocol (SOAP)
Web Service Description Language (WSDL) 
	Defines contracts to which any WebService is guaranteed to comply to.
	Types
	Messages
	Ports
	Binding
	Service
Universal Description Discovery and Integration (UDDI) not so commonly used, serves the purpose of a directory of services provided and lookup information of a WebService.

Webservices can be broadly divided into 3 types:
1) SOAP Based, a distributed protocol that is heavily dependant on XML documents. SOAP has several elements such as Envelope, Header and Body. While header contains the application specific infrastructure data, Body contains the actual Payload.  
2) RPC Based
3) RESTful WebServices - Primarily uses HTTP protocol in the form of a Universal Resource Indicator (URI) that represents a state via its request rather than a Resource itself. RESTful webservice needn't restrict itself to an XML payload it can even use something like a JSON for example.

WebServices introduce a new class of communication that is transport protocol independant. Few of the commonly used transport level protocols being HTTP, FTP, SMTP or Messaging APIs such as JMS.

EJB 3 exploits the JAXB 2.0 APIs to marshal and unmarshal XMLs into Objects and back.  

There primarily are 2 styles in which WebServices can generally serve. The Document based and RPC based. Document based confines to a well defined schema and hence validation is a part of the definition. RPC on the other hand are equallent to plain method calls. Messages can be Literals or Encoded. An Encoded messages defines rules to decode the message. 
One of the 3 Approaches are followed in developing Services.
Bottom Up - In Java this is one where POJOs are exposed as Web Services. This enables a .Net Client to use a service provided by virtue of a EJB Service Proxy.
Top Down or the Interface first approach is one where the contract or the WSDL is first constructed. This is generally considered the best of the 3 approaches where a Service is to be newly introduced to serve disperate clients.
Meet in the middle Approach where the implementation and the interfaces are developed hand on hand and one is modified in sync with the other.
EJB Stateless Services can have a natural conversion to a webservice due to its stateless nature, which usually Web Services are, though not restricted to. Additionally, life cycle annotations gel well with the Web Service like in any Stateless Session Bean such as @PostConstruct and @Predestroy. One can also choose to use timer services and Interceptors with EJB WebServices. Declarative Transaction and Security also works with these services.
Additionally the EJB WebServices supports annotations such as @OneWay for a method that returns nothing and a @HandlerChain which are interceptors like the @Interceptors MetaData. The approach follows the Chain of Responsibility(COR) Pattern.
Service Class
[code language="java"]
@WebService
public interface InventoryService {
	public void addInventory(Inventory inventory);

	public Set<Inventory> returnInventories();

	public void outInventories(Holder<Set<Inventory>> inventories);
}
[/code]
Service Implementation
[code language="java"]
@WebService(serviceName = "InventoryService", targetNamespace = "urn:InventoryServiceTNS", portName = "InventoryServicePort")
@SOAPBinding(style = Style.DOCUMENT, use = Use.LITERAL)
@Stateless
@Interceptors(value = TimerInterceptor.class)
public class InventoryServiceImpl implements InventoryService {

	@WebMethod(action = "http://supermarket.com/add-inventories")
	@Oneway
	public void addInventory(
			@WebParam(name = "inventory", mode = WebParam.Mode.IN) Inventory inventory) {
		InventoryDB.saveInventory(inventory);
	}

	@WebMethod(action = "http://supermarket.com/inventories")
	public @WebResult(name = "inventories") Set<Inventory> returnInventories() {
		Set<Inventory> inventories = InventoryDB.getAllInventories();
		printProductCount(inventories);
		return inventories;
	}

	@WebMethod(action = "http://supermarket.com/inventories")
	public void outInventories(
			@WebParam(name = "inventories", mode = Mode.OUT) Holder<Set<Inventory>> inventories) {
		inventories.value = InventoryDB.getAllInventories();
	}

	@WebMethod(exclude = true)
	public void printProductCount(Set<Inventory> inventories) {
		int total = 0;
		for (Inventory inventory : inventories) {
			total += inventory.getProducts().size();
		}
		System.out.println(total);
	}
}
[/code]
Inventory Database
[code language="java"]
public class InventoryDB {
	private static Set<Inventory> inventories = new HashSet<Inventory>();

	public static void saveInventory(Inventory inventory) {
		inventories.add(inventory);
	}

	public static Set<Inventory> getAllInventories() {
		return inventories;
	}
}
[/code]

Clients:
Here we have 3 different approaches to choose from with EJBs.
1) Java Application Client
2) DII or Dynamic Invocation Interface
3) Dynamic Proxying.

The webservice tools usually generates the Proxy classes or does a Runtime proxying to access the actual services discovery and creation of which happens with the help of the information from the WSDL.
in our case:
http://localhost:8080/EJB/InventoryService/InventoryServiceImpl?wsdl
JAX-WS also describes the @WebServiceRef a CDI used to inject a service proxy used to access a WebService using the WSDL location. As of EJB 3.1 JAX-RS is not supported, but 3.2 defines APIs for RESTful Webservices. More information in the "EJB 3.2 in WildFly" Blogs.
Following are the screenshots of WebService invoked with the help of SOAP-UI.
    
