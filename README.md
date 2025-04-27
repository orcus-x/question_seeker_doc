# QuestionSeekerDoc

**QuestionSeekerDoc** is a **lightweight, fast, and efficient server** built with **Elixir** and the **Phoenix Framework**.  
It is designed to handle **PDF document uploads**, **extract text** using **AWS Textract**, and **automatically generate questions and answers** from the extracted content using **OpenAI GPT-4**.  
Thanks to Elixir and Phoenix, the server is highly scalable, maintainable, and perfect for intelligent document processing workflows.

---

## Tech Stack
- **Backend**: Elixir + Phoenix Framework
- **Database**: PostgreSQL
- **OCR**: AWS Textract
- **AI Processing**: OpenAI GPT-4
- **File Storage**: Amazon S3

---

## Installation and Setup

### Prerequisites
- **Elixir & Erlang** installed
- **Phoenix Framework** installed
- **PostgreSQL** installed

(Refer to [official Elixir/Phoenix/PostgreSQL installation guides](https://hexdocs.pm/phoenix/installation.html) if not already installed.)

---

## Environment Setup

### 1. Clone the project

```bash
git clone https://github.com/orcus-x/question_seeker_doc.git
cd question_seeker_doc/backend
```

---

### 2. Install dependencies

```bash
mix deps.get
```

---

### 3. Set up the Database

#### Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

**macOS (with Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

---

#### Create PostgreSQL user and database

Login to PostgreSQL console:
```bash
sudo -u postgres psql
```

In the PostgreSQL console, run:

```sql
CREATE USER phoenix WITH PASSWORD 'password';
CREATE DATABASE question_seeker_doc;
GRANT ALL PRIVILEGES ON DATABASE question_seeker_doc TO phoenix;
\q
```

---

#### Confirm Database Settings in `config/dev.exs`

Ensure that `config/dev.exs` contains:

```elixir
config :question_seeker_doc, QuestionSeekerDoc.Repo,
  username: "phoenix",
  password: "password",
  database: "question_seeker_doc",
  hostname: "localhost",
  pool_size: 10
```

- `username`: your PostgreSQL username (default: `phoenix`)
- `password`: your PostgreSQL password (default: `password`)
- `database`: your database name (default: `question_seeker_doc`)
- `hostname`: usually `localhost`
- `pool_size`: number of database connections (default: 10)

---

#### Create and Migrate the Database

```bash
mix ecto.create
mix ecto.migrate
```

---

### 4. Set up AWS (Textract + S3)

#### Create an AWS Account
- Sign up at [AWS Official Site](https://aws.amazon.com/)

#### Create IAM User for S3 and Textract
- Go to **IAM** → **Users** → **Add user**
- Enable **Programmatic access**
- Attach permissions:
  - `AmazonS3FullAccess`
  - `AmazonTextractFullAccess`
- Complete user creation
- **Save the Access Key ID and Secret Access Key**

#### Create an S3 Bucket
- Go to **S3** → **Create Bucket**
- Name: `your_bucket_name` (e.g., `question-seeker-docs`)
- Select your AWS region (e.g., `us-west-2`)

---

### 5. Set up OpenAI

#### Create OpenAI Account
- Sign up at [OpenAI Platform](https://platform.openai.com/)

#### Generate API Key
- Go to [OpenAI API Keys](https://platform.openai.com/account/api-keys)
- Create a new secret key
- **Copy it immediately** — you won't see it again later

---

### 6. Create `.env` File

Inside the `backend/` folder, create a file called `.env`:

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID=your_aws_access_key
export AWS_SECRET_ACCESS_KEY=your_aws_secret_key
export AWS_REGION=your_aws_region
export AWS_S3_BUCKET=your_s3_bucket_name

# OpenAI credentials
export OPENAI_API_KEY=your_openai_api_key

# Database connection (for production)
export DATABASE_URL=ecto://phoenix:password@localhost/question_seeker_doc

# Phoenix settings
export SECRET_KEY_BASE=your_generated_secret_key
export PORT=4000
export POOL_SIZE=10
```

✅ Replace the placeholders with your real credentials.

---

### 7. Generate SECRET_KEY_BASE

To generate a `SECRET_KEY_BASE` for production:

```bash
mix phx.gen.secret
```

It will output a long secret like:

```
oYZf0XksjS7D2Uw3lHv0K9fH4MsUqYkh2C1Dq1vnboBPWVaFbDd82q9uXQzyCGxN
```

Copy and set it in your `.env`:

```bash
export SECRET_KEY_BASE=oYZf0XksjS7D2Uw3lHv0K9fH4MsUqYkh2C1Dq1vnboBPWVaFbDd82q9uXQzyCGxN
```

---

### 8. Load environment variables

Before running the server, always load your environment variables:

```bash
source .env
```

---

## Running the Application

### Development Mode

```bash
# Load environment variables
source .env

# Start Phoenix server
mix phx.server
```

The server will be available at:  
[http://localhost:4000](http://localhost:4000)

---

### Production Mode

```bash
# Load environment variables
source .env

# Start in production mode
MIX_ENV=prod mix phx.server
```

---

## API Endpoints

All endpoints are prefixed with `/api`.

---

### 📄 Upload Document
**POST** `/api/upload`
- Upload a PDF document.
- Content-Type: `multipart/form-data`
- Form field: `upload[file]`

Example:
```bash
curl -X POST http://localhost:4000/api/upload \
  -F "upload=@/path/to/your/document.pdf"
```

---

### 🕐 Check Document Status
**GET** `/api/documents/:id/status`
- Check if the document is still processing or completed.

---

### 📚 List All Documents
**GET** `/api/documents`
- Fetch all uploaded documents.

---

### 📄 Get Single Document
**GET** `/api/documents/:id`
- Fetch a specific document and its extracted questions.

---

### ❓ List All Questions
**GET** `/api/questions`
- List all extracted questions.

---

### ❓ List Questions for a Specific Document
**GET** `/api/documents/:document_id/questions`
- Fetch questions linked to a specific document.

---

## Environment Variables Summary

| Variable | Purpose |
|:---------|:--------|
| AWS_ACCESS_KEY_ID | AWS access key for S3 and Textract |
| AWS_SECRET_ACCESS_KEY | AWS secret access key |
| AWS_REGION | AWS region (e.g., `us-east-1`) |
| AWS_S3_BUCKET | Name of your S3 bucket |
| OPENAI_API_KEY | OpenAI secret key |
| DATABASE_URL | PostgreSQL connection string |
| SECRET_KEY_BASE | Secret for Phoenix session encryption |
| PORT | HTTP server port (default: 4000) |
| POOL_SIZE | DB connection pool size |
