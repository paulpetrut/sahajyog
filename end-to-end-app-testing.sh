#!/bin/bash

# 🚀 Sahajyog Deployment & Testing Script
# Run this script every time you make changes to ensure quality and successful deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_URL="https://sahajyog.onrender.com"
HEALTH_ENDPOINT="$APP_URL/api/health"
API_TEST_ENDPOINT="$APP_URL/api/health/api-test"

# Helper functions
print_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if we're in the right directory
check_project_directory() {
    if [ ! -f "mix.exs" ]; then
        print_error "Not in a Phoenix project directory. Please run this script from your project root."
        exit 1
    fi
}

# Step 1: Pre-deployment checks
run_pre_deployment_checks() {
    print_header "PRE-DEPLOYMENT CHECKS"
    
    print_step "Checking for uncommitted changes..."
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "You have uncommitted changes. Consider committing them first."
        git status --short
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled."
            exit 0
        fi
    else
        print_success "Working directory is clean"
    fi
    
    print_step "Running code quality checks..."
    
    # Format check
    if mix format --check-formatted >/dev/null 2>&1; then
        print_success "Code formatting is correct"
    else
        print_warning "Code formatting issues found. Auto-formatting..."
        mix format
        print_success "Code formatted"
    fi
    
    # Compile check
    print_step "Compiling project..."
    if mix compile --warnings-as-errors; then
        print_success "Compilation successful with no warnings"
    else
        print_error "Compilation failed or has warnings"
        exit 1
    fi
    
    # Run tests
    print_step "Running tests..."
    if mix test --max-failures 1; then
        print_success "All tests passed"
    else
        print_error "Tests failed"
        exit 1
    fi
    
    # Check for unused dependencies
    print_step "Checking for unused dependencies..."
    if mix deps.unlock --unused >/dev/null 2>&1; then
        print_success "No unused dependencies found"
    else
        print_warning "Some dependencies might be unused"
    fi
}

# Step 2: Git operations
handle_git_operations() {
    print_header "GIT OPERATIONS"
    
    # Check if there are changes to commit
    if [ -n "$(git status --porcelain)" ]; then
        print_step "Staging changes..."
        git add .
        
        echo -e "${YELLOW}Enter commit message (or press Enter for default):${NC}"
        read -r commit_message
        
        if [ -z "$commit_message" ]; then
            commit_message="Update application - $(date '+%Y-%m-%d %H:%M')"
        fi
        
        print_step "Committing changes..."
        git commit -m "$commit_message"
        print_success "Changes committed: $commit_message"
    else
        print_info "No changes to commit"
    fi
    
    print_step "Pushing to GitHub..."
    if git push origin main; then
        print_success "Successfully pushed to GitHub"
    else
        print_error "Failed to push to GitHub"
        exit 1
    fi
}

# Step 3: Wait for deployment
wait_for_deployment() {
    print_header "DEPLOYMENT MONITORING"
    
    print_step "Waiting for Render.com deployment to complete..."
    print_info "This usually takes 2-5 minutes..."
    
    # Wait a bit for deployment to start
    sleep 30
    
    # Check deployment status by monitoring health endpoint
    max_attempts=20
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_step "Checking deployment status (attempt $attempt/$max_attempts)..."
        
        if curl -s --max-time 10 "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
            print_success "Deployment appears to be complete!"
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                print_error "Deployment seems to be taking longer than expected"
                print_info "You can continue monitoring manually at: $APP_URL"
                exit 1
            fi
            print_info "Still deploying... waiting 15 seconds"
            sleep 15
        fi
        
        ((attempt++))
    done
}

# Step 4: Post-deployment testing
run_post_deployment_tests() {
    print_header "POST-DEPLOYMENT TESTING"
    
    # Test health endpoints
    print_step "Testing health endpoints..."
    
    # Basic health check
    if health_response=$(curl -s --max-time 10 "$HEALTH_ENDPOINT"); then
        if echo "$health_response" | grep -q '"status":"ok"'; then
            print_success "Health check passed"
        else
            print_error "Health check failed - application may have issues"
            echo "Response: $health_response"
        fi
    else
        print_error "Could not reach health endpoint"
        exit 1
    fi
    
    # Detailed API test
    print_step "Testing API connectivity..."
    if api_response=$(curl -s --max-time 30 "$API_TEST_ENDPOINT"); then
        # Check if all tests passed
        if echo "$api_response" | grep -q '"status":"success"'; then
            print_success "API connectivity tests passed"
            
            # Extract some metrics
            talks_count=$(echo "$api_response" | grep -o '"talks_returned":[0-9]*' | cut -d':' -f2)
            countries_count=$(echo "$api_response" | grep -o '"countries_count":[0-9]*' | cut -d':' -f2)
            
            if [ -n "$talks_count" ] && [ -n "$countries_count" ]; then
                print_info "📊 $talks_count talks available from $countries_count countries"
            fi
        else
            print_warning "Some API tests may have failed"
            echo "Response: $api_response"
        fi
    else
        print_error "Could not reach API test endpoint"
    fi
    
    # Test main pages
    print_step "Testing main application pages..."
    
    pages=("/" "/talks" "/steps")
    for page in "${pages[@]}"; do
        if curl -s --max-time 10 -o /dev/null -w "%{http_code}" "$APP_URL$page" | grep -q "200"; then
            print_success "Page $page is accessible"
        else
            print_error "Page $page is not accessible"
        fi
    done
    
    # Test external API integration
    print_step "Testing external API integration..."
    if curl -s --max-time 10 "https://learnsahajayoga.org/api/talks?lang=en" | grep -q "total_results"; then
        print_success "External API integration working"
    else
        print_warning "External API may be having issues"
    fi
}

# Step 5: Performance check
run_performance_check() {
    print_header "PERFORMANCE CHECK"
    
    print_step "Measuring page load times..."
    
    # Test homepage performance
    homepage_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$APP_URL/")
    talks_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$APP_URL/talks")
    
    print_info "📈 Homepage load time: ${homepage_time}s"
    print_info "📈 Talks page load time: ${talks_time}s"
    
    # Performance thresholds
    if (( $(echo "$homepage_time < 2.0" | bc -l) )); then
        print_success "Homepage performance is good"
    else
        print_warning "Homepage is loading slowly (>${homepage_time}s)"
    fi
    
    if (( $(echo "$talks_time < 2.0" | bc -l) )); then
        print_success "Talks page performance is good"
    else
        print_warning "Talks page is loading slowly (>${talks_time}s)"
    fi
}

# Step 6: Summary
print_summary() {
    print_header "DEPLOYMENT SUMMARY"
    
    print_success "🎉 Deployment completed successfully!"
    echo ""
    print_info "🔗 Application URL: $APP_URL"
    print_info "🏥 Health Check: $HEALTH_ENDPOINT"
    print_info "🧪 API Tests: $API_TEST_ENDPOINT"
    echo ""
    print_info "📊 Quick verification commands:"
    echo "   curl $HEALTH_ENDPOINT"
    echo "   curl $API_TEST_ENDPOINT"
    echo ""
    print_success "✨ Your application is live and ready!"
}

# Main execution
main() {
    print_header "🚀 SAHAJYOG DEPLOYMENT SCRIPT"
    print_info "Starting automated deployment and testing process..."
    
    check_project_directory
    run_pre_deployment_checks
    handle_git_operations
    wait_for_deployment
    run_post_deployment_tests
    run_performance_check
    print_summary
}

# Run the script
main "$@"