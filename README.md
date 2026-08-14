# COBOL CLI Calculator

A command-line calculator written in COBOL (GnuCOBOL) that performs basic arithmetic operations. It accepts expressions in the format `<number> <operator> <number>` and returns the result.

## Project Structure

```
calculator.cob   — Main calculator program (COBOL source code)
run_tests.sh     — Test suite with 44 test cases (Bash script)
.gitignore       — Excludes compiled binary and object files
README.md        — This file
```

## How to Build

Requires GnuCOBOL (`cobc`) to be installed.

```bash
cobc -x -o calculator calculator.cob
```

This compiles `calculator.cob` into an executable binary called `calculator`.

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
./run_tests.sh
```

This compiles the source and runs all 44 test cases, printing PASS/FAIL for each.

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

- If the result is a whole number, it is displayed as an integer (no decimal point). Example: `5`
- If the result has a fractional component, it is displayed with exactly 4 decimal places. Example: `3.5000`
- Error messages are prefixed with `Error:` and printed to stdout.

## Error Handling

The calculator handles these error conditions:

| Condition                  | Output                                          |
|----------------------------|-------------------------------------------------|
| Division by zero           | `Error: division by zero`                       |
| Modulo by zero             | `Error: modulo by zero`                         |
| Unknown operator           | `Error: unknown operator X` (where X is the operator) |
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
| `WS-LEFT`            | `PIC S9(10)V9(4)`   | Left operand as a numeric value (signed, 10 integer digits, 4 decimal places) |
| `WS-RIGHT`           | `PIC S9(10)V9(4)`   | Right operand as a numeric value              |
| `WS-RESULT`          | `PIC S9(10)V9(4)`   | Calculation result                            |
| `WS-ERROR-FLAG`      | `PIC 9`             | 0 = no error, 1 = error occurred              |
| `WS-BATCH-MODE`      | `PIC 9`             | 0 = interactive mode, 1 = batch mode          |
| `WS-PARSE-STATE`     | `PIC 9`             | State machine state for input parsing         |

### Procedure Division (Logic Flow)

The program executes in this order:

1. **MAIN-PROGRAM** — Entry point. Checks if command-line arguments exist. If yes, processes the single expression and exits (batch mode). If no, enters an interactive loop that reads expressions until the user types QUIT.

2. **PARSE-INPUT** — Validates that input is non-empty, then calls PARSE-LOOP.

3. **PARSE-LOOP** — A character-by-character state machine that splits the input string into three parts:
   - State 0: Accumulate characters into `WS-LEFT-STR` until a space is found.
   - State 1: Skip spaces, then capture the operator character.
   - State 2: Skip the space after the operator.
   - State 3: Accumulate characters into `WS-RIGHT-STR`.
   
   After parsing, converts the string operands to numeric values using `FUNCTION NUMVAL`.

4. **DO-CALCULATION** — An `EVALUATE` statement (equivalent to switch/case) that dispatches to the correct arithmetic operation based on `WS-OPERATOR`. Checks for division/modulo by zero before computing.

5. **POWER-CALC** — Implements exponentiation via a loop (multiply the base by itself N times). COBOL has no built-in power operator, so this is done manually. Uses a separate loop counter (`WS-POWER-IDX`) to avoid conflicting with the parsing loop counter.

6. **DISPLAY-RESULT** — Checks if the result has a fractional part. If the fractional part is zero, displays as an integer. Otherwise displays with 4 decimal places.

### Numeric Precision

- Numbers are stored as `PIC S9(10)V9(4)` — signed, up to 10 integer digits, 4 decimal places.
- Maximum representable integer: 9,999,999,999
- Minimum representable value: -9,999,999,999.9999
- Decimal precision: 4 places (results are truncated, not rounded)
- Exponentiation is limited to integer exponents between 0 and 999.

## Test Suite (run_tests.sh)

The test runner is a Bash script that:
1. Compiles `calculator.cob` using `cobc -x`
2. For each test case, invokes `./calculator "<expression>"` and captures stdout
3. Compares the actual output to the expected output (exact string match after trimming whitespace)
4. Prints color-coded PASS/FAIL results
5. Exits with code 0 if all pass, code 1 if any fail

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

## Transcription Notes for AI Agents

If you are transcribing this to another language, here is what to preserve:

1. **Interface contract**: The program must accept a single command-line argument in the format `"<number> <operator> <number>"` and print exactly one line of output (the result or an error message). It must also support an interactive REPL mode when no arguments are given.

2. **Operator behavior**: All six operators (`+ - * / ^ %`) must be supported. Exponentiation only needs to handle non-negative integer exponents.

3. **Output formatting**: Whole-number results display without decimals. Fractional results display with 4 decimal places.

4. **Error messages**: Must match exactly as specified in the Error Handling table above (the test suite does exact string matching).

5. **Test suite**: The `run_tests.sh` script should work with any compiled binary named `calculator` that follows the interface contract above. You can rewrite the calculator in any language as long as it compiles/runs as `./calculator "<expression>"`.
