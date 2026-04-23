---
trigger: manual
description: 프로젝트 구조를 스캔하여 architecture.md를 프로젝트 유형에 맞게 생성/갱신
---

# /update-architecture

사용법: `/update-architecture`

프로젝트를 스캔해 `.claude/docs/architecture.md`를 생성하거나 갱신한다.
**프로젝트 유형에 따라 적절한 섹션을 동적으로 구성**한다. (백엔드/프론트엔드/모바일/ML/CLI 등 무관)

## 실행 절차 (Claude가 수행)

### Step 1. 프로젝트 유형 감지

| 단서 | 추정 유형 |
|---|---|
| `package.json` + `next.config.*` | Next.js 프론트엔드 |
| `package.json` + `react-native` | React Native 모바일 |
| `package.json` + `@nestjs/*` / `fastify` / `express` | Node.js 백엔드 |
| `pubspec.yaml` | Flutter 모바일 |
| `requirements.txt` + `torch` / `tensorflow` | Python ML |
| `requirements.txt` + `fastapi` / `django` / `flask` | Python 백엔드 |
| `go.mod` + `cobra` / `urfave/cli` | Go CLI |
| `go.mod` + `gin` / `echo` / `fiber` | Go 백엔드 |
| `Cargo.toml` | Rust |
| `.github/workflows/`만 있고 앱 코드 없음 | DevOps/Infra |

여러 유형 혼재 (모노레포 등)면 각각의 섹션을 모두 포함.

### Step 2. 유형별 섹션 구성 (백엔드 가정하지 않기)

**백엔드:**
- 기술 스택 (Runtime, Framework, DB)
- API 라우팅 / 엔드포인트
- 서비스/도메인 모듈
- DB 스키마
- 외부 API 의존성
- 데이터 흐름

**프론트엔드:**
- 기술 스택 (Framework, Bundler, State)
- 라우팅 구조
- 상태 관리 전략
- 컴포넌트/디자인 시스템
- API 통신 계층
- 빌드/배포 타겟

**모바일:**
- 기술 스택 + 타겟 플랫폼 (iOS/Android)
- 화면 구조 / 네비게이션
- 네이티브 모듈 의존성
- 권한 / 설정
- 빌드 타겟

**ML/데이터:**
- 기술 스택 (Framework, Tracking)
- 데이터 파이프라인
- 모델 아키텍처
- 실험 관리
- 학습/추론 인프라

**CLI/도구:**
- 기술 스택
- 커맨드 구조
- 설정 파일 형식
- 빌드 타겟

**DevOps/Infra:**
- IaC 도구 (Terraform/CDK/Pulumi)
- 인프라 토폴로지
- CI/CD 파이프라인
- 시크릿 관리

### Step 3. 실제 코드 기반으로 내용 채움

섹션만 만들지 말고 **실제 파일 스캔 결과**로 채운다:

```bash
# 의존성
cat package.json go.mod requirements.txt Cargo.toml pubspec.yaml 2>/dev/null

# 디렉토리 구조
find . -maxdepth 2 -type d -not -path "*/\.*" -not -path "*/node_modules*"

# 주요 설정
ls *.config.* .env.example tsconfig.json 2>/dev/null

# 스키마 파일
find . -name "schema.prisma" -o -name "*.sql" -o -name "*.proto" | head -5

# 라우트/엔드포인트 (있으면)
grep -rE "(router|route|@Get|@Post|app\.)" src/ 2>/dev/null | head -10
```

### Step 4. 기존 내용과 비교

architecture.md에 이미 내용이 있으면:
1. 기존 섹션과 새로 감지한 내용 diff
2. 사용자에게 변경사항 요약
3. 확정 후 갱신

처음이면 바로 작성.

### Step 5. PROGRESS.md에 로그

```markdown
## 완료
- [YYYY-MM-DD] architecture.md [생성/갱신]: [유형] 프로젝트 구조 반영
```

### Step 6. 보고

```
architecture.md [생성/갱신] 완료

감지된 프로젝트 유형: [유형]
주요 변경:
- 추가: ...
- 갱신: ...
```

## 주의사항

- **추측 금지** — 파일에서 확인되지 않는 것은 "확인 필요" 표시
- **프로젝트 유형에 안 맞는 섹션 넣지 않기** — 예: 프론트에 "DB 스키마" 섹션 X
- **최소주의** — 의미 없는 섹션 생략
- **다이어그램은 텍스트로** — ASCII 또는 mermaid
