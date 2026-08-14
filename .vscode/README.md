# `<repo>/.vscode/`

Directory containing VS Code workspace configuration files.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

**settings.json**: Workspace-level settings that override user-level VS Code
settings.

**README.md**: This directory guide.

## Subdirectories

None.

## `settings.json`

Modifying or adding settings in this file should be avoided.

This configuration file customizes VS Code behavior with the following
settings:

- **markdownlint.configFile**: Sets the configuration file path for the
  markdownlint extension to `config/markdownlint.json`. This ensures that
  markdown linting follows the project's standardized rules. See
 `config/README.md` for details on the markdownlint configuration.

## Notes

Additional VS Code configuration files may be added here as needed:

- **launch.json**: Debug configurations for running and debugging the project.

- **extensions.json**: Recommended VS Code extensions for this project.

See the [VS Code Documentation](https://code.visualstudio.com/docs/getstarted/settings`)
for more information on workspace settings.
