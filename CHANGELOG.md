# Changelog

## 2.0.0

### Added
- Command-line options for running without prompts: `--php`, `--node`, `--fix-perms`, `--list`, `--verify`, `--yes`, `--help`, `--version`
- Detection of installed PHP versions (cPanel `ea-php` and CloudLinux `alt-php`) instead of a hardcoded list
- Composer wrapper that always runs with the selected PHP version
- Node.js: any major version or `lts`
- Permission fixes for nested `node_modules/.bin` folders and Laravel `storage/` and `bootstrap/cache/`
- `~/.bashrc` backup before changes
- ShellCheck CI workflow

### Changed
- PHP symlink moved from `~/perl5/bin` to `~/.local/bin` (old symlink and aliases are cleaned up automatically)
- `~/.bashrc` changes live in one marked block, so re-running never adds duplicate lines
- nvm updated from v0.39.0 to v0.40.3 and no longer edits `~/.bashrc` itself
- npm cache is only moved when the current one isn't writable, using the user config instead of `--global`

### Fixed
- Invalid input no longer exits the whole script
- Removed the alias fallback, which pointed at the same missing PHP binary that triggered it
- Verification no longer depends on sourcing `~/.bashrc`

## 1.0.0
- Initial release: interactive PHP and Node.js setup for shared hosting
