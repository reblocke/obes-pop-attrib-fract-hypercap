"""Reconstruct every aliased report profile from the complete aggregate tables."""
from pathlib import Path
from decimal import Decimal, InvalidOperation
import csv, hashlib, json, sys

packet = Path(sys.argv[1])
coverage = Path(sys.argv[2]) if len(sys.argv) > 2 else packet / 'verification/summary-coverage'
output = Path(sys.argv[3]) if len(sys.argv) > 3 else None
tables = packet / 'tables'
if not tables.is_dir():
    tables = packet

def read(path):
    with path.open(newline='') as handle:
        return list(csv.DictReader(handle))

def canonical(value):
    if value in ('', 'NA'):
        return None
    try:
        return Decimal(value)
    except InvalidOperation:
        return value

def values(rows, fields):
    return [tuple(canonical(row[field]) for field in fields) for row in rows]

sources = {name: read(tables / (name + '.csv')) for name in ('variable_summary', 'category_counts')}
seen = set()
checked_rows = 0
file_hashes = {}
for aliases in sorted(coverage.glob('*-aliases.csv')):
    stem = aliases.name.removesuffix('-aliases.csv')
    name = next(name for name in sources if stem.startswith(name + '-'))
    displayed_path = coverage / (stem + '-displayed.csv')
    displayed = read(displayed_path)
    assert displayed, stem
    variable = displayed[0]['variable_id']
    assert all(row['variable_id'] == variable for row in displayed), stem
    fields = [field for field in displayed[0] if field != 'population_id']
    for mapping in read(aliases):
        target = mapping['population_id']
        representative = mapping['representative_id']
        key = (name, variable, target)
        assert key not in seen, key
        original = [row for row in sources[name] if row['variable_id'] == variable and row['population_id'] == target]
        shown = [row for row in displayed if row['population_id'] == representative]
        assert original and shown, key
        assert values(original, fields) == values(shown, fields), key
        seen.add(key)
        checked_rows += len(original)
    for path in (aliases, displayed_path):
        file_hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
expected = {(name, row['variable_id'], row['population_id']) for name, rows in sources.items() for row in rows}
assert seen == expected, {'missing': len(expected - seen), 'extra': len(seen - expected)}
assert checked_rows == sum(map(len, sources.values()))
result = {'status': 'passed', 'scope': 'Complete aggregate profile reconstruction; no patient rows or clinical reads',
          'alias_groups': len(seen), 'original_rows_reconstructed': checked_rows,
          'coverage_csvs': len(file_hashes), 'source_tables': {
              name: {'rows': len(rows), 'sha256': hashlib.sha256((tables / (name + '.csv')).read_bytes()).hexdigest()}
              for name, rows in sources.items()},
          'coverage_file_sha256': file_hashes, 'investigator_approval': 'not asserted'}
if output is not None:
    assert not output.exists(), 'Choose a fresh receipt path; existing review evidence is immutable'
    output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({key: result[key] for key in ('status', 'alias_groups', 'original_rows_reconstructed', 'coverage_csvs')}))
