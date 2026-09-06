import os
import re
import unittest

class SecurityApiKeyTest(unittest.TestCase):
    def test_no_hardcoded_api_keys_in_web_portal_and_scripts(self):
        """Verifies that web_admin_portal.html and scripts do not contain hardcoded Firebase API keys."""
        root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        files_to_check = [
            os.path.join(root_dir, "web_admin_portal.html"),
            os.path.join(root_dir, "scripts", "google_apps_script_sync.js"),
            os.path.join(root_dir, "scripts", "upload_questions.py"),
        ]

        # Firebase API Key regex pattern: AIzaSy followed by 33 base64/URL-safe chars
        api_key_pattern = re.compile(r"AIzaSy[A-Za-z0-9_-]{33}")

        for file_path in files_to_check:
            if not os.path.exists(file_path):
                continue
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                matches = api_key_pattern.findall(content)
                self.assertEqual(
                    len(matches),
                    0,
                    f"Found hardcoded Firebase API key(s) {matches} in {file_path}"
                )

if __name__ == "__main__":
    unittest.main()
