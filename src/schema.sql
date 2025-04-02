-- Core schema for OpenCBS Cloud

-- Clients table
CREATE TABLE IF NOT EXISTS clients (
    id TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    account_number TEXT UNIQUE NOT NULL,
    currency TEXT NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    account_type TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id)
);

-- Loans table
CREATE TABLE IF NOT EXISTS loans (
    id TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    account_id TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    term_months INTEGER NOT NULL,
    status TEXT NOT NULL,
    disbursement_date TIMESTAMP,
    maturity_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id),
    FOREIGN KEY (account_id) REFERENCES accounts(id)
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    loan_id TEXT,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (loan_id) REFERENCES loans(id)
);

-- Documents table (references to R2)
CREATE TABLE IF NOT EXISTS documents (
    id TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    loan_id TEXT,
    document_type TEXT NOT NULL,
    r2_key TEXT NOT NULL,
    filename TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    size INTEGER NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id),
    FOREIGN KEY (loan_id) REFERENCES loans(id)
);

-- Create indexes
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_accounts_client_id ON accounts(client_id);
CREATE INDEX idx_loans_client_id ON loans(client_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_loan_id ON transactions(loan_id);
CREATE INDEX idx_documents_client_id ON documents(client_id);
CREATE INDEX idx_documents_loan_id ON documents(loan_id); 