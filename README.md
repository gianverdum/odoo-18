# Odoo 19 Community Docker Setup

## Quick Start

1. Ensure Docker and Docker Compose are installed
2. Copy environment file: `cp .env.example .env`
3. Run: `docker compose up -d`
4. Access Odoo at: http://localhost:8069
5. Create your first database via the web interface

## Folder Structure

- `config/` → Odoo configuration files (production-optimized)
- `addons/custom/` → Your custom addons
- `addons/oca/` → OCA community addons
- `data/` → Persistent database data (Docker volumes)

## OCA Addons Installed

✅ **Base Infrastructure:**
- server-tools
- web
- server-ux

✅ **CRM & Sales:**
- crm
- sale-workflow

✅ **Project Management:**
- project

✅ **Human Resources:**
- hr

✅ **Finance & Accounting:**
- account-financial-tools
- account-invoicing
- account-payment
- account-analytic

✅ **Purchase & Workflow:**
- purchase-workflow

✅ **Portuguese (Brazil) Localization:**
- l10n-brazil

## Custom Addons Installed

✅ **UI/UX:**
- muk_web_theme

## Post-Setup Actions Required

1. **Activate Developer Mode** in Odoo
2. **Update Apps List** (Apps → Update Apps List)
3. **Install Portuguese (Brazil)** language:
   - Settings → Translations → Languages
   - Install Portuguese (Brazil)
4. **Install required modules** selectively (avoid installing everything)

## Development Workflow

- Place custom addons in `addons/custom/`
- Place OCA addons in `addons/oca/`
- Restart Odoo after adding new addons: `docker compose restart odoo`

## Deployment

For automated production deployment:
```bash
./deploy.sh
```

For detailed deployment instructions, database access, and production setup, see [DEPLOY.md](DEPLOY.md).