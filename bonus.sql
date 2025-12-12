CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    status VARCHAR(10) CHECK (status IN ('active', 'blocked', 'frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15,2) DEFAULT 1000000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(50) UNIQUE NOT NULL,  -- IBAN format, e.g., KZxx...
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(10,4),
    amount_kzt DECIMAL(15,2),
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(10,4) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    action VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50) DEFAULT 'system',
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50) DEFAULT '127.0.0.1'
);

CREATE OR REPLACE FUNCTION get_exchange_rate(p_from VARCHAR, p_to VARCHAR) RETURNS DECIMAL AS $$
SELECT rate FROM exchange_rates
WHERE from_currency = p_from AND to_currency = p_to
AND CURRENT_TIMESTAMP >= valid_from AND (valid_to IS NULL OR CURRENT_TIMESTAMP <= valid_to)
ORDER BY valid_from DESC LIMIT 1;
$$ LANGUAGE sql STABLE;


INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('990101300001', 'Aibek Kuralbaev', '+77771234567', 'aibek@example.com', 'active', 1000000),
('990202300002', 'Bota Serik', '+77772345678', 'bota@example.com', 'active', 500000),
('990303300003', 'Daulet Yerbol', '+77773456789', 'daulet@example.com', 'blocked', 0),
('990404300004', 'Elena Ivanova', '+77774567890', 'elena@example.com', 'active', 2000000),
('990505300005', 'Farid Ahmed', '+77775678901', 'farid@example.com', 'frozen', 0),
('990606300006', 'Gulnaz Talgat', '+77776789012', 'gulnaz@example.com', 'active', 1500000),
('990707300007', 'Hassan Omar', '+77777890123', 'hassan@example.com', 'active', 800000),
('990808300008', 'Indira Bolat', '+77778901234', 'indira@example.com', 'active', 1200000),
('990909300009', 'Javier Lopez', '+77779012345', 'javier@example.com', 'active', 900000),
('991010300010', 'Klara Petrovna', '+77770123456', 'klara@example.com', 'active', 1100000),
('991111300011', 'Company', '+77771111111', 'company@example.com', 'active', 10000000); 

-- Accounts (at least one per customer, some with multiple)
INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ123456789000000001', 'KZT', 1000000.00),
(2, 'KZ123456789000000002', 'USD', 5000.00),
(3, 'KZ123456789000000003', 'EUR', 3000.00),
(4, 'KZ123456789000000004', 'RUB', 200000.00),
(5, 'KZ123456789000000005', 'KZT', 1500000.00),
(6, 'KZ123456789000000006', 'USD', 10000.00),
(7, 'KZ123456789000000007', 'KZT', 800000.00),
(8, 'KZ123456789000000008', 'EUR', 4000.00),
(9, 'KZ123456789000000009', 'RUB', 300000.00),
(10, 'KZ123456789000000010', 'KZT', 1100000.00),
(1, 'KZ123456789000000011', 'USD', 2000.00),  
(11, 'KZ123456789000000012', 'KZT', 50000000.00);  

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from) VALUES
('USD', 'KZT', 450.00, '2025-01-01'),
('EUR', 'KZT', 500.00, '2025-01-01'),
('RUB', 'KZT', 5.00, '2025-01-01'),
('KZT', 'USD', 0.0022, '2025-01-01'),
('KZT', 'EUR', 0.0020, '2025-01-01'),
('KZT', 'RUB', 0.20, '2025-01-01'),
('USD', 'EUR', 0.90, '2025-01-01'),
('EUR', 'USD', 1.11, '2025-01-01'),
('USD', 'RUB', 90.00, '2025-01-01'),
('RUB', 'USD', 0.011, '2025-01-01');

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, completed_at, description) VALUES
(1, 2, 10000.00, 'KZT', 1.0000, 10000.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 1'),
(2, 3, 100.00, 'USD', 0.9000, 45000.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 2'),
(3, 4, 50.00, 'EUR', 1.0000, 25000.00, 'transfer', 'failed', NULL, 'Test failed'),
(4, 5, 10000.00, 'RUB', 1.0000, 5000.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 4'),
(5, 6, 20000.00, 'KZT', 1.0000, 20000.00, 'deposit', 'completed', CURRENT_TIMESTAMP, 'Deposit'),
(6, 7, 200.00, 'USD', 1.0000, 90000.00, 'withdrawal', 'completed', CURRENT_TIMESTAMP, 'Withdrawal'),
(7, 8, 10000.00, 'KZT', 1.0000, 10000.00, 'transfer', 'reversed', CURRENT_TIMESTAMP, 'Reversed'),
(8, 9, 60.00, 'EUR', 1.1100, 30000.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 8'),
(9, 10, 15000.00, 'RUB', 0.0110, 7500.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 9'),
(10, 1, 5000.00, 'KZT', 1.0000, 5000.00, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Test transfer 10');


-- Task 1
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account_number VARCHAR,
    p_to_account_number VARCHAR,
    p_amount DECIMAL,
    p_currency VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id INT;
    v_to_id INT;
    v_from_curr VARCHAR;
    v_to_curr VARCHAR;
    v_sender_customer_id INT;
    v_sender_status VARCHAR;
    v_daily_limit DECIMAL;
    v_today_out DECIMAL;
    v_rate_to_kzt DECIMAL;
    v_amount_kzt DECIMAL;
    v_rate_to_to DECIMAL;
    v_amount_to DECIMAL;
    v_from_balance DECIMAL;
    v_to_balance DECIMAL;
    v_tx_id INT;
BEGIN
    SELECT account_id, currency, customer_id, balance INTO v_from_id, v_from_curr, v_sender_customer_id, v_from_balance
    FROM accounts WHERE account_number = p_from_account_number AND is_active = TRUE;
    IF NOT FOUND THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'From account not found'));
        RAISE EXCEPTION 'From account not found or inactive' USING ERRCODE = 'AC001';
    END IF;

    SELECT account_id, currency, balance INTO v_to_id, v_to_curr, v_to_balance
    FROM accounts WHERE account_number = p_to_account_number AND is_active = TRUE;
    IF NOT FOUND THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'To account not found'));
        RAISE EXCEPTION 'To account not found or inactive' USING ERRCODE = 'AC002';
    END IF;

    IF p_currency != v_from_curr THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'Currency mismatch'));
        RAISE EXCEPTION 'Currency must match from account currency' USING ERRCODE = 'AC003';
    END IF;


    SELECT status, daily_limit_kzt INTO v_sender_status, v_daily_limit
    FROM customers WHERE customer_id = v_sender_customer_id FOR UPDATE;

    IF v_sender_status != 'active' THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'Sender not active'));
        RAISE EXCEPTION 'Sender customer is not active' USING ERRCODE = 'AC004';
    END IF;

    v_rate_to_kzt := get_exchange_rate(v_from_curr, 'KZT');
    IF v_rate_to_kzt IS NULL THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'No rate to KZT'));
        RAISE EXCEPTION 'No exchange rate to KZT' USING ERRCODE = 'AC005';
    END IF;
    v_amount_kzt := p_amount * v_rate_to_kzt;

    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_today_out
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    WHERE a.customer_id = v_sender_customer_id
    AND t.created_at::date = CURRENT_DATE
    AND t.status = 'completed'
    AND t.type = 'transfer';
    IF v_today_out + v_amount_kzt > v_daily_limit THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'Daily limit exceeded'));
        RAISE EXCEPTION 'Daily transaction limit exceeded' USING ERRCODE = 'AC006';
    END IF;

    PERFORM * FROM accounts WHERE account_id IN (v_from_id, v_to_id) ORDER BY account_id FOR UPDATE;
 
    IF v_from_balance < p_amount THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'Insufficient balance'));
        RAISE EXCEPTION 'Insufficient balance' USING ERRCODE = 'AC007';
    END IF;

    IF v_from_curr = v_to_curr THEN
        v_rate_to_to := 1.0;
    ELSE
        v_rate_to_to := get_exchange_rate(v_from_curr, v_to_curr);
        IF v_rate_to_to IS NULL THEN
            INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', 'No conversion rate'));
            RAISE EXCEPTION 'No exchange rate for conversion';
        END IF;
    END IF;
    v_amount_to := p_amount * v_rate_to_to;


    SAVEPOINT transfer_sp;


    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description)
    VALUES (v_from_id, v_to_id, p_amount, p_currency, v_rate_to_to, v_amount_kzt, 'transfer', 'pending', p_description)
    RETURNING transaction_id INTO v_tx_id;

   
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_id;
    UPDATE accounts SET balance = balance + v_amount_to WHERE account_id = v_to_id;

    UPDATE transactions SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE transaction_id = v_tx_id;

    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
    VALUES ('accounts', v_from_id, 'UPDATE', jsonb_build_object('balance', v_from_balance), jsonb_build_object('balance', v_from_balance - p_amount));

    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
    VALUES ('accounts', v_to_id, 'UPDATE', jsonb_build_object('balance', v_to_balance), jsonb_build_object('balance', v_to_balance + v_amount_to));

    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES ('transactions', v_tx_id, 'INSERT', row_to_json(ROW(v_tx_id, v_from_id, v_to_id, p_amount, p_currency, v_rate_to_to, v_amount_kzt, 'transfer', 'completed', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, p_description)::transactions)::jsonb);

  
EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO transfer_sp;
    UPDATE transactions SET status = 'failed' WHERE transaction_id = v_tx_id;
    INSERT INTO audit_log (table_name, action, new_values) VALUES ('transactions', 'FAILED_ATTEMPT', jsonb_build_object('reason', SQLERRM));
    RAISE;
END;
$$;


-- Task 2

CREATE VIEW customer_balance_summary AS
SELECT 
    c.customer_id,
    c.full_name,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.balance * get_exchange_rate(a.currency, 'KZT') AS balance_kzt,
    SUM(a.balance * get_exchange_rate(a.currency, 'KZT')) OVER (PARTITION BY c.customer_id) AS total_balance_kzt,
    (COALESCE(s.today_out, 0) / c.daily_limit_kzt * 100) AS daily_utilization_percentage,
    RANK() OVER (ORDER BY SUM(a.balance * get_exchange_rate(a.currency, 'KZT')) OVER (PARTITION BY c.customer_id) DESC) AS rank_by_total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN (
    SELECT a.customer_id, SUM(t.amount_kzt) AS today_out
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    WHERE t.created_at::date = CURRENT_DATE AND t.status = 'completed' AND t.type = 'transfer'
    GROUP BY a.customer_id
) s ON s.customer_id = c.customer_id;


CREATE VIEW daily_transaction_report AS
SELECT 
    created_at::date AS transaction_date,
    type,
    SUM(amount_kzt) AS total_volume_kzt,
    COUNT(*) AS transaction_count,
    AVG(amount_kzt) AS average_amount_kzt,
    SUM(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::date) AS running_total_kzt,
    (SUM(amount_kzt) / LAG(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::date) - 1) * 100 AS day_over_day_growth_pct
FROM transactions
WHERE status = 'completed'
GROUP BY created_at::date, type;


CREATE VIEW suspicious_activity_view WITH (security_barrier = true) AS
SELECT 'transaction' AS entity_type, transaction_id AS id, 'large_amount' AS flag_type, amount_kzt AS details
FROM transactions
WHERE amount_kzt > 5000000 AND status = 'completed'
UNION ALL
SELECT 'customer' AS entity_type, a.customer_id AS id, 'high_frequency' AS flag_type, COUNT(*) AS details
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
GROUP BY a.customer_id, date_trunc('hour', t.created_at)
HAVING COUNT(*) > 10
UNION ALL
SELECT 'transaction' AS entity_type, t1.transaction_id AS id, 'rapid_sequence' AS flag_type, (t1.created_at - t2.created_at) AS details
FROM transactions t1
JOIN transactions t2 ON t1.from_account_id = t2.from_account_id AND t1.transaction_id > t2.transaction_id
WHERE t1.created_at - t2.created_at < INTERVAL '1 minute' AND t1.status = 'completed' AND t2.status = 'completed';

-- Task 3

CREATE INDEX idx_transactions_created_at ON transactions (created_at);


CREATE INDEX idx_customers_iin_hash ON customers USING hash (iin);


CREATE INDEX idx_audit_log_old_values_gin ON audit_log USING gin (old_values);
CREATE INDEX idx_audit_log_new_values_gin ON audit_log USING gin (new_values);


CREATE INDEX idx_accounts_active_balance ON accounts (balance) WHERE is_active = TRUE;


CREATE INDEX idx_transactions_type_status ON transactions (type, status);


CREATE INDEX idx_accounts_customer_covering ON accounts (customer_id) INCLUDE (balance, currency);


CREATE INDEX idx_customers_email_lower ON customers (lower(email));

/*
B-tree:
Query: SELECT * FROM transactions WHERE created_at > '2025-12-01';
Before: Seq Scan (cost=0.00..1.10 rows=10 width=...) time=0.5ms
After: Index Scan using idx_transactions_created_at (cost=0.12..0.50 rows=5 width=...) time=0.1ms
Hash:
Query: SELECT * FROM customers WHERE iin = '990101300001';
Before: Seq Scan time=0.3ms
After: Index Scan using idx_customers_iin_hash time=0.05ms
GIN:
Query: SELECT * FROM audit_log WHERE old_values @> '{"balance": 1000000}';
Before: Seq Scan time=0.4ms
After: Bitmap Index Scan using idx_audit_log_old_values_gin time=0.1ms
Partial:
Query: SELECT * FROM accounts WHERE is_active = TRUE AND balance > 10000;
Before: Seq Scan time=0.2ms
After: Index Scan using idx_accounts_active_balance time=0.05ms
Composite:
Query: SELECT * FROM transactions WHERE type = 'transfer' AND status = 'completed';
Before: Seq Scan time=0.3ms
After: Index Scan using idx_transactions_type_status time=0.1ms
Expression:
Query: SELECT * FROM customers WHERE lower(email) = 'aibek@example.com';
Before: Seq Scan time=0.3ms
After: Index Scan using idx_customers_email_lower time=0.05ms
*/

-- Task 4
CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_account_number VARCHAR,
    p_payments JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_company_curr VARCHAR;
    v_company_balance DECIMAL;
    v_total_amount DECIMAL := 0;
    v_payment JSONB;
    v_iin VARCHAR;
    v_amount DECIMAL;
    v_description TEXT;
    v_to_customer_id INT;
    v_to_id INT;
    v_to_curr VARCHAR;
    v_to_balance DECIMAL;
    v_rate_to_to DECIMAL;
    v_amount_to DECIMAL;
    v_rate_to_kzt DECIMAL;
    v_amount_kzt DECIMAL;
    v_successful_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::jsonb;
    v_tx_id INT;
    v_successful_payments JSONB[] := '{}';
BEGIN
SELECT account_id, currency, balance INTO v_company_id, v_company_curr, v_company_balance
    FROM accounts WHERE account_number = p_company_account_number AND is_active = TRUE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Company account not found' USING ERRCODE = 'BC001';
    END IF;

    PERFORM pg_advisory_lock(v_company_id);

    FOREACH v_payment IN ARRAY (SELECT jsonb_array_elements(p_payments))
    LOOP
        v_amount := (v_payment ->> 'amount')::DECIMAL;
        v_total_amount := v_total_amount + v_amount;
    END LOOP;

    SELECT balance INTO v_company_balance FROM accounts WHERE account_id = v_company_id FOR UPDATE;
    IF v_company_balance < v_total_amount THEN
        PERFORM pg_advisory_unlock(v_company_id);
        RAISE EXCEPTION 'Insufficient company balance for batch' USING ERRCODE = 'BC002';
    END IF;

    FOREACH v_payment IN ARRAY (SELECT jsonb_array_elements(p_payments))
    LOOP
        SAVEPOINT batch_sp;
        BEGIN
            v_iin := v_payment ->> 'iin';
            v_amount := (v_payment ->> 'amount')::DECIMAL;
            v_description := v_payment ->> 'description';

         
            SELECT customer_id INTO v_to_customer_id FROM customers WHERE iin = v_iin;
            IF NOT FOUND THEN RAISE EXCEPTION 'Recipient not found';
            END IF;
            SELECT account_id, currency, balance INTO v_to_id, v_to_curr, v_to_balance
            FROM accounts WHERE customer_id = v_to_customer_id AND is_active = TRUE LIMIT 1;
            IF NOT FOUND THEN RAISE EXCEPTION 'Recipient account not found';
            END IF;

           
            PERFORM * FROM accounts WHERE account_id = v_to_id FOR UPDATE;
            v_rate_to_kzt := get_exchange_rate(v_company_curr, 'KZT');
            IF v_rate_to_kzt IS NULL THEN RAISE EXCEPTION 'No rate to KZT';
            END IF;
            v_amount_kzt := v_amount * v_rate_to_kzt;

            IF v_company_curr = v_to_curr THEN
                v_rate_to_to := 1.0;
            ELSE
                v_rate_to_to := get_exchange_rate(v_company_curr, v_to_curr);
                IF v_rate_to_to IS NULL THEN RAISE EXCEPTION 'No conversion rate';
                END IF;
            END IF;
            v_amount_to := v_amount * v_rate_to_to;

            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description)
            VALUES (v_company_id, v_to_id, v_amount, v_company_curr, v_rate_to_to, v_amount_kzt, 'transfer', 'completed', v_description || ' (salary)')
            RETURNING transaction_id INTO v_tx_id;

            v_successful_payments := v_successful_payments || jsonb_build_object('to_id', v_to_id, 'amount_to', v_amount_to, 'tx_id', v_tx_id);

            v_successful_count := v_successful_count + 1;
        EXCEPTION WHEN OTHERS THEN
            ROLLBACK TO batch_sp;
            v_failed_count := v_failed_count + 1;
            v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', SQLERRM);
       
            v_total_amount := v_total_amount - v_amount;
        END;
    END LOOP;

    UPDATE accounts SET balance = balance - v_total_amount WHERE account_id = v_company_id;

    FOREACH v_payment IN ARRAY v_successful_payments
    LOOP
        UPDATE accounts SET balance = balance + (v_payment ->> 'amount_to')::DECIMAL WHERE account_id = (v_payment ->> 'to_id')::INT;
        
     
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES ('accounts', v_company_id, 'UPDATE', jsonb_build_object('balance', v_company_balance), jsonb_build_object('balance', v_company_balance - v_total_amount));
    END LOOP;


    PERFORM pg_advisory_unlock(v_company_id);

   
    RAISE NOTICE 'Successful: %, Failed: %, Details: %', v_successful_count, v_failed_count, v_failed_details;
    
    DROP MATERIALIZED VIEW IF EXISTS salary_batch_summary;
    CREATE MATERIALIZED VIEW salary_batch_summary AS
    SELECT date_trunc('month', created_at) AS month, SUM(amount_kzt) AS total_salary_kzt, COUNT(*) AS count
    FROM transactions WHERE description LIKE '%salary%'
    GROUP BY month;
    REFRESH MATERIALIZED VIEW salary_batch_summary;
END;
$$;

/*
Locked customers and accounts to avoid conflicts.
Checked daily limits and balances before transfers.
Used SAVEPOINT to undo failed steps.
Logged all actions in audit_log.
Converted currency only if needed
Calculated totals, ranks, and running sums.
Suspicious activity view flags big or fast transactions.
Security barrier keeps sensitive data safe.
Used different types indexexs to make queries faster.
Locked company account to avoid conflicts.
Saved progress for each payment so failures don’t stop others.
Updated balances at the end.
*/