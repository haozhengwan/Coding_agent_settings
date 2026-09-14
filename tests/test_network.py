"""Offline regression checks: python3 -m unittest discover -s tests -v."""
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class NetworkTests(unittest.TestCase):
    def run_shell(self, script):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ['bash', '-c', 'set -eo pipefail\nsource "$1/lib/network.sh"\n'
                 'cd "$2"\nDOWNLOAD_RETRY_DELAY=0\n' + script, 'test', str(ROOT), tmp],
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_retry_replaces_partial_download(self):
        self.run_shell('''
count=0
curl() {
    count=$((count+1))
    while [ "$1" != --output ]; do shift; done
    if [ "$count" = 1 ]; then printf partial > "$2"; return 18; fi
    printf complete > "$2"
}
download_file https://example.test/file result
[ "$count" = 2 ]
[ "$(cat result)" = complete ]
[ "$(find . -name '*.part.*' | wc -l)" = 0 ]
''')

    def test_failed_download_preserves_existing_file(self):
        self.run_shell('''
DOWNLOAD_ATTEMPTS=2
printf original > result
curl() { return 6; }
if download_file https://example.test/file result; then exit 1; fi
[ "$(cat result)" = original ]
[ "$(find . -name '*.part.*' | wc -l)" = 0 ]
''')

    def test_empty_response_is_failure(self):
        self.run_shell('''
DOWNLOAD_ATTEMPTS=1
curl() { return 0; }
if download_file https://example.test/file result; then exit 1; fi
[ ! -e result ]
''')

    def test_proxy_failure_falls_back_to_official_url(self):
        self.run_shell('''
GITHUB_PROXY_URL=https://proxy.test/
DOWNLOAD_ATTEMPTS=1
curl() {
    while [ "$1" != --output ]; do shift; done
    printf '%s\\n' "$3" >> requests
    case "$3" in https://proxy.test/*) return 22;; esac
    printf archive > "$2"
}
download_github_file https://github.com/example/release result
[ "$(sed -n '1p' requests)" = https://proxy.test/https://github.com/example/release ]
[ "$(sed -n '2p' requests)" = https://github.com/example/release ]
''')

    def test_npm_registry_and_failure_propagation(self):
        self.run_shell('''
NPM_REGISTRY=https://registry.test
fake_npm() { printf '%s\\n' "$@" > arguments; return 7; }
if npm_install_with_retry @openai/codex fake_npm; then exit 1; else [ "$?" = 7 ]; fi
grep -qx https://registry.test arguments
grep -qx -- --fetch-retries=3 arguments
''')

    def test_node_download_failure_stops_install(self):
        source = (ROOT / 'restore_uv.sh').read_text().rsplit('main "$@"', 1)[0]
        # BASH_SOURCE under bash -c resolves relative to this working directory.
        with tempfile.TemporaryDirectory() as tmp:
            script = source + '''
VENV_DIR="$1/venv"
NODE_INSTALL_PREFIX="$VENV_DIR"
OS=Linux
ARCH=x86_64
download_file() { return 6; }
if install_nodejs; then exit 1; fi
[ ! -e "$NODE_INSTALL_PREFIX/bin/node" ]
'''
            result = subprocess.run(['bash', '-c', script, str(ROOT / 'restore_uv.sh'), tmp],
                                    cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
