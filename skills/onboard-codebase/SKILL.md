---
name: onboard-codebase
description: Analyze an existing codebase and record learnings so the dev-team can work effectively in an established project.
---

# Onboard Codebase

When `@dev-team` is brought into an existing project (source files already present), run this skill to learn about the codebase before recommending specialists or starting work.

## When to Use

After `bootstrap-project` completes, if the project has existing source files. Detection:

```bash
# Check if there are source files beyond just .gitignore and .team/
file_count=$(find . -type f \
  -not -path './.git/*' \
  -not -path './.team/*' \
  -not -name '.gitignore' \
  -not -name 'AGENTS.md' \
  | wc -l)

if [ "$file_count" -gt 0 ]; then
  echo "Existing codebase detected ($file_count files) — running onboarding"
fi
```

## Phase 1: Scan

Gather facts about the codebase using tool calls. No guessing.

### Languages & Frameworks
```bash
# Detect by file extension
find . -type f -not -path './.git/*' -not -path './.team/*' -not -path '*/node_modules/*' \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -15

# Check package managers and framework configs
ls package.json Cargo.toml go.mod pyproject.toml Gemfile pom.xml build.gradle \
   composer.json *.csproj *.sln mix.exs 2>/dev/null

# Read package.json dependencies (if exists)
cat package.json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
deps=list(d.get('dependencies',{}).keys())
dev=list(d.get('devDependencies',{}).keys())
print('Dependencies:', ', '.join(deps[:15]))
print('DevDependencies:', ', '.join(dev[:15]))
" 2>/dev/null
```

### Project Structure
```bash
# Directory tree (2 levels, no hidden dirs, no node_modules)
find . -type d -not -path './.git/*' -not -path '*/node_modules/*' \
  -not -path './.team/*' -maxdepth 3 | sort | head -40

# Count files by directory
find . -type f -not -path './.git/*' -not -path '*/node_modules/*' \
  -not -path './.team/*' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -15
```

### Documentation
```bash
# Read README (first 100 lines)
head -100 README.md 2>/dev/null

# Check for other docs
ls CONTRIBUTING.md CHANGELOG.md docs/ wiki/ 2>/dev/null
```

### Build & Test Infrastructure
```bash
# npm scripts (if package.json)
cat package.json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
scripts=d.get('scripts',{})
for k,v in scripts.items(): print(f'  {k}: {v}')
" 2>/dev/null

# Makefile targets
grep '^[a-zA-Z_-]*:' Makefile 2>/dev/null | head -15

# Test files
find . -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name 'test_*' \) \
  -not -path '*/node_modules/*' -not -path './.git/*' | head -20

# CI/CD
ls .github/workflows/*.yml .github/workflows/*.yaml \
   .gitlab-ci.yml Jenkinsfile .circleci/config.yml \
   Dockerfile docker-compose.yml 2>/dev/null
```

### Environment & Config
```bash
# Environment files
ls .env .env.example .env.* 2>/dev/null

# Config files
ls tsconfig.json jsconfig.json .eslintrc* .prettierrc* \
   webpack.config.* vite.config.* next.config.* \
   jest.config.* vitest.config.* 2>/dev/null
```

### API Surface
```bash
# API definitions
find . -type f \( -name '*.openapi.*' -o -name '*.swagger.*' -o -name '*.graphql' \
  -o -name '*.proto' -o -name '*.gql' \) -not -path '*/node_modules/*' 2>/dev/null

# Route files (common patterns)
find . -type f \( -name 'routes.*' -o -name 'router.*' -o -name '*controller*' \
  -o -name '*endpoint*' \) -not -path '*/node_modules/*' 2>/dev/null | head -10
```

### Database
```bash
# Database/ORM files
find . -type f \( -name '*.sql' -o -name '*.prisma' -o -name '*.migration.*' \
  -o -name '*.entity.*' -o -name '*.model.*' -o -name '*.schema.*' \) \
  -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | head -15
```

## Phase 2: Analyze

Based on scan results, determine:

1. **Architecture type**: monolith, microservices, monorepo, library, CLI tool, etc.
2. **Entry points**: main files, API server entry, CLI binary
3. **Conventions**: file naming, directory organization, import style
4. **Tech stack summary**: language(s), framework(s), database(s), infrastructure
5. **Testing status**: has tests? what framework? approximate coverage (file count ratio)
6. **CI/CD status**: has pipelines? what do they run?
7. **Concerns**: no tests, no CI, outdated deps, missing docs, security risks

## Phase 3: Record

Write everything to `.team/knowledge/projects/{project-name}/codebase-profile.md`:

```bash
mkdir -p ".team/knowledge/projects/{project-name}"
```

```markdown
# Codebase Profile: {project-name}

## Overview
- **Type**: {monolith | microservices | library | CLI | etc.}
- **Primary language**: {language}
- **Framework**: {framework}
- **Database**: {database or "none detected"}
- **Size**: {file count} files, {line count estimate} lines

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | {e.g., TypeScript 5.x} |
| Framework | {e.g., Express 4.x} |
| Database | {e.g., PostgreSQL via Prisma} |
| Testing | {e.g., Jest, 45 test files} |
| CI/CD | {e.g., GitHub Actions, 2 workflows} |
| Build | {e.g., npm run build → tsc} |

## Directory Structure
{key directories and their purpose}

## Build & Test Commands
| Command | Purpose | Verified |
|---------|---------|----------|
| `{command}` | Build | {yes/no — actually ran it} |
| `{command}` | Test | {yes/no} |
| `{command}` | Lint | {yes/no} |

## Entry Points
- {main entry point and what it does}

## Conventions Observed
- {naming patterns}
- {file organization patterns}
- {import/export style}

## Concerns
- {any issues found: no tests, no CI, outdated deps, etc.}

## Onboarding Date
{date this profile was created}
```

Also write key learnings to `.team/memory/dev-team.md`:
```markdown
### ONBOARDING — {date}
- **Project**: {name}
- **Stack**: {summary}
- **Build**: `{build command}`
- **Test**: `{test command}`
- **Key concern**: {top concern or "none"}
```

## Phase 4: Brief the User

Present a concise summary:

> 📋 **Codebase onboarding complete.** Here's what I learned:
>
> **{project-name}** — {one-line description from README or inferred}
>
> | | |
> |---|---|
> | **Stack** | {language} + {framework} |
> | **Size** | {N} files |
> | **Tests** | {yes/no, framework, count} |
> | **CI/CD** | {yes/no, what} |
> | **Build** | `{command}` |
>
> **Concerns**: {any issues, or "Looking good — no major concerns."}
>
> Based on this stack, I'd recommend these specialists: ...

**Template Recommendations**: Based on the detected tech stack, recommend which specialist templates to use:

```bash
# Check for frontend → recommend ui-engineer
ui_files=$(find . -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" \) 2>/dev/null | wc -l)
if [ "$ui_files" -gt 0 ]; then
  echo "📋 Recommend: ui-engineer template (detected $ui_files frontend files)"
fi

# Check for API → recommend api-engineer  
api_files=$(find . -type f \( -name "*.openapi.*" -o -name "*.swagger.*" -o -name "*.graphql" -o -name "*.proto" \) 2>/dev/null | wc -l)
api_routes=$(grep -rl "router\.\|app\.\(get\|post\|put\|delete\)" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | wc -l)
if [ "$api_files" -gt 0 ] || [ "$api_routes" -gt 0 ]; then
  echo "📋 Recommend: api-engineer template (detected API definitions/routes)"
fi

# Check for tests → recommend qa-engineer
test_files=$(find . -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" \) 2>/dev/null | wc -l)
echo "📋 Recommend: qa-engineer template (${test_files} test files found — QA can establish/improve test strategy)"

# Check for auth/security → recommend security-analyst
auth_files=$(grep -rl "jwt\|oauth\|bcrypt\|passport\|auth" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | wc -l)
if [ "$auth_files" -gt 0 ]; then
  echo "📋 Recommend: security-analyst template (detected auth-related code in $auth_files files)"
fi
```

Present these recommendations to the user:
> Based on the codebase analysis, I'd recommend these specialists:
> {list of recommended templates}
> 
> Want me to have the Hiring Manager create these agents?

## Phase 5: Recommend Specialists

Based on the detected tech stack, recommend specific specialist agents to activate. Map detected technologies to specialist templates:

| Detection Signal | Recommended Specialist |
|-----------------|----------------------|
| React, Vue, Angular, Svelte, CSS frameworks | `ui-engineer` |
| Vitest, Jest, Cypress, Playwright, pytest | `qa-engineer` |
| Express, FastAPI, Django, REST routes, GraphQL | `api-engineer` |
| Auth libraries, JWT, OAuth, CORS, CSP headers | `security-analyst` |

Output the recommendations:

```markdown
### Recommended Specialists

Based on the detected stack, these specialists should be activated via the Hiring Manager:

{For each detected match:}
- **{specialist}** — {reason, e.g., "React detected in dependencies", "Vitest config found"}

To activate: Ask `@dev-team` to create these specialists, or tell the Hiring Manager directly.
```

Write to the user brief:

> **Recommended specialists**: {e.g., "ui-engineer (React detected), qa-engineer (Vitest detected)"}

Then offer next steps as usual.
