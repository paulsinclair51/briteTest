# LiteTest Framework Guide

This guide documents the internal architecture and design of the LiteTest framework.  
It is intended for maintainers and contributors working on the implementation.

### Internal Symbols in the Header

LiteTest exposes some internal symbols in `litetest.h` because the framework’s
macros expand into code that depends on internal types and helper functions.
These symbols must be visible to user code for the macros to compile correctly,
but they are not part of the public API and should not be used directly.

Their presence in the header reflects C implementation requirements, not intended
usage. Contributors may modify these symbols as needed, provided the public API
contract remains intact.


---

## 1. Introduction
(High‑level description of the framework internals and design goals.)

---

## 2. Architecture Overview
- Process model  
- Thread model  
- Signal handling  
- Fault detection  
- Execution flow  

---

## 3. Orchestrator Internals
- Initialization  
- Argument parsing  
- Report lifecycle  
- Category aggregation  

---

## 4. Test Group Internals
- Group initialization  
- Execution scheduling  
- Result accumulation  

---

## 5. Test Execution Engine
- Expression evaluation  
- Isolation modes  
- Concurrency model  
- Error and fault propagation  

---

## 6. Process‑Isolated Execution
- Child process creation  
- Monitoring and timeouts  
- Exit code interpretation  
- Fault mapping  

---

## 7. Thread‑Isolated Execution
- Thread creation  
- Synchronization  
- Fault boundaries  

---

## 8. Signal Guard System
- Installed handlers  
- Supported signals  
- Fault classification  
- Recovery behavior  

---

## 9. Report Generation Internals
- Output formatting  
- Category totals  
- Fault messages  
- Notes and metadata  

---

## 10. Internal State and Global Variables
(Placeholder for internal state descriptions.)

---

## 11. Error Handling and Safety Guarantees
(Placeholder for internal error semantics.)

---

## 12. Implementation Notes
- Portability considerations  
- POSIX dependencies  
- Platform differences  

---

## 13. Future Improvements
(Placeholder for roadmap items.)

