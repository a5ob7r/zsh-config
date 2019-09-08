CONFIGS := .zshenv .zshrc .zprofile

link:
	@$(foreach config, $(CONFIGS), ln -sfv $(CURDIR)/$(config) $(HOME)/$(config);)

unlink:
	@$(foreach config, $(CONFIGS), unlink $(HOME)/$(config);)
