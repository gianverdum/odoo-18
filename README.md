# Odoo 18 Community Docker Setup

## Quick Start

1. Ensure Docker and Docker Compose are installed
2. Copy environment file: `cp .env.example .env`
3. Run: `docker compose up -d`
4. Access Odoo at: http://localhost:8069
5. Create your first database via the web interface

## Folder Structure

- `config/` → Odoo configuration files (production-optimized)
- `addons/` → Módulos disponíveis para instalação
- `data/` → Persistent database data (Docker volumes)

## Available Modules

This installation includes over 700 modules organized in the following categories:

**📊 Accounting & Finance:**
Complete accounting management, electronic invoicing, payments, taxes, financial analysis, fiscal reports

**🛒 Sales & CRM:**
Sales management, customer relationship, quotations, commercial proposals, subscription sales, loyalty programs

**📦 Inventory & Logistics:**
Stock control, warehouse management, shipping, barcodes, lot tracking and expiration, landed costs

**👥 Human Resources:**
Employees, recruitment, leaves, expenses, attendance, skills, timesheets, absence management

**🏭 Manufacturing (MRP):**
Production, manufacturing orders, subcontracting, bill of materials, repairs, production costs

**🛍️ E-commerce & Website:**
Online store, blog, events, forum, landing pages, SEO, online payments

**📅 Projects & Tasks:**
Project management, timesheets, tasks, Kanban, Gantt, hourly billing

**💬 Communication:**
Live chat, email marketing, SMS, Google/Microsoft integrations, notifications

**📍 Point of Sale (POS):**
Point of sale, offline sales, hardware integrations, restaurants, self-order

**🌍 Localizations:**
Over 100 countries supported including Brazil, Argentina, Mexico, Portugal, United States, European, Asian and African countries

**🎨 Themes & Interface:**
MUK custom themes (muk_web_theme, muk_web_chatter, muk_web_colors, muk_web_appsbar)

## Development Workflow

- Restart Odoo after configuration changes: `docker compose restart odoo`
- View logs: `docker compose logs -f odoo`

## Deployment

For automated production deployment:

```bash
./deploy.sh
```

For detailed deployment instructions, database access, and production setup, see [DEPLOY.md](DEPLOY.md).
