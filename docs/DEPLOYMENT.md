# Deployment Guide
## Yarmouk Water Platform

### Prerequisites
- Ubuntu 22.04 LTS (or similar)
- Docker 24.0+
- Docker Compose 2.20+
- 4 CPU cores, 8GB RAM, 50GB storage

### Production Deployment

```bash
# 1. Clone repository
git clone https://github.com/yarmouk-water/platform.git
cd yarmouk-water-platform

# 2. Configure environment
cp .env.example .env
nano .env  # Edit with production values

# 3. SSL Certificates (Let's Encrypt)
sudo certbot certonly --standalone -d api.yarmouk-water.jo -d dashboard.yarmouk-water.jo

# 4. Start services
docker-compose -f docker-compose.prod.yml up -d

# 5. Run migrations
docker-compose exec db psql -U postgres -d yarmouk_water -f /docker-entrypoint-initdb.d/001_initial_schema.sql

# 6. Seed data
docker-compose exec db psql -U postgres -d yarmouk_water -f /docker-entrypoint-initdb.d/seeds/001_roles.sql

# 7. Verify health
curl https://api.yarmouk-water.jo/health
curl https://api.yarmouk-water.jo/ready
```

### Backup Strategy
```bash
# Automated daily backup (cron)
0 2 * * * /opt/yarmouk/scripts/backup.sh

# Manual backup
docker-compose exec db pg_dump -U postgres yarmouk_water > backup_$(date +%Y%m%d).sql
```

### Monitoring
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001
- API Metrics: http://localhost:8000/metrics
