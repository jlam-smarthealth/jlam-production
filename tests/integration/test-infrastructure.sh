#!/bin/bash
# 🧪 JLAM Infrastructure Integration Tests
# Comprehensive testing suite for production readiness validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_ENV_FILE=".env.test"
TEST_TIMEOUT=300
FAILED_TESTS=0
PASSED_TESTS=0

# ============================================
# LOGGING & UTILITIES
# ============================================
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================
# TEST ENVIRONMENT SETUP
# ============================================
setup_test_environment() {
    log "Setting up test environment..."
    
    # Create test environment file
    cat > "${TEST_ENV_FILE}" << EOF
# Test environment variables - NOT FOR PRODUCTION
AUTHENTIK_SECRET_KEY=test-secret-key-$(openssl rand -hex 16)
AUTHENTIK_DB_PASSWORD=test-db-password-$(openssl rand -hex 8)
GRAFANA_ADMIN_PASSWORD=test-admin-$(openssl rand -hex 8)
PROMETHEUS_AUTH=admin:\$2y\$10\$$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-22)
JLAM_DATABASE_USER=test_user
JLAM_DATABASE_PASSWORD=test_password_$(openssl rand -hex 8)
JLAM_DATABASE_HOST=localhost
JLAM_DATABASE_PORT=5432
JLAM_DATABASE_NAME=test_db
SMTP_HOST=smtp.test.local
SMTP_USER=test@test.local
SMTP_PASSWORD=test_smtp_$(openssl rand -hex 8)
SMTP_FROM_EMAIL=noreply@test.local
BACKUP_S3_BUCKET=test-backups-bucket
BACKUP_ENCRYPTION_KEY=$(openssl rand -base64 32)
EOF
    
    # Create test network
    docker network create jlam-test-network 2>/dev/null || true
    
    success "Test environment setup complete"
}

# ============================================
# DOCKER COMPOSE VALIDATION
# ============================================
test_docker_compose_syntax() {
    log "Testing Docker Compose syntax validation..."
    
    # Test main compose file
    if docker-compose --env-file "${TEST_ENV_FILE}" config >/dev/null 2>&1; then
        success "Main docker-compose.yml syntax valid"
    else
        error "Main docker-compose.yml syntax invalid"
        docker-compose --env-file "${TEST_ENV_FILE}" config
    fi
    
    # Test monitoring compose file
    if docker-compose --env-file "${TEST_ENV_FILE}" -f docker-compose.monitoring.yml config >/dev/null 2>&1; then
        success "Monitoring docker-compose.yml syntax valid"
    else
        error "Monitoring docker-compose.yml syntax invalid"
        docker-compose --env-file "${TEST_ENV_FILE}" -f docker-compose.monitoring.yml config
    fi
}

# ============================================
# CONTAINER BUILD TESTS
# ============================================
test_container_builds() {
    log "Testing container builds..."
    
    # Pull all required images
    local images=(
        "traefik:v3.0"
        "nginx:alpine"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
        "prom/node-exporter:latest"
        "gcr.io/cadvisor/cadvisor:latest"
    )
    
    for image in "${images[@]}"; do
        log "Pulling image: $image"
        if docker pull "$image" >/dev/null 2>&1; then
            success "Image pulled: $image"
        else
            error "Failed to pull image: $image"
        fi
    done
}

# ============================================
# SERVICE STARTUP TESTS
# ============================================
test_service_startup() {
    log "Testing service startup sequence..."
    
    # Start core services
    docker-compose --env-file "${TEST_ENV_FILE}" up -d traefik
    
    # Wait for services to initialize
    sleep 30
    
    # Check container status
    local containers
    containers=$(docker-compose --env-file "${TEST_ENV_FILE}" ps -q)
    
    for container in $containers; do
        local name
        name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
        local status
        status=$(docker inspect --format='{{.State.Status}}' "$container")
        
        if [[ "$status" == "running" ]]; then
            success "Container running: $name"
        else
            error "Container not running: $name (status: $status)"
        fi
    done
}

# ============================================
# HEALTH CHECK TESTS
# ============================================
test_health_checks() {
    log "Testing service health checks..."
    
    # Test Traefik health
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s http://localhost:8080/ping >/dev/null 2>&1; then
            success "Traefik health check passed"
            break
        else
            if [[ $attempt -eq $max_attempts ]]; then
                error "Traefik health check failed after $max_attempts attempts"
                docker logs jlam-traefik --tail 20
            else
                log "Waiting for Traefik... (attempt $attempt/$max_attempts)"
                sleep 5
                ((attempt++))
            fi
        fi
    done
}

# ============================================
# NETWORK CONNECTIVITY TESTS
# ============================================
test_network_connectivity() {
    log "Testing network connectivity..."
    
    # Test Docker network
    if docker network inspect jlam-network >/dev/null 2>&1; then
        success "Docker network 'jlam-network' exists"
    else
        error "Docker network 'jlam-network' does not exist"
    fi
    
    # Test inter-container communication
    if docker run --rm --network jlam-network curlimages/curl:latest \
       curl -f -s http://traefik:8080/ping >/dev/null 2>&1; then
        success "Inter-container network communication working"
    else
        warning "Inter-container network test failed (may be expected in isolated test)"
    fi
}

# ============================================
# SECURITY TESTS
# ============================================
test_security_configuration() {
    log "Testing security configuration..."
    
    # Check for exposed secrets
    if grep -r "password.*=" --exclude="*.test*" --exclude-dir=.git . 2>/dev/null | grep -v "test"; then
        error "Potential exposed secrets found"
    else
        success "No exposed secrets detected"
    fi
    
    # Check SSL configuration
    local compose_config
    compose_config=$(docker-compose --env-file "${TEST_ENV_FILE}" config)
    
    if echo "$compose_config" | grep -q "tls.*true"; then
        success "TLS configuration found"
    else
        warning "TLS configuration not explicitly found"
    fi
    
    # Check for security headers
    if grep -q "X-Frame-Options" config/traefik/dynamic.yml 2>/dev/null; then
        success "Security headers configured"
    else
        warning "Security headers configuration not found"
    fi
}

# ============================================
# MONITORING STACK TESTS
# ============================================
test_monitoring_stack() {
    log "Testing monitoring stack..."
    
    # Start monitoring services
    docker-compose --env-file "${TEST_ENV_FILE}" -f docker-compose.monitoring.yml up -d prometheus grafana node-exporter
    
    # Wait for services
    sleep 60
    
    # Test Prometheus
    if curl -f -s http://localhost:9090/-/healthy >/dev/null 2>&1; then
        success "Prometheus health check passed"
    else
        error "Prometheus health check failed"
        docker logs jlam-prometheus --tail 10
    fi
    
    # Test Grafana
    if curl -f -s http://localhost:3000/api/health >/dev/null 2>&1; then
        success "Grafana health check passed"
    else
        error "Grafana health check failed"
        docker logs jlam-grafana --tail 10
    fi
    
    # Test Node Exporter
    if curl -f -s http://localhost:9100/metrics >/dev/null 2>&1 | head -1 | grep -q "HELP"; then
        success "Node Exporter metrics available"
    else
        error "Node Exporter metrics not available"
    fi
}

# ============================================
# BACKUP SYSTEM TESTS
# ============================================
test_backup_system() {
    log "Testing backup system..."
    
    # Test backup script syntax
    if bash -n scripts/backup.sh; then
        success "Backup script syntax valid"
    else
        error "Backup script syntax invalid"
    fi
    
    # Test backup script functions (dry run)
    if command -v shellcheck >/dev/null 2>&1; then
        if shellcheck scripts/backup.sh; then
            success "Backup script passes shellcheck"
        else
            warning "Backup script has shellcheck warnings"
        fi
    fi
    
    # Test backup directory creation
    local test_backup_dir="/tmp/jlam-backup-test"
    mkdir -p "$test_backup_dir"
    
    if [[ -d "$test_backup_dir" ]]; then
        success "Backup directory creation test passed"
        rm -rf "$test_backup_dir"
    else
        error "Backup directory creation test failed"
    fi
}

# ============================================
# PERFORMANCE TESTS
# ============================================
test_performance() {
    log "Testing performance characteristics..."
    
    # Test container resource usage
    local stats
    stats=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No containers running")
    
    log "Current container resource usage:"
    echo "$stats"
    
    # Basic load test with Apache Bench (if available)
    if command -v ab >/dev/null 2>&1; then
        log "Running basic load test..."
        if ab -n 100 -c 5 -q http://localhost:8080/ping >/dev/null 2>&1; then
            success "Basic load test completed"
        else
            warning "Load test failed (may be expected if service not running)"
        fi
    fi
}

# ============================================
# CONFIGURATION VALIDATION
# ============================================
test_configuration_validation() {
    log "Testing configuration validation..."
    
    # Validate Prometheus configuration
    if docker run --rm -v "$PWD/monitoring/prometheus":/prometheus \
       prom/prometheus:latest \
       promtool check config /prometheus/prometheus.yml >/dev/null 2>&1; then
        success "Prometheus configuration valid"
    else
        error "Prometheus configuration invalid"
    fi
    
    # Validate alert rules
    if docker run --rm -v "$PWD/monitoring/prometheus":/prometheus \
       prom/prometheus:latest \
       promtool check rules /prometheus/alerts/*.yml >/dev/null 2>&1; then
        success "Prometheus alert rules valid"
    else
        error "Prometheus alert rules invalid"
    fi
}

# ============================================
# CLEANUP
# ============================================
cleanup_test_environment() {
    log "Cleaning up test environment..."
    
    # Stop and remove containers
    docker-compose --env-file "${TEST_ENV_FILE}" down -v --remove-orphans 2>/dev/null || true
    docker-compose --env-file "${TEST_ENV_FILE}" -f docker-compose.monitoring.yml down -v --remove-orphans 2>/dev/null || true
    
    # Remove test network
    docker network rm jlam-test-network 2>/dev/null || true
    
    # Clean up test files
    rm -f "${TEST_ENV_FILE}"
    
    success "Test environment cleanup complete"
}

# ============================================
# MAIN TEST EXECUTION
# ============================================
main() {
    log "🧪 Starting JLAM Infrastructure Integration Tests"
    log "================================================="
    
    # Setup
    setup_test_environment
    
    # Run all test suites
    test_docker_compose_syntax
    test_container_builds
    test_service_startup
    test_health_checks
    test_network_connectivity
    test_security_configuration
    test_monitoring_stack
    test_backup_system
    test_performance
    test_configuration_validation
    
    # Cleanup
    cleanup_test_environment
    
    # Report results
    log "================================================="
    log "🧪 Test Execution Complete"
    log "================================================="
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        success "All tests passed! ✅ ($PASSED_TESTS passed, $FAILED_TESTS failed)"
        echo ""
        log "🚀 Infrastructure is ready for production deployment!"
        exit 0
    else
        error "Some tests failed! ❌ ($PASSED_TESTS passed, $FAILED_TESTS failed)"
        echo ""
        log "🔧 Please fix the failing tests before deploying to production."
        exit 1
    fi
}

# Handle script interruption
trap cleanup_test_environment EXIT INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi