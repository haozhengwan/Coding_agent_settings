"""Offline installer checks; never run a real installer or change user config."""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def run_shell(self, body):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ['bash', '-c', 'set -eo pipefail\n'
                 'source "$1/lib/network.sh"\n'
                 'source "$1/lib/installers.sh"\ncd "$2"\n' + body,
                 'test', str(ROOT), tmp], text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_failed_download_is_never_executed_and_is_cleaned_up(self):
        self.run_shell('''
download_file() {
    printf '%s' "$2" > installer-path
    printf 'touch executed\\n' > "$2"
    return 6
}
if run_installer https://example.test/install.sh bash; then
    exit 1
else
    [ "$?" = 6 ]
fi
[ ! -e executed ]
[ ! -e "$(cat installer-path)" ]
''')

    def test_installer_arguments_failure_and_cleanup(self):
        self.run_shell('''
download_file() {
    printf '%s' "$2" > installer-path
    printf 'printf "%%s\\\\n" "$@" > arguments\\nexit 7\\n' > "$2"
}
if run_installer https://example.test/install.sh sh --skip-path 'two words'; then
    exit 1
else
    [ "$?" = 7 ]
fi
[ "$(sed -n '1p' arguments)" = --skip-path ]
[ "$(sed -n '2p' arguments)" = 'two words' ]
[ ! -e "$(cat installer-path)" ]
''')

    def test_native_cli_install_and_repeat_run(self):
        self.run_shell('''
mkdir bin
export PATH="$PWD/bin:$PATH"
export TEST_CLI_BIN="$PWD/bin/test_native_cli"
download_file() {
    printf download >> downloads
    cat > "$2" <<'INSTALLER'
#!/bin/sh
printf '#!/bin/sh\\n[ "$1" = --version ]\\n' > "$TEST_CLI_BIN"
chmod +x "$TEST_CLI_BIN"
INSTALLER
}
install_native_cli test_native_cli https://example.test/install.sh sh
install_native_cli test_native_cli https://example.test/install.sh sh
[ "$(cat downloads)" = download ]
''')

    def test_installer_success_without_command_is_failure(self):
        self.run_shell('''
download_file() { printf 'exit 0\\n' > "$2"; }
if install_native_cli missing_test_cli https://example.test/install.sh sh; then
    exit 1
fi
''')

    def test_existing_broken_command_is_failure(self):
        self.run_shell('''
test_broken_cli() { return 9; }
download_file() { touch downloaded; return 1; }
if install_native_cli test_broken_cli https://example.test/install.sh sh; then
    exit 1
else
    [ "$?" = 9 ]
fi
[ ! -e downloaded ]
''')


class EntrypointTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / 'repo'
        self.repo.mkdir()
        self.config = Path(self.temp.name) / 'claude-config'
        self.config.mkdir()
        shutil.copy(ROOT / 'restore.sh', self.repo)
        shutil.copytree(ROOT / 'lib', self.repo / 'lib')
        shutil.copytree(ROOT / 'config', self.repo / 'config')
        (self.repo / '.env').write_text(
            f'CLAUDE_CONFIG_DIR="{self.config}"\nTEST_PRELOADED=yes\n')
        (self.config / 'settings.json').write_text('{"original":true}\n')
        (self.config / 'keybindings.json').write_text('{"bindings":[]}\n')
        # Optional modes are dispatch fixtures, not installers.
        for mode in ('conda', 'uv'):
            (self.repo / f'restore_{mode}.sh').write_text(f'echo selected-{mode}\n')

    def run_entry(self, args=(), mock=''):
        body = '''
source "$1/restore.sh"
shift
# Any attempt to install an environment or plugin must fail this test.
conda() { return 91; }
uv() { return 92; }
npm() { return 93; }
gh() { return 94; }
install_native_cli() {
    [ "$TEST_PRELOADED" = yes ]
    [ "$CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL" = 1 ]
    printf '%s\\n' "$*" >> "$SCRIPT_DIR/calls"
}
''' + mock + '\nmain "$@"\n'
        return subprocess.run(
            ['bash', '-c', body, 'test', str(self.repo), *args],
            text=True, capture_output=True, env=os.environ.copy(),
        )

    def test_default_native_flow_loads_env_and_backs_up_config(self):
        result = self.run_entry()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = (self.repo / 'calls').read_text().splitlines()
        self.assertEqual(calls, [
            'claude https://claude.ai/install.sh bash',
            'codex https://chatgpt.com/codex/install.sh sh',
            'agy https://antigravity.google/cli/install.sh bash --skip-aliases --skip-path',
        ])
        backups = list(self.config.glob('restore-backup.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'settings.json').read_text(), '{"original":true}\n')
        self.assertEqual((backups[0] / 'keybindings.json').read_text(), '{"bindings":[]}\n')
        self.assertEqual(json.loads((self.config / 'settings.json').read_text()),
                         json.loads((ROOT / 'config/settings.json').read_text()))
        for name in ('CLAUDE.md', 'GEMINI.md'):
            self.assertFalse((self.repo / name).exists())
            self.assertFalse((self.config / name).exists())

    def test_install_failure_stops_before_config_restore(self):
        result = self.run_entry(mock='install_native_cli() { return 7; }')
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertEqual((self.config / 'settings.json').read_text(), '{"original":true}\n')
        self.assertFalse(list(self.config.glob('restore-backup.*')))
        self.assertNotIn('部署完成', result.stdout)

    def test_help_and_invalid_arguments_have_no_install_side_effects(self):
        for args, status in [(('--help',), 0), (('--invalid',), 2),
                             (('--uv', '--conda'), 2)]:
            with self.subTest(args=args):
                result = self.run_entry(args)
                self.assertEqual(result.returncode, status, result.stdout + result.stderr)
                self.assertFalse((self.repo / 'calls').exists())

    def test_optional_mode_dispatch(self):
        for mode in ('conda', 'uv'):
            with self.subTest(mode=mode):
                result = self.run_entry((f'--{mode}',))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout.strip(), f'selected-{mode}')
                self.assertFalse((self.repo / 'calls').exists())


if __name__ == '__main__':
    unittest.main()
