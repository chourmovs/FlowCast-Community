#!/usr/bin/env python3
"""Dependency-free policy and credential scanner for the public repository."""
from __future__ import annotations
import argparse, re, sys
from pathlib import Path

BLOCKED_SUFFIXES = {'.db','.sqlite','.sqlite3','.pem','.key','.p12','.mp3','.wav','.flac','.ogg','.so','.dll','.exe','.bin'}
SKIP = {'.git','node_modules','__pycache__','.pytest_cache'}
PATTERNS = {
 'private key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
 'GitHub token': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b'),
 'JWT': re.compile(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{8,}\b'),
 'credential URL': re.compile(r'https?://[^\s/:]+:[^\s/@]+@'),
 'sslip domain': re.compile(r'\b[\w.-]+\.sslip\.io\b', re.I),
 'service platform variable': re.compile(r'\bSERVICE_(?:FQDN|URL)_[A-Z0-9_]+\b'),
 'personal path': re.compile(r'(?:/home/[\w.-]+|/Users/[\w.-]+)'),
 'Docker credentials': re.compile(r'"auths"\s*:\s*\{|DOCKER_AUTH_CONFIG\s*='),
 'probable secret assignment': re.compile(r'(?i)\b(?:password|passwd|api[_-]?key|secret|token|cookie|licen[cs]e[_-]?(?:key|token))\s*[:=]\s*["\']?(?!\$|\{|<|change-me|example|dummy|redacted|false|true)[A-Za-z0-9+/_.-]{12,}'),
 'hard-coded IP': re.compile(r'(?<![\w.])(?!(?:127\.0\.0\.1|0\.0\.0\.0|255\.255\.255\.255)\b)(?:\d{1,3}\.){3}\d{1,3}(?![\w.])'),
}
TEXT_MAX = 2_000_000

def files(root: Path):
 for p in sorted(root.rglob('*')):
  if p.is_file() and not any(part in SKIP for part in p.relative_to(root).parts): yield p

def audit(root: Path) -> list[str]:
 findings=[]
 for p in files(root):
  rel=p.relative_to(root)
  if p.name.startswith('.env') and p.name != '.env.example': findings.append(f'{rel}: non-example environment file')
  if p.suffix.lower() in BLOCKED_SUFFIXES: findings.append(f'{rel}: blocked extension {p.suffix}')
  if p.stat().st_size > TEXT_MAX: findings.append(f'{rel}: oversized/unreviewed file')
  try: data=p.read_text('utf-8')
  except UnicodeDecodeError:
   findings.append(f'{rel}: binary content'); continue
  for name, pattern in PATTERNS.items():
   for match in pattern.finditer(data):
    line=data.count('\n',0,match.start())+1
    # Scanner source and tests contain patterns, not matched values.
    if rel == Path('scripts/audit-public-repository.py') or rel.parts[:1] == ('tests',): continue
    findings.append(f'{rel}:{line}: {name}')
 return findings

def main() -> int:
 parser=argparse.ArgumentParser(); parser.add_argument('root',nargs='?',default='.'); args=parser.parse_args()
 root=Path(args.root).resolve()
 findings=audit(root)
 if findings:
  print('BLOCKING findings:'); print('\n'.join(f'- {x}' for x in findings)); return 1
 print(f'PASS: audited {sum(1 for _ in files(root))} files; no blocking findings.')
 return 0
if __name__ == '__main__': sys.exit(main())
