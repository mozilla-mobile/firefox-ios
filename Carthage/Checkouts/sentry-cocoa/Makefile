lint:
	@echo "--> Running swiftlint"
	swiftlint

test:
	@echo "--> Running all tests"
	fastlane test

build-carthage:
	@echo "--> Creating Sentry framework package with carthage"
	carthage build --no-skip-current --cache-builds
	carthage archive Sentry --output Sentry.framework.zip

release: bump-version git-commit-add

pod-lint:
	@echo "--> Build local pod"
	pod lib lint --allow-warnings --verbose

git-commit-add:
	@echo "\n\n\n--> Commting git ${TO}"
	git commit -am "release: ${TO}"
	git tag ${TO}
	git push
	git push --tags

release-pod:
	pod trunk push Sentry.podspec
