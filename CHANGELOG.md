![Changelog](/docs/branding/Logo_with_BrandName.png)

# Changelog

For repository and branch history, generate a report by running
`<repo>/briteRepo/bin/report` or simply `report` (if path is setup)
using the `repo` or `branch` argument. Reports are written to the
`<repo>/reports/` directory. `report` using the `style` argument
generates a report of style violations for the current branch.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary><strong>License</strong></summary>

### License

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</details>

## Help

To view help and usage (in stdout) for the `report` script, run:

```bash
report -h
```

## Examples of Generating Repository Reports

To generate a report of the local repository history for the most
recent 20 activities, run:

```bash
report repo -l 20
```

To filter the local repository report by text, user (named user-approver),
run:

```bash
report repo -q "release" -u user-approver -l 100
```

To generate a report of remote repository history limited to the most
recent 30 activities, run:

```bash
report repo -r -t 20 -l 30
```

## Examples of Generating Branch History Reports

To generate a report of the local current branch history limited to the most
recent 20 activities, run:

```bash
report branch -l 20
```

To generate a report of remote branch history for the current branch limited
to the most recent 30 activities, run:

```bash
report branch -r -t 20 -l 30
```
