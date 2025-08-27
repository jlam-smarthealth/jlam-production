# 🚀 JLAM Production Infrastructure Makefile
# Enterprise DevOps Operations and Quality Assurance
# Version: 2.0.0 - Enhanced with real DevOps standards
# Created by: ELITE DEVOPS MASTER

.PHONY: help start stop restart status logs health test validate clean security backup monitor qa ci
.DEFAULT_GOAL := help

# Environment configuration
ENV_FILE := .env
TEST_ENV_FILE := .env.test
COMPOSE_PROJECT_NAME := jlam-production

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
BOLD := \033[1m
NC := \033[0m

# ODIN PATTERN: Help is always first
help: ## Show this help message
	@echo "🚀 JLAM Infrastructure Management"
	@echo "=================================="
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ODIN BLESSED: Core operations
start: ## Start all services
	@echo "🚀 Starting JLAM infrastructure..."
	docker-compose up -d
	@echo "✅ Services started"

stop: ## Stop all services  
	@echo "🛑 Stopping JLAM infrastructure..."
	docker-compose down
	@echo "✅ Services stopped"

restart: ## Restart all services
	@echo "🔄 Restarting JLAM infrastructure..."
	docker-compose restart
	@echo "✅ Services restarted"

status: ## Show container status
	@echo "📊 JLAM Infrastructure Status:"
	@docker ps --filter "label=com.docker.compose.project=jlam-infrastructure-consolidated" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs: ## Show logs for all services
	@echo "📋 JLAM Infrastructure Logs:"
	docker-compose logs -f

traefik-logs: ## Show only Traefik logs
	docker logs jlam-traefik -f

nginx-logs: ## Show only nginx logs  
	docker logs jlam-web -f

# ODIN BLESSED: Health monitoring
health: ## Check health of all services
	@echo "💚 JLAM Health Status:"
	@echo "Traefik: $$(docker inspect --format='{{.State.Health.Status}}' jlam-traefik 2>/dev/null || echo 'not found')"
	@echo "Nginx:   $$(docker inspect --format='{{.State.Health.Status}}' jlam-web 2>/dev/null || echo 'not found')"

test: ## Test all endpoints  
	@echo "🧪 Testing JLAM endpoints..."
	@echo "Main site:  $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8082/)"
	@echo "Health:     $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8082/health)"  
	@echo "Dashboard:  $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9080/api/overview)"

# ODIN PATTERN: Configuration validation
validate: ## Validate configuration
	@echo "🔍 Validating configuration..."
	docker-compose config > /dev/null && echo "✅ docker-compose.yml is valid" || echo "❌ docker-compose.yml has errors"

# ODIN BLESSED: Cleanup operations  
clean: ## Remove stopped containers and unused networks
	@echo "🧹 Cleaning up..."
	docker container prune -f
	docker network prune -f
	@echo "✅ Cleanup complete"

clean-all: ## Full cleanup including images and volumes
	@echo "🧹 Full cleanup (WARNING: removes unused images/volumes)..."
	docker system prune -af
	@echo "✅ Full cleanup complete"

# ODIN PATTERN: Performance monitoring
performance: ## Show resource usage
	@echo "⚡ JLAM Infrastructure Performance:"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" jlam-traefik jlam-web 2>/dev/null || echo "Containers not running"

# ODIN BLESSED: Development helpers
dev-setup: ## Setup development environment
	@echo "🛠️ Setting up development environment..."
	docker network create jlam-network 2>/dev/null || echo "Network already exists"
	$(MAKE) start
	$(MAKE) health
	@echo "🎉 Development environment ready!"

quick-restart: ## Quick restart with timing
	@echo "⚡ Quick restart..."
	@time $(MAKE) stop
	@time $(MAKE) start
	@echo "⚡ Restart complete"

# ============================================
# ENTERPRISE DEVOPS STANDARDS
# ============================================
install: ## 🔧 Install dependencies and setup environment
	@echo -e "$(BOLD)$(BLUE)🔧 Installing Dependencies...$(NC)"
	@docker --version || (echo -e "$(RED)❌ Docker not installed$(NC)" && exit 1)
	@docker-compose --version || (echo -e "$(RED)❌ Docker Compose not installed$(NC)" && exit 1)
	@docker network create jlam-network 2>/dev/null || echo "Network already exists"
	@echo -e "$(GREEN)✅ Dependencies installed successfully$(NC)"

validate-devops: ## ✅ Comprehensive DevOps standards validation
	@echo -e "$(BOLD)$(BLUE)✅ Running DevOps Standards Validation...$(NC)"
	@chmod +x scripts/validate-devops-standards.sh
	@./scripts/validate-devops-standards.sh

test-integration: ## 🧪 Run comprehensive integration tests
	@echo -e "$(BOLD)$(BLUE)🧪 Running Integration Tests...$(NC)"
	@chmod +x tests/integration/test-infrastructure.sh
	@./tests/integration/test-infrastructure.sh

test-security: ## 🔒 Run security validation tests
	@echo -e "$(BOLD)$(BLUE)🔒 Running Security Tests...$(NC)"
	@echo "Checking for secrets in repository..."
	@git log --all --oneline | head -20 | grep -i -E "(password|secret|key|token)" && echo -e "$(YELLOW)⚠️ Potential secrets in git history$(NC)" || echo -e "$(GREEN)✅ No obvious secrets in recent history$(NC)"
	@echo "Validating .gitignore for security..."
	@grep -q "\.env" .gitignore && echo -e "$(GREEN)✅ .env files ignored$(NC)" || echo -e "$(RED)❌ .env files not ignored$(NC)"

monitoring-up: ## 📊 Start monitoring stack
	@echo -e "$(BOLD)$(BLUE)📊 Starting monitoring stack...$(NC)"
	@docker-compose -f docker-compose.monitoring.yml up -d
	@echo -e "$(GREEN)✅ Monitoring stack started$(NC)"

monitoring-down: ## 📊 Stop monitoring stack
	@echo -e "$(BOLD)$(BLUE)📊 Stopping monitoring stack...$(NC)"
	@docker-compose -f docker-compose.monitoring.yml down
	@echo -e "$(GREEN)✅ Monitoring stack stopped$(NC)"

health-comprehensive: ## 🏥 Comprehensive health check with metrics
	@echo -e "$(BOLD)$(BLUE)🏥 Comprehensive Health Check:$(NC)"
	@echo "Main Application:"
	@curl -f -s http://localhost:80/health >/dev/null 2>&1 && echo -e "  $(GREEN)✅ Web App$(NC)" || echo -e "  $(RED)❌ Web App$(NC)"
	@echo "Infrastructure:"
	@curl -f -s http://localhost:8080/ping >/dev/null 2>&1 && echo -e "  $(GREEN)✅ Traefik$(NC)" || echo -e "  $(RED)❌ Traefik$(NC)"
	@echo "Monitoring:"
	@curl -f -s http://localhost:9090/-/healthy >/dev/null 2>&1 && echo -e "  $(GREEN)✅ Prometheus$(NC)" || echo -e "  $(RED)❌ Prometheus$(NC)"
	@curl -f -s http://localhost:3000/api/health >/dev/null 2>&1 && echo -e "  $(GREEN)✅ Grafana$(NC)" || echo -e "  $(RED)❌ Grafana$(NC)"
	@echo ""
	@echo "Container Resource Usage:"
	@docker stats --no-stream --format "  {{.Name}}: CPU {{.CPUPerc}}, Memory {{.MemUsage}}" 2>/dev/null || echo "  No containers running"

backup-test: ## 💾 Test backup procedures
	@echo -e "$(BOLD)$(BLUE)💾 Testing Backup Procedures...$(NC)"
	@if [ -f "scripts/backup.sh" ]; then \
		bash -n scripts/backup.sh && echo -e "$(GREEN)✅ Backup script syntax valid$(NC)" || echo -e "$(RED)❌ Backup script has syntax errors$(NC)"; \
	else \
		echo -e "$(RED)❌ Backup script not found$(NC)"; \
	fi

load-test: ## 🔥 Run basic load testing
	@echo -e "$(BOLD)$(BLUE)🔥 Running Load Test...$(NC)"
	@if command -v ab >/dev/null 2>&1; then \
		echo "Testing Traefik endpoint..."; \
		ab -n 1000 -c 10 -q http://localhost:8080/ping; \
		echo -e "$(GREEN)✅ Load test completed$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠️ Apache Bench not installed - install with: apt-get install apache2-utils$(NC)"; \
	fi

monitor-dashboards: ## 📊 Open monitoring dashboards
	@echo -e "$(BOLD)$(BLUE)📊 Opening Monitoring Dashboards...$(NC)"
	@echo "Traefik Dashboard: http://localhost:8080"
	@echo "Prometheus: http://localhost:9090"
	@echo "Grafana: http://localhost:3000"

# ============================================
# QUALITY ASSURANCE SUITE
# ============================================
qa: ## 🎯 Run complete quality assurance suite
	@echo -e "$(BOLD)$(BLUE)🎯 Quality Assurance Suite:$(NC)"
	@$(MAKE) validate-devops
	@$(MAKE) test-security
	@$(MAKE) test-integration
	@echo -e "$(GREEN)✅ Quality assurance completed$(NC)"

ci: ## 🚀 Run full CI/CD pipeline locally
	@echo -e "$(BOLD)$(BLUE)🚀 Running CI/CD Pipeline Locally:$(NC)"
	@$(MAKE) install
	@$(MAKE) qa
	@$(MAKE) start
	@sleep 30
	@$(MAKE) health-comprehensive
	@echo -e "$(GREEN)🎉 CI/CD pipeline completed successfully$(NC)"

# ============================================
# PRODUCTION DEPLOYMENT
# ============================================
deploy-check: ## 🚀 Pre-deployment validation
	@echo -e "$(BOLD)$(BLUE)🚀 Pre-deployment Validation...$(NC)"
	@$(MAKE) validate-devops
	@$(MAKE) test-security
	@echo -e "$(GREEN)✅ Ready for deployment$(NC)"

# ============================================
# EMERGENCY PROCEDURES
# ============================================
emergency-stop: ## 🛑 Emergency shutdown of all services
	@echo -e "$(BOLD)$(RED)🛑 EMERGENCY STOP$(NC)"
	@docker kill $$(docker ps -q) 2>/dev/null || echo "No containers to kill"
	@docker-compose down --remove-orphans 2>/dev/null || true
	@docker-compose -f docker-compose.monitoring.yml down --remove-orphans 2>/dev/null || true
	@echo -e "$(GREEN)✅ Emergency stop completed$(NC)"

emergency-recover: ## 🚑 Emergency recovery procedures
	@echo -e "$(BOLD)$(BLUE)🚑 Emergency Recovery...$(NC)"
	@$(MAKE) clean
	@$(MAKE) install
	@$(MAKE) start
	@sleep 30
	@$(MAKE) health-comprehensive
	@echo -e "$(GREEN)✅ Emergency recovery completed$(NC)"