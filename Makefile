BASE_HREF = /$(NAME)/
GITHUB_USER = tabhishekpaul
GITHUB_REPO = https://github.com/$(GITHUB_USER)/$(NAME)
BUILD_VERSION := $(if $(NAME),$(shell grep 'version:' ./pubspec.yaml | awk '{print $$2}'))

deploy:
ifndef NAME
	$(error NAME is not set. Usage: make deploy NAME=<name>)
endif

	@echo "Clean existing repository"
	flutter clean

	@echo "Getting packages..."
	flutter pub get

	@echo "Generating the web folder..."
	flutter create . --platform web

	@echo "Building for web..."
	flutter build web --base-href $(BASE_HREF) --release

	@echo "Deploying to GitHub repository"
	cp ./build/web/assets/assets/placeholder.png ./build/web/assets
	cd ./build/web && \
	git init && \
	git add . && \
	git commit -m "Deploy Version $(BUILD_VERSION)" && \
	git branch -M build && \
	git remote add origin $(GITHUB_REPO) && \
	git push -u -f origin build

	@echo "✅ Finished deploy: $(GITHUB_REPO)"
	@echo "🚀 Flutter web URL: https://$(GITHUB_USER).github.io/$(NAME)/"

.PHONY: deploy