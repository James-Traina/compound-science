#!/bin/bash
# Test Group 1: JSON configuration file validity
source "$(dirname "$0")/../lib/assert.sh"

group "JSON Validity"

# plugin.json
if python3 -c "import json; json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))" 2>/dev/null; then
  pass "plugin.json parses"
else
  must_fix "plugin.json parses" "invalid JSON"
fi

# Required fields in plugin.json
for field in name version description license; do
  if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
assert '$field' in d, 'missing $field'
" 2>/dev/null; then
    pass "plugin.json has '$field'"
  else
    must_fix "plugin.json has '$field'" "field missing"
  fi
done

# Author is an object (not a string)
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
assert isinstance(d.get('author'), dict), 'author must be object'
assert 'name' in d['author'], 'author.name missing'
" 2>/dev/null; then
  pass "plugin.json author is object with name"
else
  must_fix "plugin.json author is object with name" "must be {\"name\": \"...\"} not a string"
fi

# hooks.json
if python3 -c "import json; json.load(open('$PLUGIN_DIR/hooks/hooks.json'))" 2>/dev/null; then
  pass "hooks.json parses"
else
  must_fix "hooks.json parses" "invalid JSON"
fi

# hooks.json has correct wrapper structure
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
assert 'hooks' in d, 'missing hooks wrapper'
assert isinstance(d['hooks'], dict), 'hooks must be object'
" 2>/dev/null; then
  pass "hooks.json has wrapper structure"
else
  must_fix "hooks.json has wrapper structure" "needs {\"hooks\": {...}} format"
fi

# Each hook event has valid structure
if python3 -c "
import json, sys
d = json.load(open('$PLUGIN_DIR/hooks/hooks.json'))
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
" 2>/dev/null; then
  pass "hooks.json hook entries have valid structure"
else
  must_fix "hooks.json hook entries have valid structure" "malformed hook entry"
fi

# .mcp.json
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.mcp.json'))
assert 'mcpServers' in d, 'missing mcpServers'
" 2>/dev/null; then
  pass ".mcp.json parses with mcpServers key"
else
  must_fix ".mcp.json parses with mcpServers key" "invalid or missing key"
fi

# .mcp.json mcpServers should be empty (no duplication with user plugins)
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.mcp.json'))
assert len(d['mcpServers']) == 0, f'mcpServers has {len(d[\"mcpServers\"])} entries'
" 2>/dev/null; then
  pass ".mcp.json mcpServers is empty"
else
  should_fix ".mcp.json mcpServers is empty" "may duplicate user's global MCP plugins"
fi
