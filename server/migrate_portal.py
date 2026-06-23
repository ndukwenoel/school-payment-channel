import sqlite3
import os

db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "school_payment.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS payment_bundles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference VARCHAR UNIQUE,
        total_amount FLOAT,
        status VARCHAR DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        school_id INTEGER REFERENCES schools(id)
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS payment_bundle_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bundle_id INTEGER REFERENCES payment_bundles(id),
        invoice_id INTEGER REFERENCES invoices(id),
        amount_allocated FLOAT
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS payment_plan_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER REFERENCES invoices(id),
        parent_id INTEGER REFERENCES users(id),
        proposed_plan TEXT,
        reason TEXT,
        status VARCHAR DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        school_id INTEGER REFERENCES schools(id)
    )
    ''')
    
    conn.commit()
    print("Successfully created new tables for payment bundles and plan requests.")
except sqlite3.OperationalError as e:
    print(f"Error: {e}")
finally:
    conn.close()
