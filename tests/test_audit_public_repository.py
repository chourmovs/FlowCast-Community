import importlib.util
from pathlib import Path
import tempfile, unittest
SPEC=importlib.util.spec_from_file_location('audit',Path(__file__).parents[1]/'scripts/audit-public-repository.py'); MOD=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(MOD)
class AuditTests(unittest.TestCase):
 def test_clean_example(self):
  with tempfile.TemporaryDirectory() as d:
   Path(d,'README.md').write_text('safe'); self.assertEqual(MOD.audit(Path(d)),[])
 def test_sensitive_extension(self):
  with tempfile.TemporaryDirectory() as d:
   Path(d,'station.sqlite').write_text(''); self.assertTrue(MOD.audit(Path(d)))
 def test_token(self):
  with tempfile.TemporaryDirectory() as d:
   Path(d,'oops.txt').write_text('ghp_'+'A'*30); self.assertTrue(MOD.audit(Path(d)))
 def test_env_example_allowed(self):
  with tempfile.TemporaryDirectory() as d:
   Path(d,'.env.example').write_text('PASSWORD=change-me'); self.assertEqual(MOD.audit(Path(d)),[])
if __name__=='__main__': unittest.main()
