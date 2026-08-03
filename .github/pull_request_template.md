## Summary

## Scope and documentation

- [ ] No runtime behavior, image, port, volume, secret or operator script changed unintentionally
- [ ] User-facing behavior and navigation are documented
- [ ] Screenshots are real, sanitized, rights-cleared and have useful alt text; otherwise no image is committed

## Validation

- [ ] `git diff --check`
- [ ] `python3 scripts/docs/validate_docs.py`
- [ ] `python3 -m unittest discover -s tests -v`
- [ ] Shell scripts remain valid
- [ ] No secrets, private repository URLs, private addresses, media, databases or compiled binaries added
- [ ] Compose remains version-pinned and Community remains licence-optional

## Security and legal

Describe licence/notice changes and any security impact. Never paste `.env`, licence keys, Icecast passwords, tokens, private media or personal data.
