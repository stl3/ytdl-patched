all: youtube-dl README.md CONTRIBUTING.md README.txt youtube-dl.1 youtube-dl.bash-completion _youtube-dl youtube-dl.fish supportedsites

clean:
	rm -rf youtube-dl.1.temp.md youtube-dl.1 youtube-dl.bash-completion README.txt MANIFEST build/ dist/ .coverage cover/ youtube-dl.tar.gz _youtube-dl youtube-dl.fish yt_dlp/extractor/lazy_extractors.py *.dump *.part* *.ytdl *.info.json *.mp4 *.m4a *.flv *.mp3 *.avi *.mkv *.webm *.3gp *.wav *.ape *.swf *.jpg *.png CONTRIBUTING.md.tmp youtube-dl youtube-dl.exe
	find . -name "*.pyc" -delete
	find . -name "*.class" -delete
	find . -name "*~~" -exec rm -rf {} +

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/man
SHAREDIR ?= $(PREFIX)/share
PYTHON ?= /usr/bin/env python3

# set SYSCONFDIR to /etc if PREFIX=/usr or PREFIX=/usr/local
SYSCONFDIR = $(shell if [ $(PREFIX) = /usr -o $(PREFIX) = /usr/local ]; then echo /etc; else echo $(PREFIX)/etc; fi)

# set markdown input format to "markdown-smart" for pandoc version 2 and to "markdown" for pandoc prior to version 2
MARKDOWN = $(shell if [ "$(pandoc -v | head -n1 | cut -d" " -f2 | head -c1)" = "2" ]; then echo markdown-smart; else echo markdown; fi)

install: youtube-dl youtube-dl.1 youtube-dl.bash-completion _youtube-dl youtube-dl.fish
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 youtube-dl $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(MANDIR)/man1
	install -m 644 youtube-dl.1 $(DESTDIR)$(MANDIR)/man1
	install -d $(DESTDIR)$(SYSCONFDIR)/bash_completion.d
	install -m 644 youtube-dl.bash-completion $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/youtube-dl
	install -d $(DESTDIR)$(SHAREDIR)/zsh/site-functions
	install -m 644 _youtube-dl $(DESTDIR)$(SHAREDIR)/zsh/site-functions/_youtube-dl
	install -d $(DESTDIR)$(SYSCONFDIR)/fish/completions
	install -m 644 youtube-dl.fish $(DESTDIR)$(SYSCONFDIR)/fish/completions/youtube-dl.fish

codetest:
	flake8 .

test:
	#nosetests --with-coverage --cover-package=yt_dlp --cover-html --verbose --processes 4 test
	nosetests --verbose test
	$(MAKE) codetest

ot: offlinetest

# Keep this list in sync with devscripts/run_tests.sh
offlinetest: codetest
	$(PYTHON) -m nose --verbose test \
		--exclude test_age_restriction.py \
		--exclude test_download.py \
		--exclude test_iqiyi_sdk_interpreter.py \
		--exclude test_socks.py \
		--exclude test_subtitles.py \
		--exclude test_write_annotations.py \
		--exclude test_youtube_lists.py \
		--exclude test_youtube_signature.py \
		--exclude test_websocket.py

tar: youtube-dl.tar.gz

.PHONY: all clean install test tar bash-completion pypi-files zsh-completion fish-completion ot offlinetest codetest supportedsites

pypi-files: youtube-dl.bash-completion README.txt youtube-dl.1 youtube-dl.fish _youtube-dl

# youtube-dl: yt_dlp/*.py yt_dlp/*/*.py
# 	mkdir -p zip
# 	for d in yt_dlp yt_dlp/downloader yt_dlp/extractor yt_dlp/extractor/*/ yt_dlp/postprocessor yt_dlp/websocket ; do \
# 	  mkdir -p zip/$$d ;\
# 	  cp -pPR $$d/*.py zip/$$d/ ;\
# 	done
# 	touch -t 200001010101 zip/yt_dlp/*.py zip/yt_dlp/*/*.py
# 	mv zip/yt_dlp/__main__.py zip/
# 	cd zip ; 7z a -mm=Deflate -mfb=258 -mpass=15 -mtc- ../youtube-dl.zip yt_dlp/*.py yt_dlp/*/*.py yt_dlp/*/*/*.py __main__.py
# 	rm -rf zip
# 	echo '#!$(PYTHON)' > youtube-dl
# 	cat youtube-dl.zip >> youtube-dl
# 	rm youtube-dl.zip
# 	chmod a+x youtube-dl

youtube-dl: yt_dlp/*.py yt_dlp/*/*.py yt_dlp/*/*/*.py devscripts/make_zipfile.py
	$(PYTHON) devscripts/make_zipfile.py "$(PYTHON)"

README.md: yt_dlp/*.py yt_dlp/*/*.py
	COLUMNS=80 $(PYTHON) yt_dlp/__main__.py --help | $(PYTHON) devscripts/make_readme.py

CONTRIBUTING.md: README.md
	$(PYTHON) devscripts/make_contributing.py README.md CONTRIBUTING.md

issuetemplates: devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/1_broken_site.md .github/ISSUE_TEMPLATE_tmpl/2_site_support_request.md .github/ISSUE_TEMPLATE_tmpl/3_site_feature_request.md .github/ISSUE_TEMPLATE_tmpl/4_bug_report.md .github/ISSUE_TEMPLATE_tmpl/5_feature_request.md yt_dlp/version.py
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/1_broken_site.md .github/ISSUE_TEMPLATE/1_broken_site.md
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/2_site_support_request.md .github/ISSUE_TEMPLATE/2_site_support_request.md
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/3_site_feature_request.md .github/ISSUE_TEMPLATE/3_site_feature_request.md
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/4_bug_report.md .github/ISSUE_TEMPLATE/4_bug_report.md
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/5_feature_request.md .github/ISSUE_TEMPLATE/5_feature_request.md

supportedsites:
	$(PYTHON) devscripts/make_supportedsites.py docs/supportedsites.md

README.txt: README.md
	pandoc -f $(MARKDOWN) -t plain README.md -o README.txt

youtube-dl.1: README.md
	$(PYTHON) devscripts/prepare_manpage.py youtube-dl.1.temp.md
	pandoc -s -f $(MARKDOWN) -t man youtube-dl.1.temp.md -o youtube-dl.1
	rm -f youtube-dl.1.temp.md

youtube-dl.bash-completion: yt_dlp/*.py yt_dlp/*/*.py devscripts/bash-completion.in
	$(PYTHON) devscripts/bash-completion.py

bash-completion: youtube-dl.bash-completion

_youtube-dl: yt_dlp/*.py yt_dlp/*/*.py devscripts/zsh-completion.in
	$(PYTHON) devscripts/zsh-completion.py

zsh-completion: _youtube-dl

youtube-dl.fish: yt_dlp/*.py yt_dlp/*/*.py devscripts/fish-completion.in
	$(PYTHON) devscripts/fish-completion.py

fish-completion: youtube-dl.fish

lazy-extractors: yt_dlp/extractor/lazy_extractors.py

_EXTRACTOR_FILES = $(shell find yt_dlp/extractor -iname '*.py' -and -not -iname 'lazy_extractors.py')
yt_dlp/extractor/lazy_extractors.py: devscripts/make_lazy_extractors.py devscripts/lazy_load_template.py $(_EXTRACTOR_FILES)
	$(PYTHON) devscripts/make_lazy_extractors.py $@

youtube-dl.tar.gz: youtube-dl README.md README.txt youtube-dl.1 youtube-dl.bash-completion _youtube-dl youtube-dl.fish ChangeLog AUTHORS
	@tar -czf youtube-dl.tar.gz --transform "s|^|youtube-dl/|" --owner 0 --group 0 \
		--exclude '*.DS_Store' \
		--exclude '*.kate-swp' \
		--exclude '*.pyc' \
		--exclude '*.pyo' \
		--exclude '*~' \
		--exclude '__pycache__' \
		--exclude '.git' \
		--exclude 'docs/_build' \
		-- \
		bin devscripts test yt_dlp docs \
		ChangeLog AUTHORS LICENSE README.md README.txt \
		Makefile MANIFEST.in youtube-dl.1 youtube-dl.bash-completion \
		_youtube-dl youtube-dl.fish setup.py setup.cfg \
		youtube-dl
	advdef -z -4 -i 30 youtube-dl.tar.gz
