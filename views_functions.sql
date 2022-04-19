CREATE OR REPLACE VIEW vw_banks AS (
    SELECT number, name, active
    FROM bank
);

CREATE OR REPLACE VIEW vw_agencys AS (
    SELECT bank_number, number, name, active
    FROM agency
);

CREATE OR REPLACE VIEW vw_banks_agencys (
    bank_number,
    bank_name,
    agency_number,
    agency_name,
    agency_active
) AS (
    SELECT  bank.number AS bank_number,
            bank.name AS bank_name,
            agency.number AS agency_number,
            agency.name AS agency_name,
            agency.active AS agency_active
    FROM bank
    LEFT JOIN agency ON agency.bank_number = bank.number
);

CREATE OR REPLACE VIEW vw_client AS (
    SELECT number, name, email, active
    FROM client
);

CREATE OR REPLACE VIEW vw_type_transaction AS (
    SELECT id, name
    FROM type_transaction
);

CREATE OR REPLACE VIEW vw_checking_account AS (
    SELECT  bank_number,
            agency_number,
            number,
            digit,
            client_number,
            active
    FROM checking_account
);

CREATE OR REPLACE VIEW client_checking_account (
    bank_number,
    bank_name,
    agency_number,
    agency_name,
    checking_account_number,
    checking_account_digit,
    client_number,
    client_name
) AS (
        SELECT  bank.number AS bank_number,
                bank.name AS bank_name,
                agency.number AS agency_number,
                agency.name AS agency_name,
                checking_account.number AS checking_account_number,
                checking_account.digit AS checking_account_digit,
                client.number AS client_number,
                client.name AS client_name
        FROM client
        JOIN checking_account ON checking_account.client_number = client.number
        JOIN agency ON agency.number = checking_account.agency_number
        JOIN bank ON bank.number = agency.bank_number AND bank.number = checking_account.bank_number
);

CREATE OR REPLACE VIEW vw_client_transactions (
    client_number,
    client_name,
    bank_name,
    agency_name,
    checking_account_number,
    checking_account_digit,
    transaction_name,
    value
    
) AS (
    SELECT  client.number AS client_number,
            client.name AS client_name,
            bank.name AS bank_name,
            agency.name AS agency_name,
            client_transactions.checking_account_number,
            client_transactions.checking_account_digit,
            type_transaction.name AS transaction_name,
            client_transactions.value
    FROM client
    JOIN client_transactions ON client_transactions.client_number = client.number
    JOIN agency ON agency.number = client_transactions.agency_number
    JOIN bank ON bank.number = client_transactions.bank_number
    JOIN type_transaction ON type_transaction.id = client_transactions.type_transaction_id
);

CREATE OR REPLACE FUNCTION bank_manage(p_number INTEGER,p_name VARCHAR(50),p_active BOOLEAN)
RETURNS TABLE (bank_number INTEGER, bank_name VARCHAR(50), bank_active BOOLEAN)
LANGUAGE PLPGSQL
SECURITY DEFINER
RETURNS NULL ON NULL INPUT
AS $$
BEGIN
    -- THE COMMAND BELOW WILL PERFORM THE INSERT OR UPDATE OF THE BANK
    -- THE ON CONFLICT COMMAND CAN BE USED TO MAKE NOTHING (OUT OF NOTHING)
    -- OR TO PERFORM AN UPDATE IN OUR CASE.
    INSERT INTO bank (number, name, active)
    VALUES (p_number, p_name, p_active)
    ON CONFLICT (number) DO UPDATE SET name = p_name, active = p_active;
    
    -- WE MUST RETURN A TABLE
    -- THE RETURN IN THIS CASE MUST BE A QUERY
    RETURN QUERY
        SELECT number, name, active
        FROM bank
        WHERE number = p_number;
END; $$;

CREATE OR REPLACE FUNCTION agency_manage(p_bank_number INTEGER, p_number INTEGER, p_name VARCHAR(80), p_active BOOLEAN)
RETURNS TABLE (bank_name VARCHAR, agency_number INTEGER, agency_name VARCHAR, agency_active BOOLEAN)
LANGUAGE PLPGSQL
SECURITY DEFINER
RETURNS NULL ON NULL INPUT
AS $$
DECLARE variable_bank_number INTEGER;
BEGIN
    -- HERE WE WILL VALIDATE THE EXISTENCE OF THE bank
    -- AND ESPECIALLY IF IT IS ACTIVE
    SELECT INTO variable_bank_number number
    FROM vw_banks
    WHERE number = p_bank_number
    AND active IS TRUE;
    
    -- IF WE GET RETURN FROM THE ABOVE COMMAND
    -- THEN THE BANK EXISTS AND IS ACTIVE
    -- AND WE CAN PROCEED WITH THE AGENCY INSERT
    IF variable_bank_number IS NOT NULL THEN
        -- THE COMMAND BELOW WILL PERFORM THE INSERT OR UPDATE OF THE bank
        -- THE ON CONFLICT COMMAND CAN BE USED TO DO NOTHING (DO NOTHING)
        -- OR TO PERFORM AN UPDATE IN OUR CASE.
        -- !!! PLEASE NOTE THAT THE UPDATE WILL ONLY BE PERFORMED IN THE FIELDS name AND active OF the agency !!!
        -- !!! CHALLENGE: HOW ABOUT IMPROVING THIS CODE TO BE POSSIBLE TO CHANGE AGENCY BANKS ???
        INSERT INTO agency (bank_number, number, name, active)
        VALUES (p_bank_number, p_number, p_name, p_active)
        ON CONFLICT (bank_number, number) DO UPDATE SET
        name = p_name,
        active = p_active;
    END IF;

    -- WE MUST RETURN A TABLE
    -- THE RETURN IN THIS CASE MUST BE A QUERY
    RETURN QUERY
        SELECT  bank.name AS bank_name, 
                agency.number AS agency_number, 
                agency.name AS agency_name, 
                agency.active AS agency_active
        FROM agency
        JOIN bank ON bank.number = agency.number
        WHERE agency.bank_number = p_bank_number
        AND agency.number = p_number;
END; $$;

CREATE OR REPLACE FUNCTION client_manage(p_number INTEGER, p_name VARCHAR(120), p_email VARCHAR(250), p_active BOOLEAN)
RETURNS BOOLEAN
LANGUAGE PLPGSQL
SECURITY DEFINER
CALLED ON NULL INPUT
AS $$
BEGIN
    -- WE WILL VALIDATE ONLY THE MOST IMPORTANT PARAMETERS
    IF p_number IS NULL OR p_name IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- WE WILL MAKE THE INSERT WITH NULL valueES TREATMENT
    INSERT INTO client (number, name, email, active)
    VALUES (p_number, p_name, COALESCE(p_email,CONCAT(p_name,'@no_email')), COALESCE(p_active,TRUE))
    ON CONFLICT (number) DO UPDATE SET name = p_name, email = CONCAT(p_name,'@no_email'), active = COALESCE(p_active,TRUE);
    
    RETURN TRUE;
END; $$;

-- !!! CHALLENGE
-- CHANGE THE NEWLY CREATED FUNCTION TO REGISTER CLIENTS WITH YOUR CURRENT ACCOUNT
-- FUNCTION STRUCTURE IS ALREADY BELOW
-- FIRST WE HAVE TO DELETE THE FUNCTION, BECAUSE IT ALREADY EXISTS WITH DIFFERENT PARAMETERS

DROP FUNCTION client_manage(p_number INTEGER, p_name VARCHAR(120), p_email VARCHAR(250), p_active BOOLEAN);

-- NOW WE MUST CREATE THE FUNCTION CONTEMPLATING ALL POSSIBLE VARIABLES
-- DON'T FORGET THAT IT IS IMPORTANT TO UPDATE SOME FIELDS IF THE CLIENT ALREADY EXISTS
CREATE OR REPLACE FUNCTION client_manage(
    p_bank_number INTEGER,
    p_agency_number INTEGER,
    p_client_number INTEGER,
    p_client_name VARCHAR(120),
    p_client_email VARCHAR(250),
    p_client_active BOOLEAN,
    p_checking_account_number BIGINT,
    p_checking_account_digit SMALLINT,
    p_checking_account_active BOOLEAN
)
RETURNS TABLE (
    bank_name VARCHAR,
    agency_name VARCHAR,
    client_name VARCHAR,
    checking_account_number BIGINT,
    checking_account_digit SMALLINT
)
LANGUAGE PLPGSQL
SECURITY DEFINER
RETURNS NULL ON NULL INPUT
AS $$
BEGIN
    -- YOUR CODE HERE
END; $$;
