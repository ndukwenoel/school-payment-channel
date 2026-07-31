import unittest
from datetime import datetime, timezone
import sys
import os

# Ensure server module is accessible
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from server.models import Base, School, User, Student, Invoice, InvoiceLineItem, PaymentAttempt, LedgerAccount, LedgerTransaction
from server.worker.tasks import handle_virtual_account_funded
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Create in-memory SQLite database
engine = create_engine('sqlite:///:memory:')
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class TestVirtualAccount(unittest.TestCase):
    def setUp(self):
        # Create all tables
        Base.metadata.create_all(bind=engine)
        self.db = TestingSessionLocal()
        
        # Setup basic data
        self.school = School(name="Test School")
        self.db.add(self.school)
        self.db.commit()
        
        self.parent = User(email="parent@test.com", hashed_password="pwd", full_name="Parent", role="parent", credit_balance=0.0)
        self.db.add(self.parent)
        self.db.commit()
        
        self.student = Student(enrollment_number="STU-001", full_name="Test Student", parent_id=self.parent.id, school_id=self.school.id, grade="JSS 1")
        self.db.add(self.student)
        self.db.commit()
        
        # Setup ledger accounts
        self.school_rev = LedgerAccount(school_id=self.school.id, name="School Revenue", type="revenue")
        self.va_wallet = LedgerAccount(school_id=self.school.id, name="Virtual Account Wallet", type="asset")
        self.parent_wallet = LedgerAccount(school_id=self.school.id, name="Parent Wallet", type="liability")
        self.unrec_funds = LedgerAccount(school_id=self.school.id, name="Unreconciled Funds", type="liability")
        self.db.add_all([self.school_rev, self.va_wallet, self.parent_wallet, self.unrec_funds])
        self.db.commit()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=engine)

    def test_handle_virtual_account_funded_matches_invoice_and_credits_parent(self):
        # Create two unpaid invoices
        inv1 = Invoice(student_id=self.student.id, title="Term 1", status="pending", due_date=datetime(2023, 1, 1, tzinfo=timezone.utc), school_id=self.school.id)
        inv2 = Invoice(student_id=self.student.id, title="Term 2", status="pending", due_date=datetime(2023, 4, 1, tzinfo=timezone.utc), school_id=self.school.id)
        self.db.add_all([inv1, inv2])
        self.db.commit()

        li1 = InvoiceLineItem(invoice_id=inv1.id, title="Tuition", amount=100.0)
        li2 = InvoiceLineItem(invoice_id=inv2.id, title="Tuition", amount=100.0)
        self.db.add_all([li1, li2])
        self.db.commit()

        # Payload representing a webhook event with 250.0 received
        # Expectation: 100 goes to inv1, 100 goes to inv2, 50 goes to parent credit_balance
        payload = {
            "student_id": self.student.id,
            "account_number": "1234567890",
            "amount": 250.0,
            "transaction_ref": "TEST-REF-123"
        }
        
        # We need to mock SessionLocal in database module temporarily to use our in-memory DB
        from unittest.mock import patch
        
        with patch('server.database.SessionLocal', TestingSessionLocal):
            handle_virtual_account_funded(payload, self.school.id)
            
            # Check invoices
            self.db.refresh(inv1)
            self.db.refresh(inv2)
            self.assertEqual(inv1.status, "paid")
            self.assertEqual(inv2.status, "paid")
            
            # Check parent wallet
            self.db.refresh(self.parent)
            self.assertEqual(self.parent.credit_balance, 50.0)
            
            # Check Payment Attempts
            attempts = self.db.query(PaymentAttempt).all()
            self.assertEqual(len(attempts), 2)
            self.assertEqual(attempts[0].amount, 100.0)
            self.assertEqual(attempts[1].amount, 100.0)
            
            # Check Ledger Transactions
            txns = self.db.query(LedgerTransaction).all()
            # 1 for funding, 1 for overpayment credit
            self.assertEqual(len(txns), 2)
            self.assertTrue("Virtual Account Transfer" in txns[0].description)
            self.assertTrue("Overpayment Credit" in txns[1].description)

    def test_parse_email_alert_exact_match(self):
        from server.services.reconciliation import parse_and_route_email_alert
        from server.models import VirtualAccount, ClassRoom
        
        cls = ClassRoom(name="Grade 1", school_id=self.school.id)
        self.db.add(cls)
        self.db.commit()
        
        self.student.classroom_id = cls.id
        self.db.commit()
        
        va = VirtualAccount(
            school_id=self.school.id,
            classroom_id=cls.id,
            account_number="9876543210",
            bank_name="TestBank",
            account_name="Grade 1 VA"
        )
        self.db.add(va)
        self.db.commit()

        email_body = f"""
        Credit Alert
        Account: 9876543210
        Amount: 50,000.00
        Desc: Payment for {self.student.enrollment_number}
        """
        payload = {"text": email_body}

        from unittest.mock import patch
        
        with patch('server.database.SessionLocal', TestingSessionLocal):
            with patch('server.events.EventDispatcher.publish') as mock_publish:
                parse_and_route_email_alert(self.db, payload)
                mock_publish.assert_called_once()
                args, kwargs = mock_publish.call_args
                event = args[0]
                self.assertEqual(event.event_type, "VirtualAccountFunded")
                self.assertEqual(event.payload["student_id"], self.student.id)
                self.assertEqual(event.payload["amount"], 50000.00)

    def test_parse_email_alert_unmatched(self):
        from server.services.reconciliation import parse_and_route_email_alert
        from server.models import VirtualAccount, ClassRoom, UnmatchedPayment
        
        cls = ClassRoom(name="Grade 2", school_id=self.school.id)
        self.db.add(cls)
        self.db.commit()
        
        va = VirtualAccount(
            school_id=self.school.id,
            classroom_id=cls.id,
            account_number="1111222233",
            bank_name="TestBank",
            account_name="Grade 2 VA"
        )
        self.db.add(va)
        self.db.commit()

        # No enrollment number in narration, name doesn't match perfectly
        email_body = f"""
        Credit Alert
        Account: 1111222233
        Amount: 25,000.00
        Desc: Payment for John Doe
        """
        payload = {"text": email_body}

        from unittest.mock import patch
        
        with patch('server.database.SessionLocal', TestingSessionLocal):
            with patch('server.events.EventDispatcher.publish') as mock_publish:
                parse_and_route_email_alert(self.db, payload)
                mock_publish.assert_not_called()
                
                # Check UnmatchedPayment was created
                unmatched = self.db.query(UnmatchedPayment).filter_by(account_number="1111222233").first()
                self.assertIsNotNone(unmatched)
                self.assertEqual(unmatched.amount, 25000.00)
                self.assertEqual(unmatched.status, "pending")

if __name__ == '__main__':
    unittest.main()
