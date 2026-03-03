#!/bin/bash
# Test Group 11: Skill content depth and trigger quality (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

SKILLS_DIR="$PLUGIN_DIR/skills"

SKILLS=(
  "strategy-brainstorm"
  "causal-inference"
  "compound-catalog"
  "git-worktree"
  "swarm-orchestration"
  "reproducible-pipelines"
  "project-setup"
  "structural-modeling"
  "submission-guide"
  "empirical-playbook"
)

group "Content Depth"

# 1: All 10 skills have >=100 lines
all_long=true
for skill in "${SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  lines=0; [ -f "$f" ] && lines=$(wc -l < "$f" | tr -d ' ')
  if [ "${lines:-0}" -lt 100 ]; then
    all_long=false
    must_fix "skill $skill >= 100 lines" "got ${lines:-0} lines"
  fi
done
if $all_long; then pass "all 10 skills have >= 100 lines"; fi

# 2: All 10 skills have >=3 ## section headers
all_headers=true
for skill in "${SKILLS[@]}"; do
  headers=$(grep -c '^## ' "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null) || headers=0
  if [ "$headers" -lt 3 ]; then
    all_headers=false
    must_fix "skill $skill >= 3 sections" "got $headers sections"
  fi
done
if $all_headers; then pass "all 10 skills have >= 3 section headers"; fi

# 3: All 10 skills have code examples
all_code=true
for skill in "${SKILLS[@]}"; do
  codeblocks=$(grep -c '```' "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null) || codeblocks=0
  if [ "$codeblocks" -lt 2 ]; then
    all_code=false
    must_fix "skill $skill has code examples" "got $codeblocks backtick-fence markers"
  fi
done
if $all_code; then pass "all 10 skills have code examples"; fi

# 4: All 10 skills have >=500 words
all_words=true
for skill in "${SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  words=0; [ -f "$f" ] && words=$(wc -w < "$f" | tr -d ' ')
  if [ "${words:-0}" -lt 500 ]; then
    all_words=false
    must_fix "skill $skill >= 500 words" "got ${words:-0} words"
  fi
done
if $all_words; then pass "all 10 skills have >= 500 words"; fi

group "Trigger Quality"

# 5: All skill descriptions have trigger keywords (>=50 chars in first non-frontmatter paragraph)
all_desc=true
for skill in "${SKILLS[@]}"; do
  desc_len=$(SKILL_PATH="$SKILLS_DIR/$skill/SKILL.md" python3 -c "
import sys, os
text = open(os.environ['SKILL_PATH']).read()
# Skip frontmatter
if text.startswith('---'):
    text = text.split('---', 2)[2] if text.count('---') >= 2 else text
# Get first non-empty paragraph
for line in text.strip().split('\n'):
    line = line.strip()
    if line and not line.startswith('#'):
        print(len(line))
        break
else:
    print(0)
" 2>/dev/null)
  if [ "${desc_len:-0}" -lt 50 ]; then
    all_desc=false
    must_fix "skill $skill description >= 50 chars" "got $desc_len chars"
  fi
done
if $all_desc; then pass "all skills have substantial trigger descriptions"; fi

# 6: No two skills share >8 identical significant words in body opener
# Threshold is >8 because a domain-specific plugin has related skills that
# naturally share vocabulary. >8 catches true duplication, not domain overlap.
# Stopwords include common English + skill-structure words (appear in every preamble).
if overlap_detail=$(SKILLS_DIR="$SKILLS_DIR" python3 -c "
import os, re, sys
stopwords = {'the','a','an','and','or','to','in','for','of','with','is','are','this','that','it','on','at','by','from','as','be','was','has','can','will','use','not','but','if','when','your','you','do','no','all',
  'skill','user','reference','covers','using','methods','guide','section','also','used','each','more','than','about','into','between','other','some','most','only','such','these','those','them','they','been','have','which','what','make','tool','tools'}
skills_dir = os.environ['SKILLS_DIR']
skill_words = {}
for skill in os.listdir(skills_dir):
    path = os.path.join(skills_dir, skill, 'SKILL.md')
    if not os.path.isfile(path): continue
    raw = open(path).read()
    # strip YAML frontmatter so field names don't pollute word sets
    if raw.startswith('---'):
        end = raw.find('---', 3)
        if end != -1:
            raw = raw[end+3:]
    text = raw[:500].lower()
    words = set(w for w in re.findall(r'[a-z]{4,}', text) if w not in stopwords)
    skill_words[skill] = words
names = sorted(skill_words)
for i, a in enumerate(names):
    for b in names[i+1:]:
        shared = skill_words[a] & skill_words[b]
        if len(shared) > 8:
            print(f'{a} & {b} share {len(shared)} words: {sorted(shared)[:5]}')
            sys.exit(1)
" 2>/dev/null); then
  pass "no two skills share >8 identical trigger words"
else
  should_fix "skill trigger word overlap" "${overlap_detail:-two skills share too many trigger words}"
fi

group "Domain Content"

# 7-16: Each skill contains expected domain terms
get_skill_terms() {
  case "$1" in
    structural-modeling)  echo "NFXP|MPEC|BLP" ;;
    causal-inference)     echo "IV|2SLS|DiD|RDD" ;;
    empirical-playbook)   echo "method selection|diagnostics|power" ;;
    submission-guide)     echo "journal|referee|revision" ;;
    compound-catalog)     echo "category|frontmatter|problem_type" ;;
    reproducible-pipelines) echo "Makefile|Snakemake|DVC" ;;
    strategy-brainstorm)  echo "approach|parsimony" ;;
    project-setup)        echo "compound-science.local" ;;
    git-worktree)         echo "worktree|branch" ;;
    swarm-orchestration)  echo "parallel|teammate" ;;
  esac
}

for skill in "${SKILLS[@]}"; do
  pattern=$(get_skill_terms "$skill")
  if grep -qiE "$pattern" "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null; then
    pass "skill $skill contains domain terms"
  else
    must_fix "skill $skill domain terms" "missing: $pattern"
  fi
done

group "Integration"

# 17: All skills reference at least one agent name
AGENT_PATTERN="econometric-reviewer|mathematical-prover|numerical-auditor|identification-critic|journal-referee|simulation-designer|process-architect|equilibrium-analyst|calibration-assessor|results-verifier|literature-scout|methods-explorer|data-detective|solutions-archivist|benchmark-researcher|pipeline-validator|reproducibility-checker|specification-analyzer|research-coordinator|progress-tracker"

ref_count=0
for skill in "${SKILLS[@]}"; do
  if grep -qiE "$AGENT_PATTERN" "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null; then
    ref_count=$((ref_count + 1))
  fi
done
if [ "$ref_count" -eq 10 ]; then
  pass "all skills reference at least one agent ($ref_count/10)"
elif [ "$ref_count" -ge 5 ]; then
  should_fix "all skills reference an agent" "$ref_count/10 skills reference agents"
else
  must_fix "all skills reference an agent" "only $ref_count/10 skills reference agents"
fi

# 18: No skill exceeds 2000 lines (bloat guard)
all_slim=true
for skill in "${SKILLS[@]}"; do
  f="$SKILLS_DIR/$skill/SKILL.md"
  lines=0; [ -f "$f" ] && lines=$(wc -l < "$f" | tr -d ' ')
  if [ "${lines:-0}" -gt 2000 ]; then
    all_slim=false
    should_fix "skill $skill <= 2000 lines" "got ${lines:-0} lines"
  fi
done
if $all_slim; then pass "no skill exceeds 2000 lines"; fi

# 19: All skill directories contain exactly 1 file (SKILL.md)
all_single=true
for skill in "${SKILLS[@]}"; do
  count=$(find "$SKILLS_DIR/$skill" -maxdepth 1 -type f | wc -l | tr -d ' ')
  if [ "$count" -ne 1 ]; then
    all_single=false
    must_fix "skill $skill has exactly 1 file" "got $count files"
  fi
done
if $all_single; then pass "all skill directories contain exactly 1 file"; fi

# 20: All skill names match word-word kebab-case
all_kebab=true
for skill in "${SKILLS[@]}"; do
  if ! echo "$skill" | python3 -c "
import sys, re
name = sys.stdin.read().strip()
assert re.match(r'^[a-z]+-[a-z]+$', name), f'{name} not word-word kebab-case'
" 2>/dev/null; then
    all_kebab=false
    must_fix "skill $skill is word-word kebab-case" "naming convention violated"
  fi
done
if $all_kebab; then pass "all skill names match word-word kebab-case"; fi
