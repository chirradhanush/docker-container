# Prerequisites

Before starting the assignment, ensure you have the following software installed and properly configured on your machine:

1. **Docker Desktop:**
   - [Download and Install Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Verify installation:
     ```bash
     docker --version
     docker compose version
     ```

2. **Git:**
   - [Download and Install Git](https://git-scm.com/downloads)
   - Verify installation:
     ```bash
     git --version
     ```

3. **Editor/IDE:**
   - Use [Visual Studio Code](https://code.visualstudio.com/) or any IDE of your choice.

---

# Project Structure
.
├── app/
│ ├── Dockerfile # Python app container
│ └── main.py # Queries Postgres and writes results
├── db/
│ ├── Dockerfile # PostgreSQL container
│ └── init.sql # Schema + seed data
├── out/ # Stores JSON output
├── compose.yml # Compose file to run multi-container stack
└── README.md # Documentation

## 📄 Files Used in the Project

### **db/Dockerfile**
```dockerfile
FROM postgres:16
COPY init.sql /docker-entrypoint-initdb.d/
```

###**db/init.sql**
```sql
CREATE TABLE trips (
  id SERIAL PRIMARY KEY,
  city TEXT NOT NULL,
  minutes INT NOT NULL,
  fare NUMERIC(6,2) NOT NULL
);

INSERT INTO trips (city, minutes, fare) VALUES
('Charlotte', 12, 12.50),
('Charlotte', 21, 20.00),
('New York', 9, 10.90),
('New York', 26, 27.10),
('San Francisco', 11, 11.20),
('San Francisco', 28, 29.30);
```
### **app/Dockerfile**
```dockerfile
FROM python:3.11-slim
RUN pip install --no-cache-dir psycopg[binary]==3.1.19
WORKDIR /app
COPY main.py /app/
CMD ["python", "main.py"]
```
### **app/main.py**
```python
import os, sys, time, json
import psycopg

# Environment variables with defaults
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASS = os.getenv("DB_PASS", "secretpw")
DB_NAME = os.getenv("DB_NAME", "appdb")
TOP_N   = int(os.getenv("APP_TOP_N", "5"))

def connect_with_retry(retries=10, delay=2):
    last_err = None
    for _ in range(retries):
        try:
            conn = psycopg.connect(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASS,
                dbname=DB_NAME,
                connect_timeout=3,
            )
            return conn
        except Exception as e:
            last_err = e
            print("Waiting for database...", file=sys.stderr)
            time.sleep(delay)
    print("Failed to connect to Postgres:", last_err, file=sys.stderr)
    sys.exit(1)

def main():
    conn = connect_with_retry()
    with conn, conn.cursor() as cur:
        # Total number of trips
        cur.execute("SELECT COUNT(*) FROM trips;")
        total_trips = cur.fetchone()[0]

        # Average fare by city
        cur.execute("""
            SELECT city, AVG(fare) 
            FROM trips 
            GROUP BY city;
        """)
        by_city = [{"city": c, "avg_fare": float(a)} for (c, a) in cur.fetchall()]

        # Top N trips by minutes
        cur.execute("""
            SELECT city, minutes, fare
            FROM trips
            ORDER BY minutes DESC
            LIMIT %s;
        """, (TOP_N,))
        top = [{"city": c, "minutes": m, "fare": float(f)} for (c, m, f) in cur.fetchall()]

    summary = {
        "total_trips": int(total_trips),
        "avg_fare_by_city": by_city,
        "top_by_minutes": top
    }

    # Write to /out/summary.json
    os.makedirs("/out", exist_ok=True)
    with open("/out/summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    # Print to stdout
    print("=== Summary ===")
    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()
```
### **compose.yml**
```yaml
services:
  db:
    build:
      context: ./db
      dockerfile: Dockerfile
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: secretpw
      POSTGRES_DB: appdb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 3s
      timeout: 3s
      retries: 10

  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: appuser
      DB_PASS: secretpw
      DB_NAME: appdb
      APP_TOP_N: "3"
    volumes:
      - ./out:/out
```
### **Steps to Run**

**1.Clone Repository**
```bash
git clone https://github.com/chirradhanush/docker-container.git
```



**2.Build and Start Containers**

```bash
docker compose up --build
```


**3.Stop and Remove Containers**

```bash
docker compose down -v
```


**4.Reset Output Folder**

PowerShell:
```powershell

Remove-Item -Recurse -Force .\out
New-Item -ItemType Directory -Path .\out
```


Git Bash / Linux:
```bash

rm -rf out && mkdir out
```

##**Example Output**##
**Terminal**
```json
=== Summary ===
{
  "total_trips": 6,
  "avg_fare_by_city": [
    {"city": "Charlotte", "avg_fare": 16.25},
    {"city": "New York", "avg_fare": 19.00},
    {"city": "San Francisco", "avg_fare": 20.25}
  ],
  "top_by_minutes": [
    {"city": "San Francisco", "minutes": 28, "fare": 29.30},
    {"city": "New York", "minutes": 26, "fare": 27.10},
    {"city": "Charlotte", "minutes": 21, "fare": 20.00}
  ]
}
```
**File (out/summary.json):**
```json
{
  "total_trips": 6,
  "avg_fare_by_city": [
    {"city": "Charlotte", "avg_fare": 16.25},
    {"city": "New York", "avg_fare": 19.00},
    {"city": "San Francisco", "avg_fare": 20.25}
  ],
  "top_by_minutes": [
    {"city": "San Francisco", "minutes": 28, "fare": 29.30},
    {"city": "New York", "minutes": 26, "fare": 27.10},
    {"city": "Charlotte", "minutes": 21, "fare": 20.00}
  ]
}

```
##**✍️ Reflection**##
**Through this assignment, I learned how to:**

Set up a multi-container application using Docker Compose.

Initialize PostgreSQL with an automatic seed script.

Write a Python app that queries data and saves results in JSON.

Document and share a reproducible workflow with GitHub.

**For improvements, I would:**

Add more complex analytics queries.

Optimize the Python container size with Alpine images.

Add automated tests to verify output correctness.

Use .env files for cleaner configuration.





















