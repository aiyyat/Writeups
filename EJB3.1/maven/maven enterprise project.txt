This is a Multi Maven Enterprise Archive Project which contains the following Maven Modules:
Application: This is the module that coordinates various other modules to generate an Enterprise Archive. This has a packaging type of ear. Following is its pom.xml.
[code language="xml"]
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.company.project</groupId>
		<artifactId>Parent</artifactId>
		<version>0.0.1-SNAPSHOT</version>
	</parent>
	<artifactId>Application</artifactId>
	<packaging>ear</packaging>
	<dependencies>
		<dependency>
			<groupId>org.company.project</groupId>
			<artifactId>Services</artifactId>
			<version>0.0.1-SNAPSHOT</version>
			<type>ejb</type>
		</dependency>
		<dependency>
			<groupId>org.company.project</groupId>
			<artifactId>Web</artifactId>
			<version>0.0.1-SNAPSHOT</version>
			<type>war</type>
		</dependency>
	</dependencies>
	<!-- Used to define the lib folder under META-INF which is auto loaded by 
		the EJB Class loader -->
	<build>
		<plugins>
			<plugin>
				<artifactId>maven-ear-plugin</artifactId>
				<version>2.7</version>
				<configuration>
					<version>6</version>
					<defaultLibBundleDir>lib</defaultLibBundleDir>
					<archive>
						<manifest>
							<addClasspath>true</addClasspath>
						</manifest>
					</archive>
					<modules>
						<jarModule>
							<groupId>org.company.project</groupId>
							<artifactId>DomainModel</artifactId>
						</jarModule>
						<jarModule>
							<groupId>org.company.project</groupId>
							<artifactId>Interfaces</artifactId>
						</jarModule>
					</modules>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>
[/code]
A very bit about class loading.
The bootstrap Classloader is the heighest level of class loader, followed by the Extension and the System Classloader. The classloader that follows are the ones that actually load the packages that we deploy within our Application Servers.
The Application Server Classloaders usually follow the Deligation model to load its classes. A Class already loaded is never loaded once again. When a class is to be loaded the Classloader first checks if it has already been loaded by one of its parent Classloader by browsing though in its cache. If so, it uses that loaded class else it loads again. Similarly a loaded class is in loadable scope only if is loaded by its parent. A class loaded by one WAR within an EAR is not visible to another WAR in the same EAR at the same level. In effect they get loaded by different Classloaders. EJBs loaded by the class loader are application scoped since EJB class loaders are usually the direct child of an App Servler Classloader. So the classes loaded by EJBs are typically visible to the WAR Classloaders. 
With EJB 3.1 EJBs can very well be packaged within a WAR archive.
For an EAR in general the package archives ie the WAR and EJB modules defined in the application.xml deployment descriptor gets loaded and so are the jars within the META-INF/lib folder, which are achived with the aforementioned maven-ear-plugins defaultLibBundleDir.
While a WAR has a folder named named WEB-INF/lib to store its jars or within its META-INF, an ejb-jar or a jar has its packaged jars defined within the manifest.mf file inside its META-INF folder. 
Domain Model: This module contains all the Entities that make up the Domain model of this project. This module in effect produces a JAR archive.
Interfaces: This module consitutes the Remote interfaces that are used to expose the services to the remote world. In ordered to ship the interfaces to any client code one can just provide the jar produced by this module.
Services: Service classes are written into this module.
Web: UI. Produces a WAR.
Few of the design patterns used in this project to demostrate few of the good practises are the EntityDao Pattern which is an Allotropic form of Bridge pattern. The bridge pattern is one which is meant to decouple the abstraction from its actual implementation. DAO or Data access Pattern is usually written inorder to be able to vary the access to data in accordance to the source of data. The interface that define all the common behaviours are defined in the GenericDao interface. below is that class.
[code language="java"]
public interface GenericDao<E, K> {
	void persist(E entity);

	void remove(E entity);

	E findById(K id);
	
	List<E> findAll();
}
[/code]
Here E is used to define the Entity Class type and K defines the primary key class. The JPA implementation of this DAO is as below.
[code language="java"]
public abstract class JpaDao<E, K> implements GenericDao<E, K> {
	protected Class<E> entityClass;

	@PersistenceContext
	protected EntityManager entityManager;

	@SuppressWarnings("unchecked")
	public JpaDao() {
		ParameterizedType genericSuperclass = (ParameterizedType) getClass()
				.getGenericSuperclass();
		this.entityClass = (Class<E>) genericSuperclass
				.getActualTypeArguments()[0];
	}

	public void persist(E entity) {
		entityManager.persist(entity);
	}

	public void remove(E entity) {
		entityManager.remove(entity);
	}

	@SuppressWarnings("unchecked")
	public List<E> findAll() {
		Query q = entityManager.createQuery("SELECT e FROM "
				+ entityClass.getName() + " e");
		return (List<E>) q.getResultList();
	}

	public E findById(K id) {
		return entityManager.find(entityClass, id);
	}
}
[/code]
I have once had a requirement where there are multiple data sources. This can be achieved by have a Data source or persistence unit specific implementation of the JpaDao, one for each Persistence Units. The class provides an implementation of the abstract getEntityManager() implementaion of the JpaDao abstract class. The polymorphic behaviour of DAO implementation allows us to use different EntityManager in accordance to the persistence units defined. 
2 things to remember are 
1) ParameterizedType genericSuperclass = (ParameterizedType) getClass().getGenericSuperclass(); is for simple hierarchy. For a complex hierarchy the getGenericSuperclass() is to be called twice.
2) this.entityClass = (Class<E>) genericSuperclass.getActualTypeArguments()[0] The parameter '0' represents the position of the Entity Class in the definition of the Hierarchy.Employee in the case of a GenericDao<Employee, Long>

The EmployeeDao implementation of the JpaDao is as follows
[code language="java"]
@Local
public interface EmployeeDao extends GenericDao<Employee, Long> {

}
[/code]
Implementation of the Dao. Here the Employee is the EntityClass, Long that defines Primary Key Class of the entity.
[code language="java"]
@Stateless
public class JPAEmployeeDao extends JpaDao<Employee, Long> implements
		EmployeeDao {
}
[/code]
This class can have other implementations that are specific to Employee Entity. For example if one has to query for the list of employees based on age of findEmployeesByAge(int age), one can define it in the Dao, EmployeeDao in our case. This definition ensures that whatever be the underlying implmentation(JPA in our case), he has to define it. 
Another highlight is the test case which is used to unit test our EJB and JPAs. For this we make use of an EJB 3.1 feature called Embedded EJB Container which automagically deploys EJB Beans based on their Target Annotations and as in any Maven project one can find the test case in the test/java folders.
[code language="java"]

public class EmployeeTest {
	private static EJBContainer container;

	@BeforeClass
	public static void setUpClass() throws Exception {
		container = EJBContainer.createEJBContainer();
		System.out.println("Starting container");
	}

	@AfterClass
	public static void tearDownClass() throws Exception {
		container.close();
		System.out.println("Shutting container");
	}

	@Before
	public void setUp() {
	}

	@After
	public void tearDown() {
	}

	@Test
	public void testCreate() throws Exception {
		EmployeeDao dao = (EmployeeDao) container
				.getContext()
				.lookup("java:global/Services/JPAEmployeeDao!org.company.project.dao.base.EmployeeDao");
		Employee employee = new Employee();
		employee.setEmployeeName("Lee Bruise");
		employee.setDateOfBirth(Calendar.getInstance().getTime());
		dao.persist(employee);
		TestCase.assertEquals("Lee Bruise", dao.findById(employee.getId())
				.getEmployeeName());
	}
}
[/code]

