#!/bin/bash
# Test runner for the calculator.
# This script is LANGUAGE-AGNOSTIC. It assumes an executable called
# "./calculator" already exists in this directory. It does NOT compile
# or build anything — that is the job of the Makefile or build script.
#
# To use after transcription to another language:
#   1. Ensure "./calculator" is an executable file in this directory.
#      - For compiled languages: compile your source to a binary named "calculator"
#      - For interpreted languages: create a file named "calculator" with a
#        shebang line (e.g. #!/usr/bin/env python3) and chmod +x it
#   2. Run: ./run_tests.sh
#
# The test runner invokes: ./calculator "<expression>"
# and expects exactly one line of output on stdout.

set -e

PASS=0
FAIL=0
TOTAL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check that ./calculator exists and is executable
if [ ! -f ./calculator ]; then
    echo "Error: ./calculator not found."
    echo "Build it first (e.g. 'make build') or ensure the file exists."
    exit 1
fi

if [ ! -x ./calculator ]; then
    echo "Error: ./calculator is not executable. Run: chmod +x calculator"
    exit 1
fi

echo "=== Calculator Test Suite ==="
echo ""

run_test() {
    local description="$1"
    local input="$2"
    local expected="$3"

    TOTAL=$((TOTAL + 1))

    actual=$(timeout 5 ./calculator "$input" 2>&1 || true)
    actual=$(echo "$actual" | xargs)
    expected_trimmed=$(echo "$expected" | xargs)

    if [ "$actual" = "$expected_trimmed" ]; then
        echo -e "  ${GREEN}PASS${NC} [$TOTAL] $description"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC} [$TOTAL] $description"
        echo "        Expected: '$expected_trimmed'"
        echo "        Actual:   '$actual'"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- Addition ---"
run_test "2 + 3 = 5" "2 + 3" "5"
run_test "0 + 0 = 0" "0 + 0" "0"
run_test "100 + 200 = 300" "100 + 200" "300"
run_test "-5 + 3 = -2" "-5 + 3" "-2"
run_test "-5 + -3 = -8" "-5 + -3" "-8"
run_test "999 + 1 = 1000" "999 + 1" "1000"
run_test "1 + 99999 = 100000" "1 + 99999" "100000"

echo ""
echo "--- Subtraction ---"
run_test "10 - 3 = 7" "10 - 3" "7"
run_test "3 - 10 = -7" "3 - 10" "-7"
run_test "5 - 5 = 0" "5 - 5" "0"
run_test "100 - 1 = 99" "100 - 1" "99"
run_test "0 - 0 = 0" "0 - 0" "0"
run_test "-3 - -3 = 0" "-3 - -3" "0"

echo ""
echo "--- Multiplication ---"
run_test "4 * 5 = 20" "4 * 5" "20"
run_test "0 * 999 = 0" "0 * 999" "0"
run_test "1 * 42 = 42" "1 * 42" "42"
run_test "-3 * 4 = -12" "-3 * 4" "-12"
run_test "-3 * -4 = 12" "-3 * -4" "12"
run_test "7 * 7 = 49" "7 * 7" "49"
run_test "100 * 100 = 10000" "100 * 100" "10000"

echo ""
echo "--- Division ---"
run_test "10 / 2 = 5" "10 / 2" "5"
run_test "7 / 2 = 3.5" "7 / 2" "3.5000"
run_test "100 / 4 = 25" "100 / 4" "25"
run_test "-10 / 2 = -5" "-10 / 2" "-5"
run_test "0 / 5 = 0" "0 / 5" "0"
run_test "1 / 3 (repeating)" "1 / 3" "0.3333"
run_test "Division by zero" "5 / 0" "Error: division by zero"

echo ""
echo "--- Exponentiation ---"
run_test "2 ^ 3 = 8" "2 ^ 3" "8"
run_test "3 ^ 2 = 9" "3 ^ 2" "9"
run_test "5 ^ 0 = 1" "5 ^ 0" "1"
run_test "7 ^ 1 = 7" "7 ^ 1" "7"
run_test "2 ^ 10 = 1024" "2 ^ 10" "1024"
run_test "10 ^ 3 = 1000" "10 ^ 3" "1000"
run_test "1 ^ 99 = 1" "1 ^ 99" "1"

echo ""
echo "--- Modulo ---"
run_test "10 % 3 = 1" "10 % 3" "1"
run_test "10 % 5 = 0" "10 % 5" "0"
run_test "7 % 2 = 1" "7 % 2" "1"
run_test "100 % 7 = 2" "100 % 7" "2"
run_test "9 % 9 = 0" "9 % 9" "0"
run_test "Modulo by zero" "5 % 0" "Error: modulo by zero"

echo ""
echo "--- Error Handling ---"
run_test "Unknown operator &" "2 & 3" "Error: unknown operator &"
run_test "Unknown operator !" "2 ! 3" "Error: unknown operator !"
run_test "Missing operand" "42" "Error: expected format <number> <op> <number>"
run_test "Only operator" "+ +" "Error: expected format <number> <op> <number>"

echo ""
echo "=================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, $TOTAL total"
echo "=================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
