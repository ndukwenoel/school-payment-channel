import httpx
import asyncio

async def test_api():
    async with httpx.AsyncClient() as client:
        # First login
        response = await client.post("http://127.0.0.1:8000/api/v1/auth/login", data={"username": "admin@school.com", "password": "password123"})
        if response.status_code != 200:
            print("Login failed", response.text)
            return
            
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Call payroll history
        res = await client.get("http://127.0.0.1:8000/api/v1/erp/hr/payroll/history?month=May&year=2026", headers=headers)
        print("Status:", res.status_code)
        print("Data:", res.json())

if __name__ == "__main__":
    asyncio.run(test_api())
