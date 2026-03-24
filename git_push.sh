#!/bin/bash

# 1. 현재 상태 출력 (어떤 파일이 바뀌었나?)
echo "======================================="
echo " 변경된 파일 목록을 확인합니다."
git status -s
echo "======================================="

# 2. 커밋 메시지 입력 (입력 안 하면 자동으로 생성)
echo -n "💬 커밋 메시지를 입력하세요 (기본값: 'fix: update infrastructure'): "
read msg

if [ -z "$msg" ]; then
    msg="fix: update infrastructure and github actions $(date +'%Y-%m-%d %H:%M')"
fi

# 3. 깃 명령어 실행
echo " 깃허브로 코드를 전송합니다."

# 모든 파일 추가 (숨김 폴더 .github 포함)
git add .

# 커밋 실행
git commit -m "$msg"

# 현재 브랜치 이름 자동 추출 (main 또는 master)
branch_name=$(git branch --show-current)

# 푸시 실행
git push origin "$branch_name"

echo "======================================="
echo " 업로드 완료 GitHub Actions 탭을 확인하세요."
echo "======================================="
