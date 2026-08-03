import json
import random
import uuid
from datetime import datetime, timedelta

def get_random_date(start_date, end_date):
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    return start_date + timedelta(days=random_days)

def get_school_days(start_date, end_date):
    days = []
    current = start_date
    while current <= end_date:
        if current.weekday() < 5:  # Monday to Friday
            days.append(current)
        current += timedelta(days=1)
    return days

def generate_json_data():
    nigerian_last_names = ["Adebayo", "Okafor", "Nwachukwu", "Ibrahim", "Abubakar", "Danladi", "Oluwaseun", "Eze", "Okoro", "Adeyemi", "Bello", "Chukwu", "Umar", "Olawale", "Nwosu", "Adekunle", "Oni", "Ogunleye", "Balogun", "Ojo", "Igwe", "Kalu", "Onyeka", "Danjuma", "Mohammed", "Sani", "Mustapha", "Abdullahi", "Hassan", "Aliyu", "Lawal"]
    nigerian_first_names = ["Chinedu", "Fatima", "Aminu", "Ngozi", "Aisha", "Emeka", "Olamide", "Zainab", "Musa", "Tolu", "Kemi", "Ifeanyi", "Binta", "Dayo", "Yusuf", "Chioma", "Nnamdi", "Blessing", "Samuel", "David", "Mary", "Joy", "Grace", "Emmanuel", "Abigail", "Daniel", "Michael", "Esther", "Sarah", "Oluwaseyi", "Habiba", "Halima"]

    schools = [
        {
            "id": str(uuid.uuid4()),
            "name": "Excel Academy",
            "location": "Lagos",
            "address": "14 Broad Street, Victoria Island, Lagos",
            "contact_email": "info@excelacademylagos.edu.ng",
            "contact_phone": "+2348012345678",
            "motto": "Excellence in Education",
            "established_year": 2005,
            "principal_name": "Mrs. Folashade Adeyemi",
            "tier": "mid_tier"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Heritage International School",
            "location": "Abuja",
            "address": "22 Gana Street, Maitama, Abuja",
            "contact_email": "contact@heritageabuja.edu.ng",
            "contact_phone": "+2349012345678",
            "motto": "Nurturing Future Leaders",
            "established_year": 2010,
            "principal_name": "Dr. Ibrahim Aliyu",
            "tier": "high_charging" # Adds to tuition
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Pinnacle Primary School",
            "location": "Port Harcourt",
            "address": "45 Trans Amadi Industrial Layout, Port Harcourt",
            "contact_email": "admin@pinnacleph.edu.ng",
            "contact_phone": "+2347012345678",
            "motto": "Reaching the Peak",
            "established_year": 2012,
            "principal_name": "Mr. Chinedu Eze",
            "tier": "standard"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Springfield Scholars",
            "location": "Ibadan",
            "address": "10 Ring Road, Ibadan",
            "contact_email": "hello@springfieldib.edu.ng",
            "contact_phone": "+2348112345678",
            "motto": "Knowledge is Power",
            "established_year": 2008,
            "principal_name": "Chief Ojo Balogun",
            "tier": "standard"
        }
    ]

    classes = ["Creche", "Nursery 1", "Nursery 2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6"]
    sections = ["A", "B", "C"]
    subjects = ["Mathematics", "English Language", "Basic Science", "Social Studies", "Civic Education", "Agricultural Science", "Computer Studies", "Christian Religious Studies", "Islamic Religious Studies", "Yoruba", "Igbo", "Hausa"]

    # Academic Year Setup (approx Sept 2025 to July 2026)
    ay_start = datetime(2025, 9, 8)
    ay_end = datetime(2026, 7, 15)
    
    term1_start = datetime(2025, 9, 8)
    term1_end = datetime(2025, 12, 12)
    
    term2_start = datetime(2026, 1, 12)
    term2_end = datetime(2026, 4, 3)
    
    term3_start = datetime(2026, 4, 27)
    term3_end = datetime(2026, 7, 15)

    all_school_days = get_school_days(term1_start, term1_end) + get_school_days(term2_start, term2_end) + get_school_days(term3_start, term3_end)

    data = {
        "metadata": {
            "academic_year": "2025/2026",
            "generated_at": datetime.now().isoformat(),
            "version": "2.0",
            "description": "Full academic year mock data for Nigerian primary schools with dropouts, late admissions, and nuanced tuition."
        },
        "schools": []
    }

    students_per_school = 135

    for school in schools:
        school_data = {k: v for k, v in school.items() if k != 'tier'} # Keep tier private to generation logic
        tier = school["tier"]
        
        # 1. Generate Staff
        staff_list = []
        roles = [("Head Teacher", 150000), ("Assistant Head", 120000), ("Bursar", 100000), ("Secretary", 60000)]
        for i in range(12): 
            roles.append(("Teacher", random.choice([70000, 75000, 80000, 85000])))
        for i in range(2):
            roles.append(("Security", 40000))
        roles.append(("Cleaner", 35000))
        
        for idx, (role, salary) in enumerate(roles):
            fname = random.choice(nigerian_first_names)
            lname = random.choice(nigerian_last_names)
            staff_list.append({
                "id": str(uuid.uuid4()),
                "employee_id": f"EMP-{school['name'][:3].upper()}-{idx+100}",
                "name": f"{fname} {lname}",
                "email": f"{fname.lower()}.{lname.lower()}{idx}@{school['contact_email'].split('@')[1]}",
                "phone": f"080{random.randint(20000000, 99999999)}",
                "role": role,
                "department": "Academic" if "Teacher" in role or "Head" in role else "Non-Academic",
                "salary": salary,
                "date_joined": get_random_date(ay_start - timedelta(days=3000), ay_start - timedelta(days=100)).strftime("%Y-%m-%d"),
                "qualifications": random.choice(["NCE", "B.Ed", "PGDE", "M.Ed"]) if "Teacher" in role else random.choice(["SSCE", "OND", "HND", "BSc"]),
                "status": "Active"
            })
        school_data["staff"] = staff_list
        
        # 2. Generate Students
        # Generate Class Tuition Map
        if tier == "high_charging":
            school_base = random.randint(250000, 350000)
        elif tier == "mid_tier":
            school_base = random.randint(80000, 120000)
        else: # standard
            school_base = random.randint(30000, 60000)
            
        class_tuition_map = {}
        for c in classes:
            c_tuition = school_base
            if "Creche" in c:
                c_tuition += int(school_base * 0.20)
            elif "Nursery" in c:
                c_tuition += int(school_base * 0.10)
            elif c in ["Primary 4", "Primary 5", "Primary 6"]:
                c_tuition += int(school_base * 0.15)
            class_tuition_map[c] = (c_tuition // 1000) * 1000 # Round to nearest 1000

        student_list = []
        for i in range(students_per_school):
            fname = random.choice(nigerian_first_names)
            lname = random.choice(nigerian_last_names)
            student_class = random.choice(classes)
            student_section = random.choice(sections)
            
            # Trajectory
            trajectory_type = random.choices(["full_year", "late_admission", "dropout"], weights=[80, 10, 10])[0]
            
            student_start = ay_start
            student_end = ay_end
            
            if trajectory_type == "late_admission":
                student_start = get_random_date(term2_start, term3_start) # Joins mid-year
            elif trajectory_type == "dropout":
                student_end = get_random_date(term1_start + timedelta(days=30), term2_end) # Leaves mid-year
                
            dob_range_start = ay_start - timedelta(days=12*365) # Max 12 yrs
            dob_range_end = ay_start - timedelta(days=1*365) # Min 1 yr (creche)
            dob = get_random_date(dob_range_start, dob_range_end).strftime("%Y-%m-%d")
            
            # Attendance History
            attendance = []
            absence_probability = random.choice([0.02, 0.05, 0.15]) # 2% (good), 5% (avg), 15% (frequent absentee)
            
            for day in all_school_days:
                if student_start <= day <= student_end:
                    is_absent = random.random() < absence_probability
                    if is_absent:
                        status = "Absent"
                        remark = random.choice(["Sick", "Family Reason", "Unknown", "Transportation Issue"])
                    else:
                        is_late = random.random() < 0.05
                        status = "Late" if is_late else "Present"
                        remark = "Traffic" if is_late else ""
                        
                    attendance.append({
                        "date": day.strftime("%Y-%m-%d"),
                        "status": status,
                        "remark": remark
                    })
                
            # Base tuition from class map (fixed per class)
            base_tuition = class_tuition_map[student_class]
            
            # Student-specific exceptions (Discounts, Scholarships, Penalties, Extras)
            exceptions = []
            if random.random() < 0.10: # 10% get sibling discount
                exceptions.append({"description": "Sibling Discount", "amount": -int(base_tuition * 0.15)})
            elif random.random() < 0.02: # 2% get scholarship
                exceptions.append({"description": "Merit Scholarship", "amount": -int(base_tuition * 0.50)})
                
            if random.random() < 0.15: # 15% take extracurriculars
                exceptions.append({"description": "Extracurricular (Ballet/Coding)", "amount": 15000})
            if random.random() < 0.05: # 5% PTA penalty
                exceptions.append({"description": "Late Registration Penalty", "amount": 5000})
            
            # Invoices
            invoices = []
            terms = [
                ("First Term", term1_start, term1_end),
                ("Second Term", term2_start, term2_end),
                ("Third Term", term3_start, term3_end)
            ]
            
            for term_name, t_start, t_end in terms:
                # Only bill if student was active during this term
                if student_end >= t_start and student_start <= t_end:
                    status = "Paid" if term_name == "First Term" else random.choice(["Pending", "Paid", "Partial", "Overdue"])
                    if trajectory_type == "dropout" and student_end < t_end:
                        status = "Overdue" # Often dropouts leave unpaid balances
                        
                    line_items = [
                        {"description": "Tuition Fee", "amount": base_tuition},
                        {"description": "PTA Levy", "amount": 2000},
                        {"description": "Development Levy", "amount": 3000}
                    ] + exceptions
                    
                    total_amount = sum(item["amount"] for item in line_items)
                    total_amount = max(0, int(total_amount))
                    
                    paid_amount = total_amount if status == "Paid" else (random.randint(10000, max(10000, total_amount - 1000)) if status == "Partial" else 0)
                    
                    invoices.append({
                        "invoice_id": f"INV-{school['name'][:3].upper()}-26-{i:03d}-{term_name[:3].upper()}",
                        "title": f"{term_name} Fees",
                        "issue_date": (t_start - timedelta(days=14)).strftime("%Y-%m-%d"),
                        "due_date": (t_start + timedelta(days=14)).strftime("%Y-%m-%d"),
                        "status": status,
                        "total_amount": total_amount,
                        "amount_paid": paid_amount,
                        "balance": total_amount - paid_amount,
                        "line_items": line_items
                    })
                    
            # Grades
            grades = []
            for term_name, t_start, t_end in terms:
                if student_end >= t_end: # Must finish term to get full grades
                    for subj in random.sample(subjects, 8):
                        ca1 = random.randint(5, 15)
                        ca2 = random.randint(5, 15)
                        exam = random.randint(30, 70)
                        total = ca1 + ca2 + exam
                        grades.append({
                            "subject": subj,
                            "ca_1": ca1,
                            "ca_2": ca2,
                            "exam": exam,
                            "total": total,
                            "grade": "A" if total >= 70 else "B" if total >= 60 else "C" if total >= 50 else "D" if total >= 45 else "E" if total >= 40 else "F",
                            "term": term_name
                        })

            student_list.append({
                "id": str(uuid.uuid4()),
                "enrollment_number": f"{school['name'][:3].upper()}-26-{i:03d}",
                "first_name": fname,
                "last_name": lname,
                "full_name": f"{fname} {lname}",
                "date_of_birth": dob,
                "gender": random.choice(["Male", "Female"]),
                "blood_group": random.choice(["O+", "A+", "B+", "AB+", "O-"]),
                "genotype": random.choice(["AA", "AS", "SS", "AC"]),
                "allergies": random.choice(["None", "Dust", "Pollen", "Peanut", "Seafood", "None", "None"]),
                "medical_conditions": random.choice(["None", "Asthma", "None", "None"]),
                "address": f"{random.randint(1, 200)} {random.choice(['Obafemi Awolowo Way', 'Ahmadu Bello Way', 'Nnamdi Azikiwe Express', 'Allen Avenue', 'Ademola Adetokunbo', 'Herbert Macaulay Way'])}, {school['location']}",
                "class": f"{student_class} {student_section}",
                "enrollment_status": "Active" if trajectory_type != "dropout" else "Dropped Out",
                "trajectory": trajectory_type,
                "admission_date": student_start.strftime("%Y-%m-%d"),
                "exit_date": student_end.strftime("%Y-%m-%d") if trajectory_type == "dropout" else None,
                "parent_info": {
                    "father_name": f"Mr. {lname}",
                    "mother_name": f"Mrs. {lname}",
                    "primary_contact_phone": f"080{random.randint(20000000, 99999999)}",
                    "secondary_contact_phone": f"090{random.randint(20000000, 99999999)}",
                    "email": f"parent_{fname.lower()}.{lname.lower()}@example.com",
                    "occupation": random.choice(["Engineer", "Doctor", "Trader", "Teacher", "Civil Servant", "Business Owner", "Banker"])
                },
                "virtual_account": {
                    "account_name": f"{school['name'][:10]} - {fname} {lname}",
                    "account_number": f"90{random.randint(10000000, 99999999)}",
                    "bank_name": random.choice(["GTBank", "Zenith Bank", "Access Bank", "First Bank", "Wema Bank", "UBA"])
                },
                "academic_performance": grades,
                "attendance": attendance,
                "billing": invoices
            })
            
        school_data["students"] = student_list
        data["schools"].append(school_data)

    with open("nigerian_schools_mock_api.json", "w") as f:
        json.dump(data, f, indent=4)
        
    print("Successfully generated nigerian_schools_mock_api.json with full academic year data!")

if __name__ == "__main__":
    generate_json_data()
