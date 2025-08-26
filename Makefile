# ODIN BLESSED: Development Productivity Makefile
# Quick commands for JLAM infrastructure management
# Created by: ELITE DEVOPS MASTER

.PHONY: help start stop restart status logs health test validate clean

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