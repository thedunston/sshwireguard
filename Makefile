.PHONY: copy-ubuntu
copy-ubuntu: ## Copy the sshwireguard binary to the test on Ubuntu Linux.
	@lxc file push test/sshwireguard-ubuntu-amd64-test ubuntuSSHGW/home/duane/

.PHONY: ubuntu-cont
ubuntu-cont: ## Drop into an ubuntu container to test the binary.
	@lxc exec ubuntuSSHWG -- su --login duane

# Linux binaries 64-bit
LINUX := env GOOS=linux GOARCH=amd64 go build -o test/sshwireguard

.PHONY: test
test: ## Build and create test binaries.
	env GOOS=windows GOARCH=amd64 go build -o test/sshwireguard-amd64-test.exe
	$(LINUX)-ubuntu-amd64-test
	$(LINUX)-arch-amd64-test
	

.PHONY: compile
compile: ## Create the final binaries for the given version.
	echo "Compiling for every OS and Platform"
	env GOOS=windows GOARCH=amd64 go build -o bin/sshwireguard-amd64.exe
	env GOOS=linux GOARCH=amd64 go build -o bin/sshwireguard-linux-amd64

.PHONY: clean
clean: ## Remove test binaries.
	go clean
	rm -f test/sshwireguard-amd64-test.exe
	rm -f test/sshwireguard-linux-amd64-test

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## This output.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := test
