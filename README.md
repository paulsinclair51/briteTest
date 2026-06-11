# LiteTest

LiteTest is a lightweight C/C++ testing framework implemented as a single `.h` / `.c` pair with no external dependencies. It provides simple test definitions, fault‑tolerant execution, and clear reporting — ideal for small to medium C projects that need reliable testing without heavy tooling.

## Quick Start

To try LiteTest:

1. Copy `litetest.h` and `litetest.c` into your project directory.
2. Create `test_quick.c` and paste in the example test group and orchestrator.
3. Build the test executable:

   ```sh
   cc -std=c99 -Wall -Wextra -o test_quick test_quick.c litetest.c
   ```

4. Run it:

   ```sh
   ./test_quick
   ```

5. View the generated report:

   ```sh
   less quick_test_report.txt
   ```

See the **LiteTest User Guide** for concepts, workflow, and examples.

## Key Features

- Pure C implementation  
- Minimal footprint (single header + source)  
- Fault detection using POSIX signals  
- Optional process‑isolated execution  
- Parallel and concurrent test execution  
- Clear pass/fail/fault reporting  
- Simple API based on macros and test group functions  

## Documentation

- **LiteTest User Guide** — Concepts, workflow, examples  
- **LiteTest API Reference** — Public API types, enums, macros, and functions  
- **LiteTest Contributor Guide** — Versioning, branching, testing, documentation rules  

## License

MIT License — see `LICENSE` for details.
