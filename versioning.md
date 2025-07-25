# Versioning Strategy

This project uses a linear, infrastructure-centric versioning scheme designed for practical development and deployment workflows. Versions are tracked in the `VERSION` file at the root of the repository.

## Format

Version.Major.Minor

- **Version** (first digit): Reserved for major structural overhauls or foundational resets.
- **Major** (second digit): Indicates a milestone for core platform features.
- **Minor** (third digit): Incremented for each meaningful functional improvement, bug fix, or feature addition that works and is committed.
- **Optional Suffixes** (`a`, `b`, `c`, etc.): May be appended to denote non-incremental hotfixes or temporary patches. These are not guaranteed to be stable.

## Principles

- Minor versions (e.g. `0.0.54 → 0.0.55`) are bumped frequently — whenever something functional is added or changed and it works.
- Major versions are rare and only incremented when the project reaches a meaningful operational baseline.
- Patch-level distinctions are intentionally avoided. Instead, minor versions cover all functional updates.  Out of band patches and hotfixes will use letter suffixes.
- Commit messages may or may not include version references; version tracking is maintained manually via the `VERSION` file.
- The system may reach high minor version numbers before hitting version `1.0.0` or beyond — this is expected and acceptable.

## Example Progression

- `0.0.1`: First working commit
- `0.0.42`: Dozens of iterative improvements
- `0.1.0`: First stable milestone, basic system complete
- `0.1.37`: Continued enhancements after milestone
- `1.0.0`: Official release with major features in place
- `1.0.5a`: Quick-fix applied post-release

## Notes

- This versioning scheme is designed for internal clarity and control, not strict semantic compatibility.
- Tagging or release automation may be layered on in the future, but is not required for version management.

