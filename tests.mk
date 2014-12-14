shellcheck:
ifeq ($(shell shellcheck > /dev/null 2>&1 ; echo $$?),127)
ifeq ($(shell uname),Darwin)
		brew install shellcheck
else
		sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse'
		sudo apt-get update && sudo apt-get install -y shellcheck
endif
endif

ci-dependencies: shellcheck bats

setup-deploy-tests:
	# echo "-----> Enabling tracing"
	# mkdir -p /home/dokku
	# echo "export DOKKU_TRACE=1" >> /home/dokku/dokkurc
	@echo "Setting dokku.me in /etc/hosts"
	/bin/bash -c "[[ `ping -c1 dokku.me > /dev/null 2>&1; echo $$?` -eq 0 ]] || echo \"127.0.0.1  dokku.me *.dokku.me\" >> /etc/hosts"

	@echo "-----> Generating keypair..."
	mkdir -p ~/.ssh
	rm -f ~/.ssh/dokku_test_rsa*
	echo -e  "y\n" | ssh-keygen -f ~/.ssh/dokku_test_rsa -t rsa -N ''
	chmod 600 ~/.ssh/dokku_test_rsa*

	@echo "-----> Setting up ssh config..."
ifeq ($(shell grep dokku.me ~/.ssh/config),)
	echo "Host dokku.me \\r\\n RequestTTY yes \\r\\n IdentityFile ~/.ssh/dokku_test_rsa" >> ~/.ssh/config
endif

	@echo "-----> Installing SSH public key..."
	sshcommand acl-remove dokku test
	cat ~/.ssh/dokku_test_rsa.pub | sshcommand acl-add dokku test

	ls -la ~/.ssh/
	cat ~/.ssh/dokku_test_rsa.pub
	cat ~dokku/.ssh/authorized_keys
	cat ~/.ssh/config
	cat /root/.ssh/config
	@echo "-----> Intitial SSH connection to populate known_hosts..."
	ssh -vvv -o StrictHostKeyChecking=no dokku@dokku.me help > /dev/null

bats:
	git clone https://github.com/sstephenson/bats.git /tmp/bats
	cd /tmp/bats && sudo ./install.sh /usr/local
	rm -rf /tmp/bats

lint:
	@echo linting...
	@$(QUIET) find . -not -path '*/\.*' | xargs file | grep shell | awk '{ print $$1 }' | sed 's/://g' | xargs shellcheck

unit-tests:
	@echo running unit tests...
	@$(QUIET) bats tests/unit

deploy-tests:
	@echo running deploy tests...
	@$(QUIET) bats tests/deploy

test: lint unit-tests setup-deploy-tests deploy-tests
