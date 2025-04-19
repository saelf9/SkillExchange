# SkillExchange

SkillExchange is a social networking platform that allows users to share, learn, and exchange skills with others. The platform supports profile creation, skill showcasing, messaging, and user evaluations.

## 🌐 Features

- 👤 User profiles with bio, skills, and evaluations
- 🔍 Skill-based search and filtering
- 📨 Real-time messaging between users
- ⭐ Friend and follow system
- 📝 Skill rating and evaluation
- 🛡️ Reporting and supervision for underage users
- 📱 Fully responsive design (desktop, tablet, mobile)

## 🛠️ Tech Stack

- **Frontend**: Vue.js
- **Backend**: Flask (REST API)
- **Database**: MySQL
- **Fake Data Generation**: Python + Faker

## 🚀 Getting Started

### Prerequisites

- Node.js
- Python 3
- MySQL server

### Frontend Setup

```bash
cd skillexchange
npm install
npm run serve
```
### Backend Setup (Flask)
```bash
Copy
Edit
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows use venv\Scripts\activate
pip install -r requirements.txt
python app.py
```
### Database Setup
1. Create a MySQL database.

2. Run the provided SQL script to create tables and seed fake data.

3. Update .env or config file with your DB credentials.

### 📂 Folder Structure
```php
Copy
Edit
skillexchange/
│
├── public/              # Public assets
├── src/                 # Vue.js source files
│   ├── assets/
│   ├── components/
│   ├── views/
│   └── App.vue
├── package.json         # Project metadata and scripts
└── vue.config.js        # Vue configuration
```
### 👥 Team
This project was created by a team of students at Université Laval as part of the GLO-2005 course.

### 📄 License
MIT License



