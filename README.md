# Project_Map
SECJ3623-01 Mobile application programming course, this project will include proposal and all sprints and all related documents and commets done by team members during this semester

# UTM Counter

> **Digital Examination Washroom Timer & Movement History System**  
> Course: **SECJ3623 Mobile Application Programming** (Semester 1, 2026/2027)  
> Faculty of Computing, Universiti Teknologi Malaysia (UTM)  
> **Group:** Wizards  

---

## 👥 Team Members

| No | Name | Matric Number |
|:--:|:---|:---:|
| 1 | **Mohammed Fares Hamid Abdo** | A23CS4046 |
| 2 | **Rifqi Ahmad Musyaffa** | A23CS0024 |
| 3 | **Ahmed Abdelhadi Mohamed Zien Abdeldafei** | A22EC4002 |
| 4 | **Daffa Tangguh Ananda Kurniawan** | A21EC4042 |

---

## 📌 Project Overview

**UTM Counter** is an ultra-lightweight, offline-first mobile application designed to streamline student washroom tracking and maintain movement audit histories during university examinations.

### Key Highlights:
- **Instant 1-Tap Counter:** Quick matric input with real-time green/red visual traffic-light status indicators.
- **Offline-First Resilience:** Fully functional without active campus Wi-Fi; automatically synchronizes records to Cloud Firestore when internet reconnects.
- **1-Click Student History Lookup:** Instant access to a student's past departures to prevent unmonitored overstays.
- **Role-Tailored Architecture:** Distinct views and navigation for **Hall Invigilators** and **Chief Supervisors**.

---

## 🛠 Tech Stack & Architecture

- **Framework:** Flutter (Dart)
- **Architecture:** Model-View-ViewModel (MVVM)
- **Backend / Database:** Firebase Authentication & Cloud Firestore
- **Version Control:** Git & GitHub

---

## 📁 Repository Structure

```text
Project_Map/
├── docs/                 # Project proposal slides and sprint documentation
├── src/
│   └── utm_counter/      # Flutter application source code
│       ├── lib/
│       │   ├── models/
│       │   ├── views/
│       │   ├── viewmodels/
│       │   └── services/
└── README.md
