DEVICE_ID = 00008020-001224981411002E
TEAM_ID = 49NSXZJZ54
SCHEME = NovelReaderApp
PROJECT = NovelReaderApp.xcodeproj
DERIVED_DATA = $(HOME)/Library/Developer/Xcode/DerivedData/NovelReaderApp-dgpxpeizblwacqfuezvplbaupayy

.PHONY: install clean build test trollstore ipa

install: build
	ideviceinstaller install $(DERIVED_DATA)/Build/Products/Release-iphoneos/NovelReaderApp.app

build:
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-configuration Release \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		CODE_SIGN_STYLE=Automatic \
		build

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf build/

# 在macOS上运行单元测试（仅测试业务逻辑）
test:
	@echo "运行 JoyRead 业务逻辑测试（macOS环境）..."
	@swift test

# 构建 IPA 用于 TrollStore 安装（无需数据线）
trollstore:
	@./scripts/trollstore_install.sh

# 仅构建 IPA 文件（不启动服务器）
ipa:
	@./scripts/build_ipa.sh
