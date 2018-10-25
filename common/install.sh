# xbin detection
if [ ! -d /system/xbin ]; then
  mv -f $INSTALLER/system/xbin $INSTALLER/system/bin
  bin=bin
else
  bin=xbin
fi

# GET BETA/STABLE FROM ZIP NAME
case $(basename $ZIP) in
  *beta*|*Beta*|*BETA*) BETA=true;;
  *stable*|*Stable*|*STABLE*) BETA=false;;
esac

# Change this path to wherever the keycheck binary is located in your installer
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}   

choose() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}
ui_print " "
if [ -z $BETA ]; then
  if keytest; then
    FUNCTION=choose
  else
    FUNCTION=chooseold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Option -"
  ui_print "   Install into beta stream: "
  ui_print "   Vol Up = Beta,  Vol Down = Stable"
  if $FUNCTION; then 
    BETA=true
  else 
    BETA=false
  fi
else
  ui_print "   Option specified in zipname!"
fi

mkdir -p $INSTALLER/system/etc/permissions $INSTALLER/system/priv-app/Avroid
cp -f $INSTALLER/custom/perm/privapp-permissions-avroid.bangla.keyboard.xml $INSTALLER/system/etc/permissions/privapp-permissions-avroid.bangla.keyboard.xml
if $BETA; then
  ui_print "   Avroid Beta will be installed"
  cp -f $INSTALLER/custom/beta/Avroid.apk $INSTALLER/system/priv-app/Avroid/Avroid.apk
else
  ui_print "   Avroid Stable will be installed"
  cp -f $INSTALLER/custom/stable/Avroid.apk $INSTALLER/system/priv-app/Avroid/Avroid.apk
fi
