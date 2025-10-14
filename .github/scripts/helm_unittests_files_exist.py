#!/usr/bin/env python3
import os
import sys

def main():
    missing_files = []
    chart_dirs = []
    for root, dirs, files in os.walk(".", topdown=True):
        if ".git" in dirs:
            dirs.remove(".git")

        if "Chart.yaml" in files:
            chart_dirs.append(root)
            # Prevent recursion into subcharts, as they are handled independently.
            if "charts" in dirs:
                dirs.remove("charts")

    for chart_dir in chart_dirs:
        templates_dir = os.path.join(chart_dir, "templates")
        tests_dir = os.path.join(chart_dir, "tests")

        if not os.path.isdir(templates_dir):
            continue

        for template_root, _, template_files in os.walk(templates_dir):
            for template_file in template_files:
                if not template_file.endswith((".yaml", ".yml", ".txt")):
                    continue

                template_path = os.path.join(template_root, template_file)

                template_name_no_ext, _ = os.path.splitext(os.path.basename(template_file))
                expected_test_file = os.path.join(tests_dir, f"{template_name_no_ext}_test.yaml")

                if not os.path.exists(expected_test_file):
                    missing_files.append(f"- Template file {template_path} missing expected test {expected_test_file}")

    if missing_files:
        print("Missing test files:")
        for file in sorted(missing_files):
            print(file)
        sys.exit(1)
    else:
        print("All templates have a corresponding test file.")

if __name__ == "__main__":
    main()
