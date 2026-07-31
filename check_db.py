import sqlite3

def check_db(db_name):
    try:
        conn = sqlite3.connect(db_name)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM expenses")
        print(f"Expenses count: {cursor.fetchone()[0]}")
            
    except Exception as e:
        print("Error:", e)

if __name__ == '__main__':
    check_db("school_payment.db")
