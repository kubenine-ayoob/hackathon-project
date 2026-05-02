# StackNine Invoice Processor

A small web app: you **upload an invoice PDF**, the system **reads it** and **fills in** things like vendor, date, total, and line items. You see the result on a **results** page after a short wait.

This repo has the **Python services** plus **Terraform** to run everything on **AWS**.

---

## The big picture (simple)

Think of **three programs** and **one database**:

| Part | What it does |
|------|----------------|
| **main-backend** | Web pages, login, upload. Tells the others to work. |
| **extractor** | Opens the PDF and pulls out **raw text**. |
| **parser** | Reads that text and turns it into **structured fields** (saved in the DB). |
| **PostgreSQL** | Stores jobs, text, and final invoice data. |

On **your laptop**, Docker runs all of them together.

On **AWS**, the same apps run in **containers** (ECS). Files go to **S3**. A **Lambda** function notices the new file and tells **main-backend** to start processing. Users only reach the app through a **load balancer** (ALB).

```
  You  ──►  Internet load balancer  ──►  main-backend (website + upload)
                                              │
                         ┌────────────────────┼────────────────────┐
                         ▼                    ▼                    ▼
                    PostgreSQL           extractor              parser
                    (database)           (PDF → text)           (text → fields)

  PDF file:  saved in S3  ──►  Lambda  ──►  calls main-backend to start the job
```

---

## Run it on your computer

1. Install [Docker](https://docs.docker.com/get-docker/).
2. In this folder, run:

```bash
docker compose up --build
```

3. Open **http://localhost:8000** in the browser.

Use any email format for login. Try a PDF from the **`sample-invoices/`** folder.

| What | Address |
|------|---------|
| Website | http://localhost:8000 |
| Database (from host) | port **5433** |

---

## Run it on AWS (short version)

All cloud setup is in the **`terraform/`** folder.

1. **Configure** `terraform/terraform.tfvars` (region, name prefix, and **`github_repository`** = your real GitHub repo, e.g. `your-user/your-repo`).
2. **Create** the S3 bucket + DynamoDB table for Terraform state (if you use the S3 backend), then run **`terraform init`** and **`terraform apply`** with AWS credentials.
3. Copy **`terraform output public_alb_url`** — that is your **live website URL**.
4. **Build Docker images** from the **root** of this repo (not inside `terraform/`) and **push** them to the ECR URLs from **`terraform output ecr_repositories`**.
5. **Restart ECS services** (or use GitHub Actions) so new images are picked up.

**GitHub Actions:** set the secret **`AWS_ROLE_ARN`** to **`terraform output github_deploy_role_arn`**. The value of **`github_repository`** in tfvars must match the repo that runs the workflow, or login will fail.

More detail and naming rules: **`TASK-1.md`**.

---

## Folder map

```
db/                 Database schema (init.sql)
main-backend/       Website + upload + “run the pipeline”
extractor/          PDF text extraction
parser/             Parse text into invoice fields
lambda/             Wakes up when S3 gets a file (AWS only)
sample-invoices/    Example PDFs to test
terraform/          AWS network, ECS, RDS, S3, Lambda, etc.
.github/workflows/  Auto-deploy on push to main
```

---

## If something goes wrong

| Problem | What to check |
|---------|----------------|
| GitHub Action cannot log in to AWS | Secret **`AWS_ROLE_ARN`** and **`github_repository`** in `terraform.tfvars` match your real repo; run **`terraform apply`** again after changing tfvars. |
| Upload works but status stays **pending** | **Lambda** logs in CloudWatch; S3 must trigger Lambda; SSM parameter **`/stacknine/main-backend-url`** must be your public ALB URL. |
| Website does not load on AWS | ECS tasks running? Target group **healthy**? Docker images **pushed** to ECR? |

---

## Tests (optional)

From the repo root:

```bash
cd extractor && python -m pytest tests/
cd parser && python -m pytest tests/
cd main-backend && python -m pytest tests/
```

---

Hackathon brief and full requirements: **`TASK-1.md`**.
