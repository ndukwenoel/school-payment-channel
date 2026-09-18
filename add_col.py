import sqlite3

c = sqlite3.connect('school_payment.db')
tables = [row[0] for row in c.execute("SELECT name FROM sqlite_master WHERE type='table'")]
for t in tables:
    try:
        c.execute(f"ALTER TABLE {t} ADD COLUMN updated_at DATETIME")
        print(f"Added updated_at to {t}")
    except Exception as e:
        print(f"{t}: {e}")
c.commit()
