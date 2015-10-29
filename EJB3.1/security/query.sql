buse supermarket;
CREATE TABLE users (
username varchar(20) NOT NULL PRIMARY KEY,
password varchar(20) NOT NULL
);
CREATE TABLE roles (
rolename varchar(20) NOT NULL PRIMARY KEY
);
CREATE TABLE users_roles (
username varchar(20) NOT NULL,
rolename varchar(20) NOT NULL,
PRIMARY KEY (username, rolename),
CONSTRAINT users_roles_fk1 FOREIGN KEY (username) REFERENCES users (username),
CONSTRAINT users_roles_fk2 FOREIGN KEY (rolename) REFERENCES roles (rolename)
);

INSERT INTO `supermarket`.`users` (`username`, `password`) VALUES ('first_user', 'password');
INSERT INTO `supermarket`.`roles` (`rolename`) VALUES ('user_role');
INSERT INTO `supermarket`.`users_roles` (`username`, `rolename`) VALUES ('first_user', 'user_role');

INSERT INTO `supermarket`.`users` (`username`, `password`) VALUES ('admin_user', 'password');
INSERT INTO `supermarket`.`roles` (`rolename`) VALUES ('admin_role');
INSERT INTO `supermarket`.`users_roles` (`username`, `rolename`) VALUES ('admin_user', 'admin_role');
COMMIT;