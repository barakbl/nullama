# Contributing to Nullama

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Maintainer

- **Barak Bloch** — [barak.bloch@gmail.com](mailto:barak.bloch@gmail.com)

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](../../issues) to report bugs or suggest features.
- Include steps to reproduce, expected behavior, and actual behavior.
- Mention your Nushell version and OS.

### Submitting Changes

1. Fork the repository.
2. Create a feature branch from `main` (`git checkout -b feature/my-change`).
3. Make your changes.
4. Test your generated `.nu` files in Nushell to confirm they parse and run correctly.
5. Update `CHANGELOG.txt` with a summary of your changes.
6. Submit a pull request against `main`.

### Adding a New CLI Wrapper

1. Create a directory under `wrappers/` named after the CLI tool (e.g., `wrappers/mytool/`).
2. Add a TOML spec file (`mytool.toml`) following the schema documented in the README.
3. Generate the Nushell commands with `/to_nu wrappers/mytool/mytool.toml`.
4. Include both the `.toml` and generated `.nu` file in your PR.

### Code Style

- Keep generated Nushell code minimal — no unnecessary comments or boilerplate.
- TOML specs should include `description` fields for all flags and positional args.
- Use `parse_format` over `parse_pattern` (regex) whenever possible.

### Commit Messages

- Use concise, descriptive commit messages.
- Start with a verb in imperative mood (e.g., "Add kubectl wrapper", "Fix flag handling").

## Code of Conduct

Be respectful and constructive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) code of conduct.

## Questions?

Reach out to the maintainer at [barak.bloch@gmail.com](mailto:barak.bloch@gmail.com) or open an issue.
