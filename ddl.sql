CREATE TABLE IF NOT EXISTS bank (
	numbers INTEGER NOT NULL,
	names VARCHAR(50) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (numbers)
);

CREATE TABLE IF NOT EXISTS agency (
	bank_numbers INTEGER NOT NULL,
	numbers INTEGER NOT NULL,
	names VARCHAR(80) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (bank_numbers,numbers),
	FOREIGN KEY (bank_numbers) REFERENCES bank (numbers)
);

CREATE TABLE IF NOT EXISTS client (
	numbers BIGSERIAL PRIMARY KEY,
	names VARCHAR(120) NOT NULL,
	email VARCHAR(250) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS checking_account (
	bank_numbers INTEGER NOT NULL,
	agency_numbers INTEGER NOT NULL,
	numbers BIGINT NOT NULL,
	digit SMALLINT NOT NULL,
	client_numbers BIGINT NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (bank_numbers,agency_numbers,numbers,digit,client_numbers),
	FOREIGN KEY (bank_numbers,agency_numbers) REFERENCES agency (bank_numbers,numbers),
	FOREIGN KEY (client_numbers) REFERENCES client (numbers)
);

CREATE TABLE IF NOT EXISTS transaction_type (
	id SMALLSERIAL PRIMARY KEY,
	names VARCHAR(50) NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS client_transactions (
	id BIGSERIAL PRIMARY KEY,
	bank_numbers INTEGER NOT NULL,
	agency_numbers INTEGER NOT NULL,
	checking_account_numbers BIGINT NOT NULL,
	checking_account_digit SMALLINT NOT NULL,
	client_numbers BIGINT NOT NULL,
	transaction_type_id SMALLINT NOT NULL,
	valor NUMERIC(15,2) NOT NULL,
	date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (bank_numbers,agency_numbers,checking_account_numbers,checking_account_digit,client_numbers) REFERENCES checking_account(bank_numbers,agency_numbers,numbers,digit,client_numbers)
);
