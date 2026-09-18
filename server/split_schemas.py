import os
import re

schemas_dir = 'schemas'
models_dir = 'models'
os.makedirs(schemas_dir, exist_ok=True)
os.makedirs(models_dir, exist_ok=True)

with open('schemas.py', 'r') as f:
    schema_code = f.read()

sections = re.split(r'# --- (.*?) ---', schema_code)

schema_imports = "from pydantic import BaseModel\nfrom typing import List, Optional\nfrom datetime import datetime\n"
schema_groups = {}
current_group = "base"
schema_groups[current_group] = schema_imports

for i in range(1, len(sections), 2):
    header = sections[i].strip()
    content = sections[i+1]
    
    if "User" in header: g = "user"
    elif "Student" in header or "Document" in header: g = "student"
    elif "Discount" in header or "Invoice" in header or "Fee" in header or "Installment" in header or "Payment" in header or "Virtual" in header or "Ledger" in header or "Financial" in header or "Expense" in header or "Webhook" in header: g = "finance"
    elif "School" in header or "ERP" in header or "Report" in header or "Platform" in header or "Settings" in header: g = "school"
    elif "Course" in header or "Test" in header or "Academic" in header or "Collaboration" in header: g = "academic"
    elif "Staff" in header or "Payroll" in header: g = "hr"
    elif "Inventory" in header or "Broadcast" in header or "Notification" in header or "Audit" in header or "CSV" in header: g = "admin"
    else: g = "misc"
    
    if g not in schema_groups: schema_groups[g] = schema_imports
    schema_groups[g] += content

schema_init = ""
for g in schema_groups:
    if g == "base" or g == "misc": continue
    # Need to add cross-imports. E.g. student needs VirtualAccount from finance.
    # We will just write the files and manually fix imports in them if we have to.
    # Easiest hack: import all other schemas locally or at the top.
    
    cross_imports = ""
    for other_g in schema_groups:
        if other_g != "base" and other_g != "misc" and other_g != g:
            cross_imports += f"from .{other_g} import *\n"
            
    with open(os.path.join(schemas_dir, g + '.py'), 'w') as f:
        f.write(schema_groups[g])

    # We also need to extract all class names to put into __init__.py
    class_names = re.findall(r'class ([A-Za-z0-9_]+)\(.*?BaseModel.*?\):', schema_groups[g])
    class_names += re.findall(r'class ([A-Za-z0-9_]+)\([A-Za-z0-9_]+\):', schema_groups[g])
    # deduplicate while keeping order
    class_names = list(dict.fromkeys(class_names))
    
    if class_names:
        schema_init += f"from .{g} import {', '.join(class_names)}\n"

with open(os.path.join(schemas_dir, '__init__.py'), 'w') as f:
    f.write(schema_init)

print("Schemas split done!")
