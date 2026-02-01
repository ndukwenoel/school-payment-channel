# Channel

## Project Structure
- `client/`: Flutter Application (Web, Android, iOS)
- `server/`: Python FastAPI Backend

## Setup

### Backend (Python)
1. Navigate to `server` directory.
2. Create virtual environment: `python -m venv venv`
3. Activate venv:
   - Windows: `.\venv\Scripts\activate`
   - Linux/Mac: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Run server: `uvicorn main:app --reload`

### Frontend (Flutter)
1. Navigate to `client` directory.
2. Install dependencies: `flutter pub get`
3. Run app: `flutter run`
