"""Fail CI if a workflow introduces unbounded temporary artifact retention."""
from pathlib import Path
import sys
import yaml


def check(root=Path('.')):
    problems = []
    count = 0
    for path in sorted((root / '.github/workflows').glob('*')):
        if path.suffix not in ('.yml', '.yaml'):
            continue
        data = yaml.safe_load(path.read_text(encoding='utf-8-sig'))
        for job_name, job in (data.get('jobs') or {}).items():
            for step in job.get('steps') or []:
                uses = str(step.get('uses', '')).lower()
                if not uses.startswith(('actions/upload-artifact@', 'actions/upload-pages-artifact@')):
                    continue
                count += 1
                options = step.get('with') or {}
                # The private administrator installer is delivered manually, for seven days.
                expected = 7 if root.name == 'Gestor-de-Equipamentos' and options.get('name') == 'Gestor_Equipamentos_ADMIN' else 1
                if type(options.get('retention-days')) is not int or options['retention-days'] != expected:
                    problems.append(f'{path}:{job_name}: {options.get("name", "artifact")} requires retention-days: {expected}')
    return count, problems


if __name__ == '__main__':
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    count, problems = check(root)
    for problem in problems:
        print(problem)
    if problems:
        raise SystemExit(1)
    print(f'Artifact retention policy passed ({count} upload steps).')
