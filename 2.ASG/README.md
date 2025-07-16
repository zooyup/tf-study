# ASG 및 ALB 생성

## 개요
이 프로젝트는 Terraform을 사용하여 모듈 없이 Launch Template를 통한 Auto Scaling Group과 Application LoadBalancer를 구성하는 예제입니다.


## 구성 요소

### 1. LauchTemplate
- **AMI**: Amazon Linux 2023 (최신 버전)
- **인스턴스 타입**: t3.micro
- **키 페어**: "해당 부분 변경할 것"
- **보안 그룹**: HTTP(80), SSH(22) 포트 허용


### 2. 웹서버 구성 (User Data)
- Apache HTTP Server 설치
- 메타데이터를 가져와서 인스턴스 id 출력
- 기본 웹페이지 생성 ("Hello, World instance-id")
- 서비스 자동 시작 및 활성화

### 3. 보안 그룹
- **인바운드 규칙**:
  - HTTP (80): 웹 접근용
  - SSH (22): 원격 접속용
- **아웃바운드 규칙**: 모든 트래픽 허용

### 4. ALB
- **리스너**: 80번 포트
- **대상 그룹**: 80번 포트

## 파일 구조
```
1.EC2/
├── main.tf          # 메인 Terraform 설정 파일
├── provider.tf       # 프로 바이더 정의 (선택사항)
├── variables.tf       # 기본 변수 (선택사항)
├── data.tf       # 기본 받아오는 data (선택사항)
└── README.md        # 이 파일
```

## 사용 방법

### 1. 초기화
```bash
terraform init
```

### 2. 계획 확인
```bash
terraform plan
```

### 3. 인프라 생성
```bash
terraform apply --auto-approve
```

### 4. 인프라 삭제
```bash
terraform destroy --auto-approve
```

## 주요 특징
- **모듈 없이 직접 리소스 정의**: 간단하고 직관적인 구성
- **User Data 활용**: 인스턴스 시작 시 자동으로 웹서버 구성
- **보안 그룹 설정**: 필요한 포트만 허용하는 보안 구성
- **태그 관리**: 리소스 식별을 위한 태그 설정

## 접속 방법
1. **웹 접속**: `http://[ALB_DNS]`

## 주의사항
- 키 페어 부분을 본인 거로 변경이 필요합니다
- 보안 그룹에서 SSH 접속을 위한 IP 제한을 고려하세요
- 프로덕션 환경에서는 더 강화된 보안 설정이 필요합니다