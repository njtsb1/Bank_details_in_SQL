DROP TABLE IF EXISTS product_category CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS client_address CASCADE;
DROP TABLE IF EXISTS client_telephone CASCADE;
DROP TABLE IF EXISTS period_contact CASCADE;
DROP TABLE IF EXISTS status CASCADE;
DROP TABLE IF EXISTS request CASCADE;
DROP TABLE IF EXISTS request_product CASCADE;
DROP TABLE IF EXISTS request_status CASCADE;

CREATE TABLE IF NOT EXISTS product_category (
	id SMALLSERIAL NOT NULL,
	name VARCHAR(50) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT product_category_pk PRIMARY KEY (id),
	CONSTRAINT product_category_unique_1 UNIQUE (name)
);

CREATE OR REPLACE VIEW vw_product_category AS (
    SELECT  id,
            name,
            active
    FROM product_category
);

CREATE TABLE IF NOT EXISTS product (
	number_serie VARCHAR(50) NOT NULL,
	product_category_id INTEGER NOT NULL,
	name VARCHAR(100) NOT NULL,
	value NUMERIC(15,2) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT product_pk PRIMARY KEY (number_serie),
	CONSTRAINT product_category_fk_1 FOREIGN KEY (product_category_id) REFERENCES product_category(id),
	CONSTRAINT product_value_check_1 CHECK (value >= 0)
);

CREATE OR REPLACE VIEW vw_product AS (
    SELECT  number_serie,
            product_category_id,
            name,
            value,
            active
    FROM product
    WHERE value >= 0
) WITH LOCAL CHECK OPTION;

CREATE TABLE IF NOT EXISTS client (
	cpfcnpj VARCHAR(14) NOT NULL,
	name VARCHAR(150) NOT NULL,
	email VARCHAR(250) NOT NULL,
	password VARCHAR(50) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT client_pk PRIMARY KEY (cpfcnpj),
	CONSTRAINT client_email_check_1 UNIQUE (email)
);

CREATE OR REPLACE VIEW vw_client AS (
    SELECT  cpfcnpj,
            name,
            email,
            password,
            active
    FROM client
);

CREATE TABLE IF NOT EXISTS client_address (
	id BIGSERIAL NOT NULL,
	client_cpfcnpj VARCHAR(14) NOT NULL,
	zip_code VARCHAR(8) NOT NULL,
	public_place VARCHAR(200) NOT NULL,
	number VARCHAR(10) NOT NULL,
	complement VARCHAR(50),
	district VARCHAR(100) NOT NULL,
	city VARCHAR(100) NOT NULL,
	reference VARCHAR(250),
	delivery BOOLEAN NOT NULL DEFAULT FALSE,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT client_address_pk PRIMARY KEY (id),
	CONSTRAINT client_fk_1 FOREIGN KEY (client_cpfcnpj) REFERENCES client(cpfcnpj)
);

CREATE OR REPLACE VIEW vw_client_address AS (
    SELECT  client_cpfcnpj,
            zip_code,
            public_place,
            number,
            complement,
            district,
            city,
            reference,
            delivery,
            active
    FROM client_address
);

CREATE TABLE IF NOT EXISTS period_contact (
    id SMALLSERIAL NOT NULL,
    name VARCHAR(15) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT period_contact_pk PRIMARY KEY (id),
	CONSTRAINT period_contact_unique_1 UNIQUE (name)
);

CREATE OR REPLACE VIEW vw_period_contact AS (
    SELECT  id,
            name,
            active
    FROM period_contact
    WHERE active IS TRUE
) WITH LOCAL CHECK OPTION;

CREATE TABLE IF NOT EXISTS client_telephone (
	id BIGSERIAL NOT NULL,
	client_cpfcnpj VARCHAR(14) NOT NULL,
	ddd VARCHAR(2) NOT NULL,
	telephone VARCHAR(10) NOT NULL,
	branch VARCHAR(10),
	best_time SMALLINT,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT client_telephone_pk PRIMARY KEY (id),
	CONSTRAINT client_fk_1 FOREIGN KEY (client_cpfcnpj) REFERENCES client(cpfcnpj),
	CONSTRAINT period_contact_fk_1 FOREIGN KEY (best_time) REFERENCES period_contact(id),
	CONSTRAINT client_telephone_single UNIQUE (client_cpfcnpj,ddd,telephone,branch)
);

CREATE OR REPLACE VIEW vw_client_telephone AS (
    SELECT  client_cpfcnpj,
            ddd,
            telephone,
            branch,
            best_time,
            active
    FROM client_telephone
);

CREATE TABLE IF NOT EXISTS status (
	id SMALLSERIAL NOT NULL,
	name VARCHAR(20) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT status_pk PRIMARY KEY (id),
	CONSTRAINT status_unique_1 UNIQUE (name)
);

CREATE OR REPLACE VIEW vw_status AS (
    SELECT id, name, active
    FROM status
    WHERE active IS TRUE
) WITH CASCADED CHECK OPTION;

CREATE TABLE IF NOT EXISTS request (
	id BIGSERIAL NOT NULL,
	status_id SMALLINT NOT NULL,
	client_cpfcnpj VARCHAR(14) NOT NULL,
	value NUMERIC(15,2) NOT NULL,
	date_last_update TIMESTAMP WITHOUT TIME ZONE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT request_pk PRIMARY KEY (id),
	CONSTRAINT status_fk_1 FOREIGN KEY (status_id) REFERENCES status(id),
	CONSTRAINT client_fk_1 FOREIGN KEY (client_cpfcnpj) REFERENCES client(cpfcnpj),
	CONSTRAINT request_value_check_1 CHECK (value >= 0)
);

CREATE OR REPLACE VIEW vw_request AS (
    SELECT  status_id,
            client_cpfcnpj,
            value,
            date_last_update,
            date_creation
    FROM request
);

CREATE TABLE IF NOT EXISTS request_product (
	id BIGSERIAL NOT NULL,
	request_id BIGINT NOT NULL,
	product_number_serie VARCHAR(50) NOT NULL,
	product_category_id INTEGER NOT NULL,
	product_name VARCHAR(100) NOT NULL,
	product_value NUMERIC(15,2) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	date_modification TIMESTAMP WITHOUT TIME ZONE,
	CONSTRAINT request_product_pk PRIMARY KEY (id),
	CONSTRAINT product_fk_1 FOREIGN KEY (product_number_serie) REFERENCES product(number_serie),
	CONSTRAINT product_category_fk_1 FOREIGN KEY (product_category_id) REFERENCES product_category(id),
	CONSTRAINT request_product_product_value_check_1 CHECK (product_value >= 0)
);

CREATE OR REPLACE VIEW vw_request_product AS (
    SELECT  request_id,
            product_number_serie,
            product_category_id,
            product_name,
            product_value,
            active,
            date_creation,
            date_modification
    FROM request_product
    WHERE product_value >= 0
);

DROP VIEW IF EXISTS vw_request;
ALTER TABLE IF EXISTS request DROP CONSTRAINT IF EXISTS status_fk_1;
ALTER TABLE IF EXISTS request DROP COLUMN IF EXISTS status_id;

CREATE OR REPLACE VIEW vw_request AS (
    SELECT  client_cpfcnpj,
            value,
            date_last_update,
            date_creation
    FROM request
);

CREATE TABLE IF NOT EXISTS request_status (
	request_id BIGINT NOT NULL,
	status_id SMALLINT NOT NULL DEFAULT 1,
	date_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT request_status_pk PRIMARY KEY (request_id,status_id),
	CONSTRAINT request_fk_1 FOREIGN KEY (request_id) REFERENCES request(id),
	CONSTRAINT status_fk_1 FOREIGN KEY (status_id) REFERENCES status(id)
);

CREATE OR REPLACE VIEW vw_request_status AS (
    SELECT  request_id,
            status_id,
            date_creation
    FROM request_status
);

INSERT INTO vw_product_category (name) VALUES ('Home appliances') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Cell phones') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Computing') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Bed, Table and Bath') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Music') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Beauty and Perfumery') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Books') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Electronics') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Sports') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_product_category (name) VALUES ('Travels') ON CONFLICT (name) DO NOTHING;

INSERT INTO vw_status (name) VALUES ('initial') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Under analysis') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('On approval') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Okay') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('In production') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Ready for delivery') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('On Route') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Back') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Delivered') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_status (name) VALUES ('Called off') ON CONFLICT (name) DO NOTHING;

INSERT INTO vw_period_contact (name) VALUES ('Morning') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_period_contact (name) VALUES ('Afternoon') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_period_contact (name) VALUES ('Night') ON CONFLICT (name) DO NOTHING;
INSERT INTO vw_period_contact (name) VALUES ('Dawn') ON CONFLICT (name) DO NOTHING;
