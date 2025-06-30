#!/bin/bash

# 스크린샷 저장 디렉토리 생성
mkdir -p screenshots

echo "iPhone 6.7\" 및 6.9\" 디스플레이용 스크린샷을 생성합니다..."

# iPhone 6.7" (1290 × 2796px) - 세로 모드
echo "iPhone 6.7\" 세로 모드 스크린샷 생성 중..."
xcrun simctl io booted screenshot screenshots/iphone_67_portrait.png

# iPhone 6.7" (2796 × 1290px) - 가로 모드
echo "iPhone 6.7\" 가로 모드 스크린샷 생성 중..."
xcrun simctl io booted screenshot screenshots/iphone_67_landscape.png

# iPhone 6.9" (1320 × 2868px) - 세로 모드
echo "iPhone 6.9\" 세로 모드 스크린샷 생성 중..."
xcrun simctl io booted screenshot screenshots/iphone_69_portrait.png

# iPhone 6.9" (2868 × 1320px) - 가로 모드
echo "iPhone 6.9\" 가로 모드 스크린샷 생성 중..."
xcrun simctl io booted screenshot screenshots/iphone_69_landscape.png

echo "스크린샷 캡처 완료!"

# ImageMagick이 설치되어 있는지 확인
if command -v convert &> /dev/null; then
    echo "ImageMagick을 사용하여 크기 조정 중..."
    
    # iPhone 6.7" 세로 모드 (1290 × 2796px)
    convert screenshots/iphone_67_portrait.png -resize 1290x2796! screenshots/iphone_67_portrait_1290x2796.png
    
    # iPhone 6.7" 가로 모드 (2796 × 1290px)
    convert screenshots/iphone_67_landscape.png -resize 2796x1290! screenshots/iphone_67_landscape_2796x1290.png
    
    # iPhone 6.9" 세로 모드 (1320 × 2868px)
    convert screenshots/iphone_69_portrait.png -resize 1320x2868! screenshots/iphone_69_portrait_1320x2868.png
    
    # iPhone 6.9" 가로 모드 (2868 × 1320px)
    convert screenshots/iphone_69_landscape.png -resize 2868x1320! screenshots/iphone_69_landscape_2868x1320.png
    
    echo "크기 조정 완료!"
else
    echo "ImageMagick이 설치되어 있지 않습니다. 수동으로 크기를 조정해주세요."
    echo "필요한 크기:"
    echo "- iPhone 6.7\": 1290 × 2796px (세로), 2796 × 1290px (가로)"
    echo "- iPhone 6.9\": 1320 × 2868px (세로), 2868 × 1320px (가로)"
fi

echo "생성된 스크린샷:"
ls -la screenshots/ 