MDMDIR=/usr/share/mdm/guest-session/
APPARMORDIR=/etc/apparmor.d/
XSESSIONDIR=/usr/share/xsessions

check:
	for f in mdm/*; do sh -n $$f; done
	
install:
	install -d $(DESTDIR)$(MDMDIR) $(DESTDIR)$(APPARMORDIR) $(DESTDIR)$(XSESSIONDIR)
	install -m 755 mdm/* $(DESTDIR)$(MDMDIR)
	install -m 644 apparmor/* $(DESTDIR)$(APPARMORDIR)
	install -m 644 guest-restricted.desktop $(DESTDIR)$(XSESSIONDIR)
	ln -s guest-restricted.desktop $(DESTDIR)$(XSESSIONDIR)/une-guest-restricted.desktop
	ln -s guest-restricted.desktop $(DESTDIR)$(XSESSIONDIR)/une-efl-guest-restricted.desktop

uninstall:
	for f in $(shell ls mdm); do rm -f $(DESTDIR)$(MDMDIR)$$f; done
	rmdir -p $(DESTDIR)$(MDMDIR) 2>/dev/null || true
	for f in $(shell ls apparmor); do rm -f $(DESTDIR)$(APPARMORDIR)$$f; done
	rmdir -p $(DESTDIR)$(APPARMORDIR) 2>/dev/null || true

clean:

.PHONY: install uninstall check clean
