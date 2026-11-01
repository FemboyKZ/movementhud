SPCOMP ?= spcomp64
SCRIPTING := addons/sourcemod/scripting
# gokz last: it ships its own movement.inc and json.inc, which must not win.
INCLUDES := $(SCRIPTING)/include movementapi/$(SCRIPTING)/include sm-json/$(SCRIPTING)/include gokz/$(SCRIPTING)/include

$(SCRIPTING)/movementhud.smx: FORCE
	$(SPCOMP) $(SCRIPTING)/movementhud.sp $(addprefix -i,$(INCLUDES)) -o$@

FORCE:
