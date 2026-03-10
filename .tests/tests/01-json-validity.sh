#!/usr/bin/env bash
# Test Group 1: JSON configuration file validity and structure (16 tests)
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

group "plugin.json Validity"

# 1
py_eval "plugin.json parses" \
  "import json, os; json.load(open(os.environ['PLUGIN_DIR'] + '/.claude-plugin/plugin.json'))" \
  "invalid JSON"

# 2-5: Required fields
for field in name description license; do
  export FIELD="$field"
  py_eval "plugin.json has '$field'" "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/.claude-plugin/plugin.json'))
assert os.environ['FIELD'] in d, 'missing ' + os.environ['FIELD']
" "field missing"
done

# 6
py_eval "plugin.json author is object with name" "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/.claude-plugin/plugin.json'))
assert isinstance(d.get('author'), dict), 'author must be object'
assert 'name' in d['author'], 'author.name missing'
" 'must be {"name": "..."} not a string'

group "hooks.json Validity"

# 7
py_eval "hooks.json parses" \
  "import json, os; json.load(open(os.environ['HOOKS_FILE']))" \
  "invalid JSON"

# 8
py_eval "hooks.json has wrapper structure" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
assert 'hooks' in d, 'missing hooks wrapper'
assert isinstance(d['hooks'], dict), 'hooks must be object'
" 'needs {"hooks": {...}} format'

# 9
py_eval "hooks.json has description" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
assert 'description' in d, 'missing description'
" "top-level description missing"

# 10
py_eval "all hook entries have valid structure" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        assert 'matcher' in m, f'{event}: missing matcher'
        assert 'hooks' in m, f'{event}: missing hooks array'
        for h in m['hooks']:
            assert 'type' in h, f'{event}: hook missing type'
            if h['type'] == 'command':
                assert 'command' in h, f'{event}: command hook missing command'
            elif h['type'] == 'prompt':
                assert 'prompt' in h, f'{event}: prompt hook missing prompt'
" "malformed hook entry"

group "Hook Entry Validation"

# 11: All hook events have proper timeouts
py_eval "all hook events have timeouts" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
missing = []
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h.get('timeout', 0) <= 0:
                missing.append(event)
assert not missing, f'missing timeouts: {missing}'
" "one or more hooks missing timeout"

group "Hook JSON Integrity"

# 12: All matchers are non-empty strings
py_eval "all matchers are non-empty strings" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        assert isinstance(m['matcher'], str) and len(m['matcher']) > 0, f'{event}: empty matcher'
" "found empty or non-string matcher"

# 13: All prompt hooks have non-trivial prompts (>100 chars)
py_eval "all prompt hooks have substantive content" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                assert len(h['prompt']) > 100, f'{event}: prompt too short ({len(h[\"prompt\"])} chars)'
" "prompt too short"

# 14: Hook types are only 'command' or 'prompt'
py_eval "all hook types are command or prompt" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for event, matchers in d['hooks'].items():
    for m in matchers:
        for h in m['hooks']:
            assert h['type'] in ('command', 'prompt'), f'{event}: invalid type {h[\"type\"]}'
" "invalid hook type found"

# 15: plugin.json has version field (semver string)
py_eval "plugin.json has version field" "
import json, os, re
d = json.load(open(os.environ['PLUGIN_DIR'] + '/.claude-plugin/plugin.json'))
assert 'version' in d, 'version field must be present'
assert re.fullmatch(r'\d+\.\d+\.\d+', d['version']), f'version must be semver, got: {d[\"version\"]}'
" "add a semver version field to plugin.json"

# 16: plugin.json has keywords array
py_eval "plugin.json has keywords array" "
import json, os
d = json.load(open(os.environ['PLUGIN_DIR'] + '/.claude-plugin/plugin.json'))
assert isinstance(d.get('keywords'), list), 'keywords must be a list'
assert len(d['keywords']) >= 5, f'too few keywords: {len(d[\"keywords\"])}'
" "keywords array missing or too small"
