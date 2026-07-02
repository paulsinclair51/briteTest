#!/usr/bin/env python3

# replace_phrases.py - Replace configured phrases across markdown files.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

"""
Replace phrases in .md files based on a configuration file.

Copyright (c) 2026 Paul Sinclair
SPDX-License-Identifier: MIT
For license details, see LICENSE in the repository root.

Configuration file format:
    old_phrase = new_phrase

Each line defines a replacement where:
- old_phrase: the text to find
- new_phrase: the text to replace it with

Whitespace around the '=' is ignored.
Lines starting with '#' are treated as comments.
Empty lines are ignored.

Usage:
    python3 scripts/helpers/replace_phrases.py [config_file] [--dry-run]

Default config file: config/phrase_replacements.txt
"""

import os
import sys
import argparse
from pathlib import Path


def parse_config(config_file):
    """
    Parse the configuration file and return a list of (old_phrase, new_phrase) tuples.
    
    Args:
        config_file: Path to the configuration file
        
    Returns:
        List of (old_phrase, new_phrase) tuples
        
    Raises:
        FileNotFoundError: If config file doesn't exist
        ValueError: If config file has invalid format
    """
    replacements = []
    
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.rstrip('\n\r')
                
                # Skip empty lines and comments
                if not line.strip() or line.strip().startswith('#'):
                    continue
                
                # Parse the replacement
                if '=' not in line:
                    raise ValueError(f"Line {line_num}: Missing '=' separator. Expected format: old_phrase = new_phrase")
                
                old_phrase, new_phrase = line.split('=', 1)
                old_phrase = old_phrase.rstrip()
                new_phrase = new_phrase.lstrip()
                
                if not old_phrase:
                    raise ValueError(f"Line {line_num}: old_phrase cannot be empty")
                
                replacements.append((old_phrase, new_phrase))
    
    except FileNotFoundError:
        raise FileNotFoundError(f"Config file not found: {config_file}")
    
    return replacements


def find_md_files(root_dir='.'):
    """
    Find all .md files in the repository.
    
    Args:
        root_dir: Starting directory (default: current directory)
        
    Yields:
        Path objects for each .md file
    """
    for path in Path(root_dir).rglob('*.md'):
        # Skip hidden directories
        if '/.git' not in str(path) and '/.github' not in str(path):
            yield path


def process_file(file_path, replacements, dry_run=False):
    """
    Replace phrases in a single .md file.
    
    Args:
        file_path: Path to the .md file
        replacements: List of (old_phrase, new_phrase) tuples
        dry_run: If True, don't actually modify the file
        
    Returns:
        Tuple of (replacements_made, changes_list) where changes_list contains
        details about each replacement made
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return 0, [f"Error reading {file_path}: {e}"]
    
    original_content = content
    changes = []
    replacements_made = 0
    
    for old_phrase, new_phrase in replacements:
        if old_phrase in content:
            count = content.count(old_phrase)
            content = content.replace(old_phrase, new_phrase)
            replacements_made += count
            changes.append(f"  - Replaced '{old_phrase}' -> '{new_phrase}' ({count} occurrence{'s' if count != 1 else ''})")
    
    if content != original_content:
        if not dry_run:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
            except Exception as e:
                return 0, [f"Error writing to {file_path}: {e}"]
    
    return replacements_made, changes


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Replace phrases in .md files based on a configuration file',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Configuration file format:
  old_phrase = new_phrase
  
Example:
  # config/phrase_replacements.txt
  BriteTest = MyTestFramework
  Version 1.0.0 = Version 2.0.0
        '''
    )
    
    parser.add_argument(
        'config_file',
        nargs='?',
        default='config/phrase_replacements.txt',
        help='Path to the configuration file (default: config/phrase_replacements.txt)'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be replaced without actually modifying files'
    )
    
    args = parser.parse_args()
    
    # Parse configuration
    try:
        replacements = parse_config(args.config_file)
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    
    if not replacements:
        print(f"No replacements found in {args.config_file}")
        return 0
    
    print(f"Loaded {len(replacements)} replacement(s) from {args.config_file}")
    print()
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be modified\n")
    
    # Find and process all .md files
    md_files = list(find_md_files())
    
    if not md_files:
        print("No .md files found")
        return 0
    
    total_replacements = 0
    files_modified = 0
    
    for file_path in sorted(md_files):
        replacements_made, changes = process_file(file_path, replacements, args.dry_run)
        
        if replacements_made > 0:
            files_modified += 1
            total_replacements += replacements_made
            print(f"{file_path}:")
            for change in changes:
                print(change)
            print()
    
    # Summary
    print("=" * 60)
    if args.dry_run:
        print("DRY RUN SUMMARY:")
    else:
        print("SUMMARY:")
    print(f"  Files processed: {len(md_files)}")
    print(f"  Files modified: {files_modified}")
    print(f"  Total replacements: {total_replacements}")
    
    if args.dry_run:
        print("\nRun without --dry-run to apply these changes")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
