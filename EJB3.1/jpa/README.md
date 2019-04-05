This blog throws some light into possibilities of representation of relationships between entities in the world of JPA in EJB3, particularly Inheritance, Composition, Association. 
This example is mainly to demonstrate the Real world relationships that could be contained in the ORM universe dispite the "Impedance or Paradigm Mismatch" that exists between the RDBMS and the OOP worlds. Though few RDBMS like Oracle claims to be an OODB they are far from realistic representations made possible by Object Oriented Programming Languages like Java.  

The 'Services' in the examples however would be far from idealistic fashion of design and development since the motivation for the approach is to seperate simplicity from actual implementation. The aforementioned details would be covered in the "EJB Design patterns" & "JPA Annotations" Blogs. Example: Ideally an application would use the commenly admired "Generic Dao Pattern" which is an allotropic form of the "Bridge Pattern" and exposes factory to create Entity Data Access Object as its Products.

Address has strong relationship with Employee though my UML tool is not able to represent the filled Diamond. :) 
UML of the Relationship that is going to be represented:

Classes:
Address.java 
[code language="java"]
/**
 * 
 * @author achuth
 * 
 *         A Value type and Not an Entity. A Value type can be identified by the
 *         lack of an identity. This is typically called Composition or a strong
 *         relation and an address cannot exist without an Employee.
 * 
 *         In Database there will be a paradigm mismatch between the Database
 *         and Object Oriented Worlds. In database world columns in address are
 *         part of the employee tables.
 * 
 *         Columns not annotated @Column is always considered as a column. This
 *         is the default Behaviour. If one has to override this behaviour of
 *         not having to persist a column one has to annotate it @Transient.
 * 
 *         In effect the only two mandatory annotations are the @Entity and @Id
 *         for a class to be turned a JPA Entity.
 */
@Embeddable
public class Address implements Serializable {
	private static final long serialVersionUID = -3770911489457238195L;
	private String doorNo;
	private String lane;
	private String street;
	private String city;
	// This represents the relationship between an Address and a State. This
	// relationship means that one Address can belong to one State. Again
	// Paradigm mismatch differentiates the 2 worlds of representation. While in
	// database the Address contains a stateId the state has no direct relation
	// with Address. In effect it is a one way relationship without a join,
	// unlike in the Object Oriented World where relation is actually two way.
	@ManyToOne
	private State state;

	public String getDoorNo() {
		return doorNo;
	}

	public void setDoorNo(String doorNo) {
		this.doorNo = doorNo;
	}

	public String getLane() {
		return lane;
	}

	public void setLane(String lane) {
		this.lane = lane;
	}

	public String getStreet() {
		return street;
	}

	public void setStreet(String street) {
		this.street = street;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public State getState() {
		return state;
	}

	public void setState(State state) {
		this.state = state;
	}

	@Override
	public String toString() {
		return "Address [doorNo=" + doorNo + ", lane=" + lane + ", street="
				+ street + ", city=" + city + ", state=" + state + "]";
	}
}
[/code]
Country.java
[code language="java"]
/**
 * 
 * @author achuth
 *
 *         This class represents a Country entity. Unlike the Address Value type
 *         this has an Id and an existence of its own.
 * 
 *         If not annotated @Table at the Target level then the JPA provider
 *         assumes the class name to be the table name.
 * 
 * 
 */
@Entity
public class Country implements Serializable {
	private static final long serialVersionUID = -155791943821444777L;
	// Considering the Paradigm mismatch in the Database two entities are
	// differentiated by their id's. If the id's are the same so are the rows.
	// But in the world of Java 2 objects are equal if their equals method
	// return true.
	// There are many strategies of ID Generation. SEQUENCE, TABLE, IDENTITY and
	// AUTO. Auto does the best fit based on the databases, for example with
	// Oracle Database, JPA would take Sequence as the best fit, with IBM DB2
	// Identity etc. Databases that don't support both the strategies could
	// choose to go with Table Strategy.
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	private Long id;
	private String countryName;
	// Eager fetch type is one where the states are fetched automatically when
	// the country is loaded. This is particularly useful when the states are to
	// be accessed outside the managed environment. Scope of the managed
	// environment is defined by the scope of the transaction for example.
	// Outside the managed environment proxys does not exist and it is no more
	// than a plain bean. Any database interaction is difficult outside this
	// scope.
	@OneToMany(mappedBy = "country")
	@Basic(fetch = FetchType.EAGER)
	@JoinColumn(name = "id")
	private Set<State> states = new HashSet<State>();

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getCountryName() {
		return countryName;
	}

	public void setCountryName(String countryName) {
		this.countryName = countryName;
	}

	public Set<State> getStates() {
		return states;
	}

	public void setStates(Set<State> states) {
		this.states = states;
	}

	public void addState(State state) {
		states.add(state);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Country other = (Country) obj;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "Country [id=" + id + ", countryName=" + countryName
				+ ", states=" + states + "]";
	}
}
[/code]
CustomerServiceExecutive.java
[code language="java"]
/**
 * 
 * @author achuth
 * 
 *         This Class establishes a parent child relation with the Employee
 *         table. One must remember to not violate the Liscov's Substitution
 *         Principles when establishing this relationship.
 * 
 *         There are 3 strategies for this relationship in JPA. Paradigm
 *         mismatch or impedance mismatch as some call, or the difference in
 *         representation of RDBMS and OOPs worlds is what motivates to maintain
 *         the representations.
 * 
 *         Table per class is one where there is one class per Entity. In our
 *         case if we had a Table per class it would have generated seperate
 *         tables for Employee, Manager, CustomerServiceExecutive and a
 *         SeniorCustomerServiceExecutive. Queries would have to do a union of
 *         all the tables to return any Employee. This approach does not require
 *         a discriminator since rows will to be falling into seperate tables
 *         are it is possible to query them out without one.
 * 
 *         Yet another strategy is the Single Table where only one table exists.
 *         This requires a discrimator and this strategy would have null values
 *         in columns not relevant to this inheritance type for example
 *         seniority level for a CustomerServiceExecutive will be null unlike in
 *         a SeniorCustomerServiceExecutive.
 * 
 *         Third strategy is called the Joint Table which separates out those
 *         columns specific to subclass of Employee.
 * 
 * 
 */
@Entity
@DiscriminatorValue("CSE")
public class CustomerServiceExecutive extends Employee implements Serializable {
	private static final long serialVersionUID = 17583210312780907L;
	@ManyToOne
	private Manager manager;

	public Manager getManager() {
		return manager;
	}

	public void setManager(Manager manager) {
		this.manager = manager;
	}
}
[/code]
Department.java
[code language="java"]
@Entity
public class Department implements Serializable {
	private static final long serialVersionUID = 8136550882875470263L;
	// This is one of the 4 cardinality types. OneToOne, OneToMany, ManyToOne,
	// ManyToMany. ManyToMany requires an intermediate table to maintain the
	// relationship which is EMP_DEPT in the below case. More on the
	// relationships and their attributes later.
	@ManyToMany
	@JoinTable(name = "EMP_DEPT", joinColumns = { @JoinColumn(name = "EMP_ID", referencedColumnName = "id") }, inverseJoinColumns = { @JoinColumn(name = "DEPT_ID", referencedColumnName = "id") })
	private Set<Employee> employees = new HashSet<Employee>();
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	private Long id;

	private String departmentName;

	public String getDepartmentName() {
		return departmentName;
	}

	public void setDepartmentName(String departmentName) {
		this.departmentName = departmentName;
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Set<Employee> getEmployees() {
		return employees;
	}

	public void setEmployees(Set<Employee> employees) {
		this.employees = employees;
	}

	public void addEmployee(Employee employee) {
		employees.add(employee);
	}

	@Override
	public String toString() {
		return "Department [employees=" + employees + ", id=" + id
				+ ", departmentName=" + departmentName + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((employees == null) ? 0 : employees.hashCode());
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Department other = (Department) obj;
		if (employees == null) {
			if (other.employees != null)
				return false;
		} else if (!employees.equals(other.employees))
			return false;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		return true;
	}
}
[/code]
Employee.java
[code language="java"]
/**
 * 
 * @author achuth
 * 
 *         This is the super class of the Employee hierarchy. This if abstract
 *         then there will not exist a corresponding table.
 */
@DiscriminatorColumn(discriminatorType = DiscriminatorType.STRING, name = "EMP_TYPE", length = 3)
@Entity
@SequenceGenerator(name = "EMP_SEQ", initialValue = 1, allocationSize = 1)
@DiscriminatorValue("EMP")
@Inheritance(strategy = InheritanceType.JOINED)
public class Employee implements Serializable {
	private static final long serialVersionUID = 1302451452128099428L;

	@Id
	@GeneratedValue(generator = "EMP_SEQ", strategy = GenerationType.SEQUENCE)
	private Long id;

	@Column(name = "EMP_NAME")
	private String employeeName;

	// Temporal is used to represent Date, Time or Timestamp
	@Temporal(TemporalType.DATE)
	private Date dateOfBirth;

	// Value type Address.
	@Embedded
	private Address address;

	@ManyToMany
	@JoinTable(name = "EMP_DEPT", joinColumns = { @JoinColumn(name = "DEPT_ID", referencedColumnName = "id") }, inverseJoinColumns = { @JoinColumn(name = "EMP_ID", referencedColumnName = "id") })
	private Set<Department> departments = new HashSet<Department>();

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getEmployeeName() {
		return employeeName;
	}

	public void setEmployeeName(String employeeName) {
		this.employeeName = employeeName;
	}

	public Set<Department> getDepartments() {
		return departments;
	}

	public void setDepartments(Set<Department> departments) {
		this.departments = departments;
	}

	public Address getAddress() {
		return address;
	}

	public void setAddress(Address address) {
		this.address = address;
	}

	public Date getDateOfBirth() {
		return dateOfBirth;
	}

	public void setDateOfBirth(Date dateOfBirth) {
		this.dateOfBirth = dateOfBirth;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Employee other = (Employee) obj;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "Employee [id=" + id + ", employeeName=" + employeeName
				+ ", dateOfBirth=" + dateOfBirth + ", address=" + address
				+ ", departments=" + departments + "]";
	}
}
[/code]
Manager.java
[code language="java"]
/**
 * 
 * @author achuth
 * 
 *         Manager is a type of Employee who have CustomerServiceExecutive as
 *         its subordinates.
 */
@Entity
@DiscriminatorValue("MGR")
public class Manager extends Employee implements Serializable {
	private static final long serialVersionUID = -6477245496347196016L;
	@OneToMany(mappedBy = "manager")
	private Set<CustomerServiceExecutive> subordinates = new HashSet<CustomerServiceExecutive>();

	public Set<CustomerServiceExecutive> getSubordinates() {
		return subordinates;
	}

	public void setSubordinates(Set<CustomerServiceExecutive> subordinates) {
		this.subordinates = subordinates;
	}

	public void addSubordinate(CustomerServiceExecutive custExecutive) {
		subordinates.add(custExecutive);
	}

	@Override
	public String toString() {
		return "Manager [subordinates=" + subordinates + "]";
	}
}
[/code]
SeniorCustomerServiceExecutive.java
[code language="java"]
@Entity
@DiscriminatorValue("SSE")
public class SeniorCustomerServiceExecutive extends CustomerServiceExecutive
		implements Serializable {
	private static final long serialVersionUID = -2639351774555527343L;
	// Enumeration here is used to identify SeniorityLevel of a
	// SeniorCustomerServiceExecutive
	@Enumerated
	private SeniorityLevel level;

	public SeniorityLevel getLevel() {
		return level;
	}

	public void setLevel(SeniorityLevel level) {
		this.level = level;
	}

	@Override
	public String toString() {
		return "SeniorCustomerServiceExecutive [level=" + level + "]";
	}
}
[/code]
SeniorityLevel.java
[code language="java"]
public enum SeniorityLevel {
	LEADER, SPECIAL, TOP_NOTCH, ENLIGHTENED;
}
[/code]
State.java
[code language="java"]
@Entity
public class State implements Serializable {
	private static final long serialVersionUID = -3179225158661645765L;
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	private Long id;
	private String stateName;
	@ManyToOne(cascade = { CascadeType.ALL })
	private Country country;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getStateName() {
		return stateName;
	}

	public void setStateName(String stateName) {
		this.stateName = stateName;
	}

	public Country getCountry() {
		return country;
	}

	public void setCountry(Country country) {
		this.country = country;
	}

	@Override
	public String toString() {
		return "State [id=" + id + ", stateName=" + stateName + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		State other = (State) obj;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		return true;
	}
}
[/code]
SuperMarketEmployeeService.java
[code language="java"]
@Remote
public interface SuperMarketEmployeeService {
	void persistEmployees(Set<Employee> employees);
}
[/code]
SuperMarketEmployeeServiceImpl.java
[code language="java"]
@Stateless
public class SuperMarketEmployeeServiceImpl implements
		SuperMarketEmployeeService {
	@PersistenceUnit
	EntityManagerFactory emf;

	public void persistEmployees(Set<Employee> employees) {
		EntityManager em = emf.createEntityManager();
		for (Employee employee : employees) {
			State state = employee.getAddress().getState();
			em.persist(state.getCountry());
			em.persist(employee);
			for (Department department : employee.getDepartments()) {
				em.persist(department);
			}
		}
		em.close();
	}
}
[/code]
EmployeeServiceTester.java
This class demonstrates how we were able to map the RDMS Objects against Class objects by virtue of an Object Relational Mapping.
[code language="java"]

public class EmployeeServiceTester extends TestCase {
	SuperMarketEmployeeService service = null;

	public void setUp() {
		try {
			service = LookupUtility
					.lookup(SuperMarketEmployeeService.class,
							"ejb:/EJB/SuperMarketEmployeeServiceImpl!org.company.project.ejb.stateless.supermarket.SuperMarketEmployeeService");
		} catch (NamingException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Employee and all assosiated entities will be persisted. Department is not
	 * mapped here to employees and hence not persisted.
	 */
	public void testCreateStateCountry() {
		Set<Employee> employees = new HashSet<Employee>();
		Country country = new Country();
		country.setCountryName("Singapore");

		State state = new State();
		state.setStateName("Singapore");
		state.setCountry(country);
		country.addState(state);

		Department department = new Department();
		department.setDepartmentName("R&D");

		SeniorCustomerServiceExecutive seniorCustServExecutive = new SeniorCustomerServiceExecutive();
		department.addEmployee(seniorCustServExecutive);
		Address address = new Address();
		address.setDoorNo("#2 Unit No 123");
		address.setLane("1st Cross Lane");
		address.setStreet("Ang Mo Kio Street");
		address.setCity("Singapore City");
		address.setState(state);
		seniorCustServExecutive.setEmployeeName("Thomas Edison");
		seniorCustServExecutive
				.setDateOfBirth(Calendar.getInstance().getTime());
		seniorCustServExecutive.setAddress(address);
		seniorCustServExecutive.setLevel(SeniorityLevel.TOP_NOTCH);
		employees.add(seniorCustServExecutive);

		Manager manager = new Manager();
		department.addEmployee(manager);
		address = new Address();
		address.setDoorNo("#2 Unit No 123");
		address.setLane("2nd Cross Lane");
		address.setStreet("Ang Mo Kio Street");
		address.setCity("Singapore City");
		address.setState(state);
		manager.setEmployeeName("Benjamin Franklin");
		manager.setDateOfBirth(Calendar.getInstance().getTime());
		manager.setAddress(address);
		manager.addSubordinate(seniorCustServExecutive);
		seniorCustServExecutive.setManager(manager);
		employees.add(manager);

		CustomerServiceExecutive custServExecutive = new CustomerServiceExecutive();
		department.addEmployee(custServExecutive);
		address = new Address();
		address.setDoorNo("#3 Unit No 123");
		address.setLane("3rd Cross Lane");
		address.setStreet("Ang Mo Kio Street");
		address.setCity("Singapore City");
		address.setState(state);
		custServExecutive.setEmployeeName("Earnest Rutherford");
		custServExecutive.setDateOfBirth(Calendar.getInstance().getTime());
		custServExecutive.setAddress(address);
		employees.add(custServExecutive);

		service.persistEmployees(employees);
	}
}
[/code]
Output:

