# reports

Directory for reports, standard output, and standard error output.

Copyright (c) 2026 paulsinclair51
SPDX-License-Identifier: MIT For license details, see the LICENSE file in the paulsinclair51/lubtype repository root.

## litetest_test_report.txt

The report summarizing test results (pass, fail, fault counts, totals, etc.)
for a run of executeable test_litetest.

If the executeable test_litetest was run by ../Makefile, Makefile concatenates
standard error output to the report.

## litetest_test_report-i.txt

The report summarizing test results for a test run with injected fails
and faults (test_litetest executed with -i option specified).

If the executable test_litetest was run by ../Makefile, Makefile concatenates
standard error output to the report.

## out.txt

Standard output for the run corresponding to litetest_test_report.txt if
the executable test_litetest was run by ../Makefile.

## out-i.txt

Standard output for the run corresponding to litetest_test_report-i.txt if
the executable test_litetest was run by ../Makefile.

## errout.txt

Makefile artifact for the standard error output gnerated, if any, by a test run.

../Makefile concatenates the standard error output to the report and then the file
is removed by ..\Makefile.
