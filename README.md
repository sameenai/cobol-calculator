# COBOL CLI Calculator

A command-line calculator written in COBOL (GnuCOBOL) that performs basic arithmetic operations. It accepts expressions in the format `<number> <operator> <number>` and returns the result.

## Project Structure

```
calculator.cob   — Main calculator program (COBOL source code)
run_tests.sh     — Language-agnostic test suite (44 test cases, Bash)
Makefile         — Build commands (COBOL-specific, replace when transcribing)
.gitignore       — Excludes compiled binary and object files
README.md        — This file
```

### How the files relate to each other

```
                 ┌─────────────────┐
                 │  calculator.cob │  ← source code (language-specific)
                 └────────┬────────┘
                          │
                   make build
                          │
                          ▼
                 ┌─────────────────┐
                 │  ./calculator   │  ← executable entry point
                 └────────┬────────┘
                          │
              invoked by run_tests.sh
                          │
                          ▼
                 ┌─────────────────┐
                 │  run_tests.sh   │  ← test runner (language-agnostic)
                 └─────────────────┘
```

**Critical point:** `run_tests.sh` does NOT compile or build anything. It only invokes `./calculator "<expression>"` and checks the output. The build step is in the `Makefile` and is the ONLY language-specific part of the test pipeline.

## How to Build

Requires GnuCOBOL (`cobc`) to be installed.

```bash
make build
```

Or directly:

```bash
cobc -x -o calculator calculator.cob
```

This produces an executable binary called `calculator` in the project root.

## How to Run

### Batch Mode (single expression via command-line argument)

```bash
./calculator "2 + 3"
# Output: 5

./calculator "10 / 3"
# Output: 0.3333

./calculator "2 ^ 10"
# Output: 1024
```

### Interactive Mode (REPL, no arguments)

```bash
./calculator
# Displays a prompt "> " and waits for input
# Type an expression and press Enter to see the result
# Type QUIT to exit
```

## How to Run Tests

```bash
make test
```

Or, if `./calculator` is already built:

```bash
./run_tests.sh
```

The test runner checks that `./calculator` exists and is executable, then runs all 44 test cases against it.

## Supported Operators

| Operator | Operation        | Example        | Result |
|----------|------------------|----------------|--------|
| `+`      | Addition         | `2 + 3`        | `5`    |
| `-`      | Subtraction      | `10 - 3`       | `7`    |
| `*`      | Multiplication   | `4 * 5`        | `20`   |
| `/`      | Division         | `7 / 2`        | `3.5000` |
| `^`      | Exponentiation   | `2 ^ 10`       | `1024` |
| `%`      | Modulo           | `10 % 3`       | `1`    |

## Input Format

Every expression must be exactly three tokens separated by spaces:

```
<left_operand> <operator> <right_operand>
```

- Operands can be integers or decimals (e.g., `42`, `-5`, `3.14`).
- Negative numbers use a leading minus with no space (e.g., `-7`).
- The operator must be a single character from the supported set above.

## Output Format

- If the result is a whole number, it is displayed as an integer with NO decimal point. Example: `5`
- If the result has a fractional component, it is displayed with exactly 4 decimal places. Example: `3.5000`
- Error messages are prefixed with `Error:` and printed to stdout (not stderr).
- Output is exactly one line with no leading/trailing whitespace.

## Error Handling

The calculator handles these error conditions:

| Condition                  | Exact Output                                    |
|----------------------------|-------------------------------------------------|
| Division by zero           | `Error: division by zero`                       |
| Modulo by zero             | `Error: modulo by zero`                         |
| Unknown operator           | `Error: unknown operator X` (where X is the char) |
| Malformed expression       | `Error: expected format <number> <op> <number>` |
| Empty input (batch mode)   | `Error: empty input`                            |

## Program Architecture (calculator.cob)

The program is a single COBOL source file organized into these sections:

### Data Division (Variables)

| Variable             | Type                | Purpose                                      |
|----------------------|---------------------|----------------------------------------------|
| `WS-INPUT`           | `PIC X(80)`         | Raw input string from user or command line    |
| `WS-LEFT-STR`        | `PIC X(20)`         | Left operand as a string during parsing       |
| `WS-RIGHT-STR`       | `PIC X(20)`         | Right operand as a string during parsing      |
| `WS-OPERATOR`        | `PIC X(1)`          | The operator character                        |
| `WS-LEFT`            | `PIC S9(10)V9(4)`   | Left operand as numeric (signed, 10 int digits, 4 decimal) |
| `WS-RIGHT`           | `PIC S9(10)V9(4)`   | Right operand as numeric                      |
| `WS-RESULT`          | `PIC S9(10)V9(4)`   | Calculation result                            |
| `WS-ERROR-FLAG`      | `PIC 9`             | 0 = no error, 1 = error occurred              |
| `WS-BATCH-MODE`      | `PIC 9`             | 0 = interactive mode, 1 = batch mode          |
| `WS-PARSE-STATE`     | `PIC 9`             | State machine state for input parsing         |

### Procedure Division (Logic Flow)

1. **MAIN-PROGRAM** — Entry point. Checks if command-line arguments exist. If yes, processes the single expression and exits (batch mode). If no, enters an interactive loop that reads expressions until the user types QUIT.

2. **PARSE-INPUT** — Validates that input is non-empty, then calls PARSE-LOOP.

3. **PARSE-LOOP** — A character-by-character state machine that splits the input string into three parts:
   - State 0: Accumulate characters into left operand string until a space is found.
   - State 1: Skip spaces, then capture the operator character.
   - State 2: Skip the space after the operator.
   - State 3: Accumulate characters into right operand string.
   
   After parsing, converts the string operands to numeric values using `FUNCTION NUMVAL`.

4. **DO-CALCULATION** — An `EVALUATE` statement (equivalent to switch/case) that dispatches to the correct arithmetic operation based on the operator. Checks for division/modulo by zero before computing.

5. **POWER-CALC** — Implements exponentiation via a loop (multiply the base by itself N times). COBOL has no built-in power operator so this is done manually.

6. **DISPLAY-RESULT** — Checks if the result has a fractional part. If zero, displays as integer. Otherwise displays with 4 decimal places.

### Numeric Precision

- Numbers are stored as `PIC S9(10)V9(4)` — signed, up to 10 integer digits, 4 decimal places.
- Maximum representable integer: 9,999,999,999
- Minimum representable value: -9,999,999,999.9999
- Decimal precision: 4 places (results are truncated, not rounded)
- Exponentiation is limited to integer exponents between 0 and 999.

## Test Suite (run_tests.sh)

**The test runner is completely language-agnostic.** It does not know or care what language the calculator is written in. It:

1. Checks that `./calculator` exists and is executable
2. For each test case, invokes `./calculator "<expression>"` and captures stdout+stderr
3. Compares actual output to expected output (exact string match after whitespace trimming)
4. Prints color-coded PASS/FAIL results
5. Exits with code 0 if all pass, code 1 if any fail

**The test runner does NOT build, compile, or install anything.** Building is handled separately by the `Makefile`.

### Complete Test Case List

#### Addition (7 tests)
| Input         | Expected Output |
|---------------|-----------------|
| `2 + 3`       | `5`             |
| `0 + 0`       | `0`             |
| `100 + 200`   | `300`           |
| `-5 + 3`      | `-2`            |
| `-5 + -3`     | `-8`            |
| `999 + 1`     | `1000`          |
| `1 + 99999`   | `100000`        |

#### Subtraction (6 tests)
| Input         | Expected Output |
|---------------|-----------------|
| `10 - 3`      | `7`             |
| `3 - 10`      | `-7`            |
| `5 - 5`       | `0`             |
| `100 - 1`     | `99`            |
| `0 - 0`       | `0`             |
| `-3 - -3`     | `0`             |

#### Multiplication (7 tests)
| Input         | Expected Output |
|---------------|-----------------|
| `4 * 5`       | `20`            |
| `0 * 999`     | `0`             |
| `1 * 42`      | `42`            |
| `-3 * 4`      | `-12`           |
| `-3 * -4`     | `12`            |
| `7 * 7`       | `49`            |
| `100 * 100`   | `10000`         |

#### Division (7 tests)
| Input         | Expected Output          |
|---------------|--------------------------|
| `10 / 2`      | `5`                      |
| `7 / 2`       | `3.5000`                 |
| `100 / 4`     | `25`                     |
| `-10 / 2`     | `-5`                     |
| `0 / 5`       | `0`                      |
| `1 / 3`       | `0.3333`                 |
| `5 / 0`       | `Error: division by zero` |

#### Exponentiation (7 tests)
| Input         | Expected Output |
|---------------|-----------------|
| `2 ^ 3`       | `8`             |
| `3 ^ 2`       | `9`             |
| `5 ^ 0`       | `1`             |
| `7 ^ 1`       | `7`             |
| `2 ^ 10`      | `1024`          |
| `10 ^ 3`      | `1000`          |
| `1 ^ 99`      | `1`             |

#### Modulo (6 tests)
| Input         | Expected Output          |
|---------------|--------------------------|
| `10 % 3`      | `1`                      |
| `10 % 5`      | `0`                      |
| `7 % 2`       | `1`                      |
| `100 % 7`     | `2`                      |
| `9 % 9`       | `0`                      |
| `5 % 0`       | `Error: modulo by zero`  |

#### Error Handling (4 tests)
| Input         | Expected Output                                   |
|---------------|---------------------------------------------------|
| `2 & 3`       | `Error: unknown operator &`                       |
| `2 ! 3`       | `Error: unknown operator !`                       |
| `42`          | `Error: expected format <number> <op> <number>`   |
| `+ +`         | `Error: expected format <number> <op> <number>`   |

---

## Transcription Guide for AI Agents

If you are transcribing this calculator to another programming language, read this entire section carefully before writing any code.

### What you are producing

You must produce exactly these files:

| File           | Purpose                                              |
|----------------|------------------------------------------------------|
| `calculator`   | The executable entry point (see details below)       |
| `run_tests.sh` | **COPY THIS FILE UNCHANGED** from the original repo  |
| `Makefile`     | Updated for your language's build commands           |

### The `calculator` executable — THIS IS THE KEY REQUIREMENT

The test runner calls `./calculator "<expression>"`. This means there MUST be a file named exactly `calculator` (no extension) in the project root that is executable.

**For compiled languages** (C, Go, Rust, etc.):
- Your Makefile compiles your source into a binary named `calculator`
- Example Makefile: `build: go build -o calculator main.go`

**For interpreted languages** (Python, Ruby, Node, etc.):
- Create a file named `calculator` (NOT `calculator.py`, NOT `calculator.rb`)
- The file must have a shebang line as the first line
- The file must be executable (`chmod +x calculator`)

Example for Python — the file must be named `calculator` (no `.py` extension):
```python
#!/usr/bin/env python3
import sys

# ... your calculator logic here ...

if __name__ == "__main__":
    expression = " ".join(sys.argv[1:])
    # process and print result
```

Example for Node.js — the file must be named `calculator` (no `.js` extension):
```javascript
#!/usr/bin/env node

const expression = process.argv.slice(2).join(' ');
// ... your calculator logic here ...
```

### The `run_tests.sh` file — DO NOT MODIFY

Copy `run_tests.sh` exactly as-is into your transcribed project. Do not rewrite it in another language. Do not modify how it invokes the calculator. It calls `./calculator "<expression>"` and that must work.

### The `Makefile` — ADAPT FOR YOUR LANGUAGE

Replace the COBOL build command with whatever your language needs:

```makefile
# Python example (just needs chmod):
build:
	chmod +x calculator

test: build
	./run_tests.sh

# Go example:
build:
	go build -o calculator main.go

test: build
	./run_tests.sh

# Rust example:
build:
	cargo build --release
	cp target/release/calculator .

test: build
	./run_tests.sh
```

### Behavioral contract to preserve

1. **CLI interface**: `./calculator "<expression>"` receives the full expression as a single command-line argument string (e.g., `sys.argv[1]` in Python contains `"2 + 3"`). Print exactly one line to stdout and exit.

2. **Interactive mode**: When invoked with no arguments (`./calculator`), enter a REPL that prints `> ` as a prompt, reads a line, processes it, prints the result, and repeats. Exit when the user types `QUIT` (case-insensitive).

3. **Output formatting**:
   - Integer results: print with NO decimal point (e.g., `5`, NOT `5.0`, NOT `5.0000`)
   - Fractional results: print with EXACTLY 4 decimal places (e.g., `3.5000`, NOT `3.5`)
   - No leading/trailing whitespace in output

4. **Error messages**: Print to stdout (NOT stderr). Must match EXACTLY:
   - `Error: division by zero`
   - `Error: modulo by zero`
   - `Error: unknown operator X` (where X is the actual character)
   - `Error: expected format <number> <op> <number>`
   - `Error: empty input`

5. **Operator behavior**:
   - `+` addition
   - `-` subtraction
   - `*` multiplication
   - `/` true division (not integer division)
   - `^` exponentiation (integer exponents only, 0-999)
   - `%` modulo

6. **Parsing**: Split on spaces. The expression is always `<number> <space> <operator> <space> <number>`. Negative numbers have the minus attached (e.g., `-5 + 3` is three tokens: `-5`, `+`, `3`).

### Common transcription mistakes to avoid

- **DO NOT** name your source file `calculator.py` or `calculator.js` and then try to invoke it as `./calculator.py`. The entry point must be named `calculator` with no extension.
- **DO NOT** put a compilation/build step inside `run_tests.sh`. That file must remain unchanged.
- **DO NOT** print results to stderr. All output (results AND errors) goes to stdout.
- **DO NOT** print `5.0` or `5.0000` for integer results. Print `5`.
- **DO NOT** print `3.5` for fractional results. Print `3.5000` (exactly 4 decimal places).
- **DO NOT** add extra output like "Result: 5" or blank lines. Output is exactly one line: the number or the error message.

### Verification

After transcription, run:
```bash
make test
```

All 44 tests must pass. If they don't, the transcription has a bug — check output formatting first (that's the most common failure).
