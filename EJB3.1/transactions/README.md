Transactions are very important particularly in a multi threaded environment. We already know of the famous ATM (Simplified) example where a withdrawal happens in two simple steps. First is is where the server updates the new balanace into the database and second where the money is provided to the requestor. Now with the existence of 2 points of failure for the device the worst outcome would be one where the database is updated with the withdrawn amount but the ATM machinary jams resulting in the requestor to not get his requested money. Thus the only possible solution here is the "All or Nothing" value proposition.
Transaction brings to our mind ACID
1) Atomicity: Changes are either Committed or Rolled back. We don't have a superposition of states. 
2) Consistency: Every system has business rules. Before and after the changes the system should be consistent with these Business Rules. Though not necessirily the case during a transaction.  
3) Isolation: In a ball dance, you probably don't want to be stepped on your shoe by someone else. Like wise you don't want anyone to fiddle with your data when you are updating a row in a RDBMS. Isolation is at rescue.
	There are 4 Isolation Levels for achieving concurrency.
	a) Read Uncommited: Also called Dirty Read, one can read uncommited data. Generally not recommended in multithreaded environment. This is the lowest level of Isolation.
	b) Read Committed: Only committed data from other transactions will be read. 
	c) Repeatable Read: Multiple reads are guaranteed to return the same result during every reads until the transaction is active.
	d) Serializable: This level guarantees the table itself will not be touched during an active transaction. This is the higest level of Isolation.
Serializable is very safe to use but not without the performance trade off. It is generally recommended to use Read Committed or Repeatable Read as the Isolation Level.
4) Durability: Changes are persistent or permenant once committed.
With EJB there are 2 types of Transaction Managements namely Container and Bean Managed Transactions. With Container Managed Transactions the EJB Container itself Provides Transaction demarkations by virtue of Method level Proxying. Hence the transactions are started and committed/rolled back at the end of the method call.
If @TransactionManagement defines the Management of the Transaction, @TransactionAttribute defines its Attribute Types.
REQUIRED: If Transaction is already started proxy join transactions it with callers transaction. If it is not a new Transaction is started.  
REQUIRED_NEW: A new Transaction always get started whether one already exists or not.
SUPPORTS: If a transaction exists join it with the caller else don't continue without one.
NOT_SUPPORTED: If it exists or not continue without one.
MANDATORY: If a transaction doesn't already exist, throw a EJBTransactionRequiredException.
NEVER: If a transaction exits then throw an EJBException.

Transactions can span over resources which are distinct or non local. When it deals with Multiple resources such as a a database and JMS or a different database or even other Enterprise Information Systems such as PeopleSoft CRM, an XA Transaction or Extended Transactions is to be used.
This protocol generally known by the nomenclature 'Two Phase Commit'.
Two phase commmit invovles 2 players, logically two or more 'Resource Managers' which issues the low level transaction commands and a Transaction Manager which help the underlying Resource Managers co-ordinate with each other, thus extends the span of transaction over multiple resources.

In EJB Runtime Exceptions are also called System Exceptions and as commonly believed and understood a RuntimeException is generally not expected and need not be handled explicitely unless necessitated by the use case. If such an exception occurs, a transaction is Rolled back by the proxy introduced in case of Container managed Transaction. There are yet another class of Exceptions that are called (and Type-Annotated @ApplicationException with a rollback boolean attribute). These exceptions cause a transaction to rollback. 
Below is the example of a Container Managed Transaction with 4 cases. In the example payment happens two folds. Firstly a bill is registered with database and Second the card is validated with Third Party Gateway (Simulated) in our case.
In all four cases the bill registeration is successful since it is going to be clean and with our own datastore. The card validation happens seperately with Amount as the input. 
Scenario 1: Card is Invalid, with a Business Exception thrown out.
Scenario 2: Card is Invalid, with a Application Exception thrown out.
Scenario 3: Card is Invalid, with a Checked Exception thrown out.
Scenario 4: Card is valid
As mentioned above scenarios 1 and 2 lead the transactions to be rolled back and hence the first operation of bill registeration will fail.
Bill class
[code langugage="java"]
@Entity
public class Bill implements Serializable {
	private static final long serialVersionUID = 2535779994654392895L;
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	private long id;
	private String billNumber;
	@OneToMany(cascade = CascadeType.PERSIST)
	private Set<BillParticular> particulars;
	private float total;

	public String getBillNumber() {
		return billNumber;
	}

	public void setBillNumber(String billNumber) {
		this.billNumber = billNumber;
	}

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public Set<BillParticular> getParticulars() {
		return particulars;
	}

	public void setParticulars(Set<BillParticular> particulars) {
		this.particulars = particulars;
		total = 0;
		for (BillParticular particular : particulars) {
			total += particular.getCost();
		}
	}

	public float getTotal() {
		return total;
	}

	public void setTotal(float total) {
		this.total = total;
	}

	@Override
	public String toString() {
		return "Bill [billNumber=" + billNumber + ", particulars="
				+ particulars + ", total=" + total + "]";
	}
}
[/code]
BillParticular Class
[code langugage="java"]
@Entity
public class BillParticular implements Serializable {
	private static final long serialVersionUID = -7294150703183692206L;
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	private long id;
	private String particular;
	private int qty;
	private float cost;

	public BillParticular(String particular, int qty, float cost) {
		super();
		this.particular = particular;
		this.qty = qty;
		this.cost = cost;
	}

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public String getParticular() {
		return particular;
	}

	public void setParticular(String particular) {
		this.particular = particular;
	}

	public int getQty() {
		return qty;
	}

	public void setQty(int qty) {
		this.qty = qty;
	}

	public float getCost() {
		return cost;
	}

	public void setCost(float cost) {
		this.cost = cost;
	}

	@Override
	public String toString() {
		return "BillParticular [id=" + id + ", particular=" + particular
				+ ", qty=" + qty + ", cost=" + cost + "]";
	}
}
[/code]
BillingService interface
[code language="java"]
@Remote
public interface BillingService {
	public void registerBill(Bill bill);
}
[/code]

BillingServiceImpl class
[code language="java"]
@Stateless
@TransactionManagement(TransactionManagementType.CONTAINER)
public class BillingServiceImpl implements BillingService {
	@PersistenceUnit
	EntityManagerFactory factory;
	@TransactionAttribute(TransactionAttributeType.MANDATORY)
	public void registerBill(Bill bill) {
		System.out.println("Registering Bill..");
		EntityManager em = factory.createEntityManager();
		em.persist(bill);
		em.close();
		System.out.println("Registered Successfully...");
	}
}
[/code]

CreditCardService interface 
[code language="java"]
@Remote
public interface CreditCardService {

	public void validCard(float amount);

	public void businessExceptionThrowingInvalidCreditCard(float amount);

	public void applicationExceptionThrowingInvaildCreditCard(float amount);

	public void exceptionThrowingInvaildCreditCard(float amount)
			throws Exception;

}
[/code]

CreditCardServiceImpl class
[code language="java"]
@Stateless
public class CreditCardServiceImpl implements CreditCardService {
	@TransactionAttribute(TransactionAttributeType.MANDATORY)
	public void validCard(float amount) {
		System.out.println("Payment of $" + amount + " successful");
	}

	@TransactionAttribute(TransactionAttributeType.MANDATORY)
	public void businessExceptionThrowingInvalidCreditCard(float amount) {
		System.out.println("Payment of $" + amount
				+ " unsuccessful: Reason Invalid Card");
		throw new RuntimeException("Invalid Card");
	}

	@TransactionAttribute(TransactionAttributeType.MANDATORY)
	public void applicationExceptionThrowingInvaildCreditCard(float amount) {
		System.out.println("Payment of $" + amount
				+ " unsuccessful: Reason Invalid Card");
		throw new RuntimeException("Invalid Card");
	}

	@TransactionAttribute(TransactionAttributeType.MANDATORY)
	public void exceptionThrowingInvaildCreditCard(float amount)
			throws Exception {
		System.out.println("Payment of $" + amount
				+ " unsuccessful: Reason Invalid Card");
		throw new Exception("Invalid Card");
	}
}
[/code]

PaymentService interface
[code language="java"]
@Remote
public interface PaymentService {

	public void validCard(Bill bill);

	public void businessExceptionThrowingInvalidCreditCard(Bill bill);

	public void applicationExceptionThrowingInvaildCreditCard(Bill bill);

	public void exceptionThrowingInvaildCreditCard(Bill bill);
}
[/code]

PaymentServiceImpl class
[code language="java"]
@Stateless
@TransactionManagement(TransactionManagementType.CONTAINER)
public class PaymentServiceImpl implements PaymentService {
	@EJB
	BillingService billService;
	@EJB
	CreditCardService cardService;

	@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
	public void validCard(Bill bill) {
		billService.registerBill(bill);
		cardService.validCard(bill.getTotal());
	}

	@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
	public void businessExceptionThrowingInvalidCreditCard(Bill bill) {
		billService.registerBill(bill);
		cardService.applicationExceptionThrowingInvaildCreditCard(bill
				.getTotal());
	}

	@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
	public void applicationExceptionThrowingInvaildCreditCard(Bill bill) {
		billService.registerBill(bill);
		cardService.businessExceptionThrowingInvalidCreditCard(bill.getTotal());
	}

	@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
	public void exceptionThrowingInvaildCreditCard(Bill bill) {
		try {
			billService.registerBill(bill);
			cardService.exceptionThrowingInvaildCreditCard(bill.getTotal());
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
[/code]

InvalidCardApplicationException class
[code language="java"]
@ApplicationException
public class InvalidCardApplicationException extends Exception {
	private static final long serialVersionUID = -3280967903943747701L;

	public InvalidCardApplicationException(String s) {
		super(s);
	}

	public InvalidCardApplicationException(Exception e) {
		super(e);
	}
}
[/code]

Testcase PaymentServiceTester
[code language="java"]
public class PaymentServiceTester extends TestCase {
	PaymentService service = null;

	public void setUp() {
		try {
			service = LookupUtility
					.lookup(PaymentService.class,
							"ejb:/EJB/PaymentServiceImpl!org.company.project.ejb.stateless.supermarket.PaymentService");
		} catch (NamingException e) {
			e.printStackTrace();
		}
	}

	public void testUnSuccessfulPayment1() {
		Bill bill = new Bill();
		bill.setBillNumber("1");
		Set<BillParticular> particulars = new HashSet<BillParticular>();
		particulars.add(new BillParticular("Notebook", 2, 4.7f));
		particulars.add(new BillParticular("Pen", 1, 2.7f));
		particulars.add(new BillParticular("Eraser", 2, 1.7f));
		bill.setParticulars(particulars);
		service.businessExceptionThrowingInvalidCreditCard(bill);
	}

	public void testUnSuccessfulPayment2() {
		Bill bill = new Bill();
		bill.setBillNumber("2");
		Set<BillParticular> particulars = new HashSet<BillParticular>();
		particulars.add(new BillParticular("Notebook", 2, 4.7f));
		particulars.add(new BillParticular("Pen", 1, 2.7f));
		particulars.add(new BillParticular("Eraser", 2, 1.7f));
		bill.setParticulars(particulars);
		service.applicationExceptionThrowingInvaildCreditCard(bill);
	}

	public void testUnSuccessfulPayment3() {
		Bill bill = new Bill();
		bill.setBillNumber("3");
		Set<BillParticular> particulars = new HashSet<BillParticular>();
		particulars.add(new BillParticular("Notebook", 2, 4.7f));
		particulars.add(new BillParticular("Pen", 1, 2.7f));
		particulars.add(new BillParticular("Eraser", 2, 1.7f));
		bill.setParticulars(particulars);
		service.exceptionThrowingInvaildCreditCard(bill);
	}

	public void testSuccessfulPayment() {
		Bill bill = new Bill();
		bill.setBillNumber("4");
		Set<BillParticular> particulars = new HashSet<BillParticular>();
		particulars.add(new BillParticular("Notebook", 2, 4.7f));
		particulars.add(new BillParticular("Pen", 1, 2.7f));
		particulars.add(new BillParticular("Eraser", 2, 1.7f));
		bill.setParticulars(particulars);
		service.validCard(bill);
	}
}
[/code]

Output:
