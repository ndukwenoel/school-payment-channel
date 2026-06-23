import sqlite3
import os

db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "school_payment.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("ALTER TABLE payment_attempts ADD COLUMN receipt_url VARCHAR")
    conn.commit()
    print("Successfully added receipt_url to payment_attempts")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column receipt_url already exists.")
    else:
        print(f"Error: {e}")
finally:
    conn.close()
