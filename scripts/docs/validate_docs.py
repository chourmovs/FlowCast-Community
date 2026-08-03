#!/usr/bin/env python3
"""Dependency-free policy checks for the public documentation showcase."""
from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parents[2]
errors=[]
required=['LICENSE','THIRD_PARTY_NOTICES.md','ACKNOWLEDGEMENTS.md','TRADEMARKS.md','PRIVACY.md','DISCLAIMER.md','SUPPORT.md','CONTRIBUTING.md','CODE_OF_CONDUCT.md','SECURITY.md','docs/legal/licensing.md']
for name in required:
 if not (ROOT/name).is_file(): errors.append(f'missing required document: {name}')
version=(ROOT/'VERSION').read_text().strip()
readme=(ROOT/'README.md').read_text()
install=f'https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v{version}/install.sh | sudo bash -s -- --version {version}'
if install not in readme: errors.append('README installation command does not match VERSION')
private_repo=re.compile(r'github\.com/chourmovs/FlowCast(?:[./\s]|$)',re.I)
private_ip=re.compile(r'(?<![\d.])(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(?![\d.])')
placeholder=re.compile(r'\b(?:TODO|TBD|FIXME|lorem ipsum)\b',re.I)
secret=re.compile(r'(?i)(?:password|token|secret|license_key)\s*[:=]\s*["\']?[A-Za-z0-9_./+-]{12,}')
markdown=list(ROOT.glob('*.md'))+list((ROOT/'docs').rglob('*.md'))
link_re=re.compile(r'!?\[([^\]]*)\]\(([^)]+)\)')
headings={}
for path in markdown:
 text=path.read_text()
 rel=path.relative_to(ROOT)
 if private_repo.search(text): errors.append(f'{rel}: private repository URL forbidden')
 if private_ip.search(text): errors.append(f'{rel}: private IP address forbidden')
 if placeholder.search(text) and 'explicit' not in text.lower(): errors.append(f'{rel}: unexplained placeholder marker')
 if secret.search(text): errors.append(f'{rel}: possible secret assignment')
 slugs=set()
 for h in re.findall(r'^#{1,6}\s+(.+?)\s*$',text,re.M):
  slug=re.sub(r'[^\w\- ]','',h.lower()).strip().replace(' ','-')
  slugs.add(slug)
 headings[path.resolve()]=slugs
 for alt,target in link_re.findall(text):
  if target.startswith(('http://','https://','mailto:','#')): continue
  raw=target.split('#',1)[0]
  dest=(path.parent/raw).resolve() if raw else path.resolve()
  if not dest.exists(): errors.append(f'{rel}: broken relative link {target}')
  if text[text.find(f'[{alt}]({target})')-1:text.find(f'[{alt}]({target})')]=='!' and not alt.strip(): errors.append(f'{rel}: image missing alt text')
for path in markdown:
 text=path.read_text(); rel=path.relative_to(ROOT)
 for _,target in link_re.findall(text):
  if '#' not in target or target.startswith(('http://','https://')): continue
  raw,anchor=target.split('#',1); dest=((path.parent/raw).resolve() if raw else path.resolve())
  if dest in headings and anchor and anchor.lower() not in headings[dest]: errors.append(f'{rel}: missing anchor #{anchor} in {dest.relative_to(ROOT)}')
for img in (ROOT/'docs/assets').rglob('*'):
 if img.is_file() and img.stat().st_size>1_048_576: errors.append(f'{img.relative_to(ROOT)}: image exceeds 1 MiB')
for manifest in list(ROOT.glob('*.yml'))+list(ROOT.glob('*.yaml')):
 if re.search(r'AGPL',manifest.read_text(),re.I): errors.append(f'{manifest.name}: unexpected AGPL declaration')
if errors:
 print('\n'.join(f'ERROR: {e}' for e in errors)); sys.exit(1)
print(f'documentation validation passed: {len(markdown)} Markdown files, version {version}')
