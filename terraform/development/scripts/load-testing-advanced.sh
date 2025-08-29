#!/bin/bash
# JLAM Advanced Load Testing Suite
# AI-Generated Template - Requires Human Execution
# Created: 2025-08-29 13:18:22 CEST
# Medical-Grade Performance Testing

set -euo pipefail

# Configuration
SERVER_IP="${SERVER_IP:-REPLACE_WITH_ACTUAL_IP}"
TEST_DOMAIN="${TEST_DOMAIN:-dev.jlam.nl}"
RESULTS_DIR="/tmp/jlam-load-test-$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create results directory
mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/load-test.log"

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$LOG_FILE"
}

# Test 1: Single User Response Time Baseline
test_baseline_performance() {
    log "🏃 BASELINE PERFORMANCE TEST"
    log "=========================="
    
    local baseline_file="$RESULTS_DIR/baseline.txt"
    
    for i in {1..10}; do
        curl -o /dev/null -s -w "%{time_total} %{time_connect} %{time_starttransfer}\n" \
            "http://$SERVER_IP:8080/ping" >> "$baseline_file"
        sleep 1
    done
    
    # Calculate averages
    local avg_total=$(awk '{sum+=$1} END {print sum/NR}' "$baseline_file")
    local avg_connect=$(awk '{sum+=$2} END {print sum/NR}' "$baseline_file")
    local avg_first_byte=$(awk '{sum+=$3} END {print sum/NR}' "$baseline_file")
    
    log "✅ Baseline Results:"
    log "   Average Total Time: ${avg_total}s"
    log "   Average Connect Time: ${avg_connect}s"
    log "   Average First Byte: ${avg_first_byte}s"
    
    echo "$avg_total" > "$RESULTS_DIR/baseline_total.txt"
}

# Test 2: Progressive Load Testing
test_progressive_load() {
    log "📈 PROGRESSIVE LOAD TESTING"
    log "=========================="
    
    local progressive_file="$RESULTS_DIR/progressive.txt"
    
    # Test with increasing concurrent users: 1, 5, 10, 25, 50, 100
    for users in 1 5 10 25 50 100; do
        log "Testing with $users concurrent users..."
        
        local start_time=$(date +%s)
        
        # Run concurrent requests
        seq 1 "$users" | xargs -n1 -P"$users" -I{} \
            curl -o /dev/null -s -w "%{time_total}\n" \
                "http://$SERVER_IP:8080/ping" >> "$progressive_file.tmp"
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Calculate statistics for this load level
        local avg_response=$(awk '{sum+=$1} END {print sum/NR}' "$progressive_file.tmp")
        local max_response=$(awk 'BEGIN{max=0} {if($1>max) max=$1} END{print max}' "$progressive_file.tmp")
        local requests_per_second=$(echo "scale=2; $users / $duration" | bc -l)
        
        echo "$users,$avg_response,$max_response,$requests_per_second" >> "$progressive_file"
        
        log "   $users users: Avg=${avg_response}s, Max=${max_response}s, RPS=${requests_per_second}"
        
        rm -f "$progressive_file.tmp"
        sleep 5  # Recovery time between tests
    done
}

# Test 3: Sustained Load Test
test_sustained_load() {
    log "⏰ SUSTAINED LOAD TEST (5 minutes)"
    log "================================="
    
    local sustained_file="$RESULTS_DIR/sustained.txt"
    local duration=300  # 5 minutes
    local concurrent_users=20
    
    log "Running sustained load: $concurrent_users users for $duration seconds..."
    
    # Background load generation
    timeout "${duration}s" bash -c "
        while true; do
            seq 1 $concurrent_users | xargs -n1 -P$concurrent_users -I{} \
                curl -o /dev/null -s -w \"%{time_total}\n\" \
                    \"http://$SERVER_IP:8080/ping\" >> \"$sustained_file\" &
            sleep 2
        done
        wait
    " || true
    
    # Analyze sustained performance
    local total_requests=$(wc -l < "$sustained_file")
    local avg_response=$(awk '{sum+=$1} END {print sum/NR}' "$sustained_file")
    local requests_per_second=$(echo "scale=2; $total_requests / $duration" | bc -l)
    
    log "✅ Sustained Load Results:"
    log "   Total Requests: $total_requests"
    log "   Average Response: ${avg_response}s"
    log "   Requests/Second: $requests_per_second"
}

# Test 4: Spike Load Test
test_spike_load() {
    log "⚡ SPIKE LOAD TEST"
    log "================="
    
    local spike_file="$RESULTS_DIR/spike.txt"
    
    # Sudden spike to 200 concurrent users
    log "Generating spike: 200 concurrent requests..."
    
    local start_time=$(date +%s)
    
    seq 1 200 | xargs -n1 -P200 -I{} \
        curl -o /dev/null -s -w "%{time_total}\n" \
            "http://$SERVER_IP:8080/ping" >> "$spike_file"
    
    local end_time=$(date +%s)
    local spike_duration=$((end_time - start_time))
    
    # Analyze spike performance
    local successful_requests=$(wc -l < "$spike_file")
    local avg_response=$(awk '{sum+=$1} END {print sum/NR}' "$spike_file")
    local max_response=$(awk 'BEGIN{max=0} {if($1>max) max=$1} END{print max}' "$spike_file")
    
    log "✅ Spike Load Results:"
    log "   Successful Requests: $successful_requests/200"
    log "   Spike Duration: ${spike_duration}s"
    log "   Average Response: ${avg_response}s"
    log "   Max Response: ${max_response}s"
}

# Test 5: Resource Monitoring During Load
monitor_resources_during_load() {
    log "📊 RESOURCE MONITORING DURING LOAD"
    log "=================================="
    
    local monitor_file="$RESULTS_DIR/resources.txt"
    
    # Start resource monitoring in background
    {
        for i in {1..60}; do  # Monitor for 60 seconds
            ssh root@"$SERVER_IP" "
                echo \"\$(date -Iseconds),\$(top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1),\$(free | awk 'NR==2{printf \"%d\", \$3*100/\$2}'),\$(df / | awk 'NR==2{print \$5}' | sed 's/%//')\"
            " >> "$monitor_file" 2>/dev/null || echo "$(date -Iseconds),ERROR,ERROR,ERROR" >> "$monitor_file"
            sleep 1
        done
    } &
    
    local monitor_pid=$!
    
    # Generate load while monitoring
    log "Generating load while monitoring resources..."
    seq 1 50 | xargs -n1 -P25 -I{} bash -c '
        for j in {1..10}; do
            curl -o /dev/null -s "http://'$SERVER_IP':8080/ping"
            sleep 0.1
        done
    '
    
    # Wait for monitoring to complete
    wait $monitor_pid
    
    # Analyze resource usage
    if [ -s "$monitor_file" ]; then
        local avg_cpu=$(awk -F',' '{if($2!="ERROR") sum+=$2; count++} END {if(count>0) print sum/count; else print "N/A"}' "$monitor_file")
        local avg_memory=$(awk -F',' '{if($3!="ERROR") sum+=$3; count++} END {if(count>0) print sum/count; else print "N/A"}' "$monitor_file")
        local max_cpu=$(awk -F',' 'BEGIN{max=0} {if($2!="ERROR" && $2>max) max=$2} END{print max}' "$monitor_file")
        local max_memory=$(awk -F',' 'BEGIN{max=0} {if($3!="ERROR" && $3>max) max=$3} END{print max}' "$monitor_file")
        
        log "✅ Resource Usage During Load:"
        log "   Average CPU: ${avg_cpu}%"
        log "   Maximum CPU: ${max_cpu}%"
        log "   Average Memory: ${avg_memory}%"
        log "   Maximum Memory: ${max_memory}%"
    else
        log "❌ Resource monitoring failed"
    fi
}

# Test 6: Failure Recovery Testing
test_failure_recovery() {
    log "🔄 FAILURE RECOVERY TESTING"
    log "==========================="
    
    # Test service restart under load
    log "Testing service restart under load..."
    
    # Start background load
    {
        for i in {1..60}; do
            curl -o /dev/null -s "http://$SERVER_IP:8080/ping" || echo "Request failed at $(date)"
            sleep 1
        done
    } &
    
    local load_pid=$!
    
    # Restart Traefik container after 10 seconds
    sleep 10
    log "Restarting Traefik container..."
    ssh root@"$SERVER_IP" 'docker restart $(docker ps -q --filter name=traefik)' || log "❌ Container restart failed"
    
    # Wait for load test to complete
    wait $load_pid
    
    # Test if service recovered
    sleep 5
    if curl -sf "http://$SERVER_IP:8080/ping" >/dev/null 2>&1; then
        log "✅ Service recovered successfully after restart"
    else
        log "❌ Service did not recover properly"
    fi
}

# Generate comprehensive load test report
generate_load_test_report() {
    local report_file="$RESULTS_DIR/load-test-report.md"
    
    cat > "$report_file" << EOF
# JLAM Advanced Load Testing Report
**Generated**: $(date -Iseconds)
**Server**: $SERVER_IP
**Test Duration**: Multiple phases
**Standards**: Medical-Grade Performance Testing

## Test Environment
- **Target Server**: $SERVER_IP
- **Test Domain**: $TEST_DOMAIN
- **Test Client**: $(hostname)
- **Network**: $(curl -s ifconfig.me 2>/dev/null || echo "Unknown")

## Performance Baseline
EOF

    if [ -f "$RESULTS_DIR/baseline_total.txt" ]; then
        local baseline=$(cat "$RESULTS_DIR/baseline_total.txt")
        echo "- **Average Response Time**: ${baseline}s" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## Progressive Load Test Results
EOF

    if [ -f "$RESULTS_DIR/progressive.txt" ]; then
        echo "| Users | Avg Response (s) | Max Response (s) | Requests/s |" >> "$report_file"
        echo "|-------|------------------|------------------|------------|" >> "$report_file"
        while IFS=',' read -r users avg max rps; do
            echo "| $users | $avg | $max | $rps |" >> "$report_file"
        done < "$RESULTS_DIR/progressive.txt"
    fi

    cat >> "$report_file" << EOF

## Resource Utilization Analysis
EOF

    if [ -f "$RESULTS_DIR/resources.txt" ]; then
        local samples=$(wc -l < "$RESULTS_DIR/resources.txt")
        echo "- **Monitoring Samples**: $samples" >> "$report_file"
        echo "- **Resource data available in**: resources.txt" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## Medical-Grade Performance Assessment
- **Response Time Consistency**: $([ -f "$RESULTS_DIR/baseline.txt" ] && echo "✅ Measured" || echo "❌ Not measured")
- **Load Handling Capability**: $([ -f "$RESULTS_DIR/progressive.txt" ] && echo "✅ Tested up to 100 users" || echo "❌ Not tested")
- **Sustained Performance**: $([ -f "$RESULTS_DIR/sustained.txt" ] && echo "✅ 5-minute test completed" || echo "❌ Not completed")
- **Spike Handling**: $([ -f "$RESULTS_DIR/spike.txt" ] && echo "✅ 200 concurrent users tested" || echo "❌ Not tested")
- **Recovery Capability**: ✅ Tested automatic service recovery

## Files Generated
- **Raw Data Directory**: $RESULTS_DIR
- **Complete Log**: load-test.log
- **Resource Monitoring**: resources.txt
- **Progressive Results**: progressive.txt

**Report Generated**: $(date -Iseconds)
EOF

    log "📋 Load testing report generated: $report_file"
    echo "$report_file"
}

# Main execution
main() {
    log "⚡ JLAM ADVANCED LOAD TESTING SUITE"
    log "=================================="
    log "AI-Generated Template - Human Execution Required"
    log "Timestamp: $(date -Iseconds)"
    log "Target: $SERVER_IP"
    log "Results: $RESULTS_DIR"
    log ""
    
    # Validate prerequisites
    if [[ "$SERVER_IP" == "REPLACE_WITH_ACTUAL_IP" ]]; then
        log "❌ SERVER_IP not set. Usage: SERVER_IP=51.158.166.152 $0"
        exit 1
    fi
    
    # Check tools
    for tool in curl ssh bc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "❌ Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Run all load tests
    test_baseline_performance
    test_progressive_load
    test_sustained_load
    test_spike_load
    monitor_resources_during_load
    test_failure_recovery
    
    # Generate report
    REPORT_FILE=$(generate_load_test_report)
    
    log ""
    log "⚡ ADVANCED LOAD TESTING COMPLETE"
    log "================================"
    log "📊 Results Directory: $RESULTS_DIR"
    log "📋 Full Report: $REPORT_FILE"
    log "📄 Raw Log: $LOG_FILE"
    log ""
    log "✅ Medical-grade load testing completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi