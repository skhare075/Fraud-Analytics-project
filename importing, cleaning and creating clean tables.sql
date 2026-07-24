-- creating schema as banking.
CREATE SCHEMA IF NOT EXISTS banking;

CREATE TABLE banking.transactions_raw (
    transaction_id BIGINT,
    transaction_date TIMESTAMP,
    client_id BIGINT,
    card_id BIGINT,
    amount TEXT,
    use_chip TEXT,
    merchant_id BIGINT,
    merchant_city TEXT,
    merchant_state TEXT,
    zip TEXT,
    mcc BIGINT,
    errors TEXT
);

--checking first 10 rows
SELECT *
FROM banking.transactions_raw
LIMIT 10;

--creating clean transactions table
CREATE TABLE banking.transactions_clean AS
SELECT
    transaction_id,
    transaction_date,

    EXTRACT(YEAR FROM transaction_date)::INT  AS year,
    EXTRACT(MONTH FROM transaction_date)::INT AS month,
    EXTRACT(DAY FROM transaction_date)::INT    AS day,
    EXTRACT(HOUR FROM transaction_date)::INT   AS hour,

    client_id,
    card_id,

    REPLACE(amount, '$', '')::NUMERIC(12,2) AS amount,

    use_chip,

    merchant_id,
    merchant_city,
    merchant_state,

    mcc,

    CASE
        WHEN errors IS NULL OR TRIM(errors) = '' THEN 'No Error'
        ELSE TRIM(errors)
    END AS error_status

FROM banking.transactions_raw;

--creating users_raw table

CREATE TABLE banking.users_raw (
    id TEXT,
    current_age TEXT,
    retirement_age TEXT,
    birth_year TEXT,
    birth_month TEXT,
    gender TEXT,
    address TEXT,
    latitude TEXT,
    longitude TEXT,
    per_capita_income TEXT,
    yearly_income TEXT,
    total_debt TEXT,
    credit_score TEXT,
    num_credit_cards TEXT
);

-- creating cards_raw table

CREATE TABLE banking.cards_raw (
    id TEXT,
    client_id TEXT,
    card_brand TEXT,
    card_type TEXT,
    card_number TEXT,
    expires TEXT,
    cvv TEXT,
    has_chip TEXT,
    num_cards_issued TEXT,
    credit_limit TEXT,
    acct_open_date TEXT,
    year_pin_last_changed TEXT,
    card_on_dark_web TEXT
);

--checking first 10 rows
SELECT *
FROM banking.users_raw
LIMIT 10;

SELECT *
FROM banking.cards_raw
LIMIT 10;

--removing 1st row as headers
DELETE FROM banking.users_raw
WHERE id = 'id';

DELETE FROM banking.cards_raw
WHERE id = 'id';

--creating clean users table
CREATE TABLE banking.users_clean AS
SELECT
    id::INTEGER AS client_id,
    current_age::SMALLINT AS current_age,
    retirement_age::SMALLINT AS retirement_age,
    birth_year::SMALLINT AS birth_year,
    birth_month::SMALLINT AS birth_month,
    gender,
    address,
    latitude::DOUBLE PRECISION AS latitude,
    longitude::DOUBLE PRECISION AS longitude,
    REPLACE(per_capita_income, '$', '')::INTEGER AS per_capita_income,
    REPLACE(yearly_income, '$', '')::INTEGER AS yearly_income,
    REPLACE(total_debt, '$', '')::INTEGER AS total_debt,
    credit_score::SMALLINT AS credit_score,
    num_credit_cards::SMALLINT AS num_credit_cards
FROM banking.users_raw;

--creating clean cards table
CREATE TABLE banking.cards_clean AS
SELECT
    id::INTEGER AS card_id,
    client_id::INTEGER AS client_id,
    card_brand,
    card_type,
    card_number,
    expires, 
    cvv::SMALLINT AS cvv,
    has_chip,
    num_cards_issued::SMALLINT AS num_cards_issued,
    REPLACE(credit_limit, '$', '')::INTEGER AS credit_limit,
    acct_open_date, 
    year_pin_last_changed::SMALLINT AS year_pin_last_changed,
    card_on_dark_web
FROM banking.cards_raw;

-- creating fraud_labels_raw table
CREATE TABLE banking.fraud_labels_clean (
    transaction_id TEXT,
    fraud_label TEXT
);


--changing name from clean to raw
ALTER TABLE banking.fraud_labels_clean
RENAME TO fraud_labels_raw;

--checking 10 rows
SELECT *
FROM banking.fraud_labels_raw
LIMIT 10;

--deleting 1st row
DELETE FROM banking.fraud_labels_raw
WHERE transaction_id = 'transaction_id';

-- creating fraud_labels_clean table
CREATE TABLE banking.fraud_labels_clean AS
SELECT
    transaction_id::INTEGER AS transaction_id,
    fraud_label
FROM banking.fraud_labels_raw;

--creating mcc_codes_raw(clean) table
CREATE TABLE banking.mcc_codes_clean (
    mcc_code INTEGER,
    mcc_description TEXT
);

--verify top 10 rows
SELECT *
FROM banking.mcc_codes_clean
LIMIT 10;

--changing column name from mcc_codes to mcc as its used in code everywhere
ALTER TABLE banking.mcc_codes_clean
RENAME COLUMN mcc_code TO mcc;

--creating primary keys
ALTER TABLE banking.users_clean
ADD CONSTRAINT users_clean_pk PRIMARY KEY (client_id);

ALTER TABLE banking.cards_clean
ADD CONSTRAINT cards_clean_pk PRIMARY KEY (card_id);

ALTER TABLE banking.transactions_clean
ADD CONSTRAINT transactions_clean_pk PRIMARY KEY (transaction_id);

ALTER TABLE banking.fraud_labels_clean
ADD CONSTRAINT fraud_labels_clean_pk PRIMARY KEY (transaction_id);

ALTER TABLE banking.mcc_codes_clean
ADD CONSTRAINT mcc_codes_clean_pk PRIMARY KEY (mcc);

--creating foreign keys
ALTER TABLE banking.cards_clean
ADD CONSTRAINT cards_clean_client_fk
FOREIGN KEY (client_id) REFERENCES banking.users_clean(client_id);

ALTER TABLE banking.transactions_clean
ADD CONSTRAINT transactions_client_fk
FOREIGN KEY (client_id) REFERENCES banking.users_clean(client_id);

ALTER TABLE banking.transactions_clean
ADD CONSTRAINT transactions_card_fk
FOREIGN KEY (card_id) REFERENCES banking.cards_clean(card_id);

ALTER TABLE banking.transactions_clean
ADD CONSTRAINT transactions_mcc_fk
FOREIGN KEY (mcc) REFERENCES banking.mcc_codes_clean(mcc);

ALTER TABLE banking.fraud_labels_clean
ADD CONSTRAINT fraud_labels_txn_fk
FOREIGN KEY (transaction_id) REFERENCES banking.transactions_clean(transaction_id);

--creating a view
CREATE OR REPLACE VIEW banking.v_transactions_analytics AS
SELECT
    -- transaction identifiers and time
    t.transaction_id,
    t.transaction_date,
    t.year,
    t.month,
    t.day,
    t.hour,

    -- customer information
    t.client_id,
    u.current_age,
    u.gender,
    u.yearly_income,
    u.total_debt,
    u.credit_score,
    u.num_credit_cards,
	u.latitude,
    u.longitude,

    -- card information
    t.card_id,
    c.card_brand,
    c.card_type,
    c.has_chip,
    c.credit_limit,
    c.acct_open_date,
    c.year_pin_last_changed,
    c.card_on_dark_web,

    -- transaction amount and merchant details
    t.amount,
    t.merchant_id,
    t.merchant_city,
    t.merchant_state,
    t.mcc,
    m.mcc_description,

    -- transaction status / fraud
    t.error_status,
    f.fraud_label

FROM banking.transactions_clean t
LEFT JOIN banking.users_clean u
    ON t.client_id = u.client_id
LEFT JOIN banking.cards_clean c
    ON t.card_id = c.card_id
LEFT JOIN banking.mcc_codes_clean m
    ON t.mcc = m.mcc
LEFT JOIN banking.fraud_labels_clean f
    ON t.transaction_id = f.transaction_id;

--verifying view
	SELECT *
FROM banking.v_transactions_analytics
LIMIT 20;
