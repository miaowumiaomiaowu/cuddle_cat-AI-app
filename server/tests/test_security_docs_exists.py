import os

def test_security_docs_exists():
    assert os.path.exists('docs/security_guidelines.md')

