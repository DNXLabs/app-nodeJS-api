export GOOGLE_IDP_ID=C01501d06 #DNX IDP
export GOOGLE_SP_ID=192607830114 #DNX ID

ASSUME_REQUIRED?=.env.assume

ifdef CI
	ECR_REQUIRED?=
else
	ECR_REQUIRED?=ecrLogin
endif

ECR_ACCOUNT?=335071203852
export AWS_DEFAULT_REGION?=ap-southeast-2
export CONTAINER_PORT?=3000
export APP_NAME=nodejs-api# << CHANGEME
BUILD_VERSION?=latest
export IMAGE_NAME=$(ECR_ACCOUNT).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com/$(APP_NAME):$(BUILD_VERSION)

# Check for specific environment variables
env-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

.env:
	@echo "make .env"
	cp .env.template .env
	echo >> .env
	echo >> .env
	touch .env.auth
	touch .env.assume

.env.auth: .env env-GOOGLE_IDP_ID env-GOOGLE_SP_ID
	@echo "make .env.auth"
	echo > .env.auth
	docker-compose run --rm google-auth

.env.assume: .env env-AWS_ACCOUNT_ID env-AWS_ROLE
	@echo "make .env.assume"
	echo > .env.assume
	docker-compose pull aws
	docker-compose run --rm aws assume-role.sh > .env.assume
.PHONY: assumeRole

ecrLogin: .env
	@echo "make ecrLogin"
	$(shell docker-compose run --rm aws "aws ecr get-login --no-include-email --registry-ids $(ECR_ACCOUNT) --region $(AWS_DEFAULT_REGION)")

dockerBuild: .env
	@echo "make dockerBuild"
	docker build --no-cache -t $(IMAGE_NAME) .
.PHONY: dockerBuild

dockerPush: $(ECR_REQUIRED)
	echo "make dockerPush"
	docker push $(IMAGE_NAME)
.PHONY: dockerPush

deploy: $(ASSUME_REQUIRED)
	@echo "make deploy"
	docker-compose run --rm aws ./deploy.sh
.PHONY: deploy

install: .env
	docker-compose run --rm builder npm install

build: .env
	docker-compose run --rm builder npm run build
.PHONY: build

run: .env
	docker run --env-file .env -p 3001:3001 $(IMAGE_NAME)

test: .env
	docker-compose run --rm builder npm test
.PHONY: test

shell:
	docker run --env-file .env -it -p 3000:3000 -v ${PWD}:/app:Z --entrypoint "sh" $(IMAGE_NAME)

shell-aws: $(ASSUME_REQUIRED)
	docker run --env-file .env --env-file .env.auth --env-file .env.assume -it -p 3000:3000 -v ${PWD}:/app:Z --entrypoint "sh" dnxsolutions/aws:1.4.1

style-check: .env
	docker-compose run --rm builder npm run lint -- --fix-dry-run
.PHONY: style-check

slack-approval-request: env-SLACK_HOOKS_URL
	@echo "slack integration"
	curl -X POST -s -H 'Content-type: application/json' --data '{"text":"The pipeline requires manual approval","attachments": [{"text": "<$(CI_PIPELINE_URL)|$(DOCKER_ENV_CI_PROJECT_NAME) pipeline> - Stopped wating manual approval" ,"author_name":"GitLabCI","author_icon":"https://avatars.slack-edge.com/2019-06-03/646968693809_8e092b123559fc460e5a_192.png","color": "warning" , "fields": [{"title": "Project","value": "$(DOCKER_ENV_CI_PROJECT_NAME)","short": false},{"title": "Git Commit","value": "$(CI_COMMIT_SHORT_SHA) - $(CI_COMMIT_TITLE) - Author: $(GITLAB_USER_EMAIL)","short": false},{"title": "Target Environemt","value": "$(AWS_ENV)","short": false}],"attachment_type": "default"}]}' $(SLACK_HOOKS_URL)
.PHONY: slack-integration

slack-approval-response: env-SLACK_HOOKS_URL
	@echo "slack integration"
	curl -X POST -s -H 'Content-type: application/json' --data '{"text":"The pipeline was approved","attachments": [{"text": "<$(CI_PIPELINE_URL)|$(DOCKER_ENV_CI_PROJECT_NAME) pipeline> - Approved :done:" ,"author_name":"GitLabCI","author_icon":"https://avatars.slack-edge.com/2019-06-03/646968693809_8e092b123559fc460e5a_192.png","color": "warning" , "fields": [{"title": "Project","value": "$(DOCKER_ENV_CI_PROJECT_NAME)","short": false},{"title": "Git Commit","value": "$(CI_COMMIT_SHORT_SHA) - $(CI_COMMIT_TITLE) - Approval by: $(GITLAB_USER_EMAIL)","short": false},{"title": "Target Environemt","value": "$(AWS_ENV)","short": false}],"attachment_type": "default"}]}' $(SLACK_HOOKS_URL)
.PHONY: slack-integration
