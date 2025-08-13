ROOTDIR=$(realpath $(dir $(firstword $(MAKEFILE_LIST))))
PACKAGES_FILE=${ROOTDIR}/ubuntu_packages.txt
NOUVEAU_BLACKLIST_FILE=/etc/modprobe.d/blacklist-nouveau.conf

ASDF_DIR= $(HOME)/.asdf
PYTHON=python
PIP=pip
ASDF_BIN := $(ASDF_DIR)/bin/asdf
.PHONY: all clean

all: install


install: install_packages
	@echo "Installing packages from ${PACKAGES_FILE}"

git_cfg:
	git config --global core.editor "vim"
	git config --global credential.helper store

install_packages:
	sudo apt update
	sudo apt upgrade -y
	sudo xargs -a ${PACKAGES_FILE} apt install -y

nvidia_driver: blacklist_nouveau
	sudo apt update
	sudo apt upgrade -y
	sudo apt install nvidia-driver nvidia-cuda-toolkit -y

zerotier:
	curl -s https://install.zerotier.com | sudo bash

blacklist_nouveau: $(NOUVEAU_BLACKLIST_FILE)
	echo "Blacklisted!"

$(NOUVEAU_BLACKLIST_FILE):
	echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
	echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
	sudo update-initramfs -u

$(ASDF_DIR): install_packages git_cfg
	@if [ ! -d "$(ASDF_DIR)" ]; then \
		echo "Cloning asdf..."; \
		git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.14.1;\
		echo '. "$$HOME/.asdf/asdf.sh"' >>${HOME}/.bashrc;\
		echo '. "$$HOME/.asdf/completions/asdf.bash"' >>${HOME}/.bashrc; \
	else \
			echo "asdf already installed at $(ASDF_DIR)"; \
	fi

asdf_plugins: $(ASDF_DIR)
	bash -c '. $(ASDF_DIR)/asdf.sh && $(ASDF_BIN) plugin add python || true'
	bash -c '. $(ASDF_DIR)/asdf.sh && $(ASDF_BIN) plugin add java || true'

asdf_install_python: asdf_plugins
	bash -c '. $(ASDF_DIR)/asdf.sh && $(ASDF_BIN)  install python 3.11.9 || true'
	bash -c '. $(ASDF_DIR)/asdf.sh && $(ASDF_BIN)  install python 3.9.18 || true'
	bash -c '. $(ASDF_DIR)/asdf.sh && $(ASDF_BIN)  global python 3.11.9 || true'

	
