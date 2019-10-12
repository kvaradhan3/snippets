#! /usr/bin/env python3
#
# parse the system_profiler -xml output and put it into
# a python data structure that can be manipulated and
# analyzed.
#
# A sample analysis to show installed applications is
# in this example.
#

import sys
import subprocess
import pprint as pprint

from lxml import etree

def system_profile():
    import subprocess
    result = subprocess.run(['/usr/sbin/system_profiler', '-xml'],
                            stdout=subprocess.PIPE)
    return result.stdout

def _parse(elem):
    """Parse one object in system_profiler output, and return it."""
    if elem.tag == 'array':
        ret = []
        for e in elem.getchildren():
            ret.append(_parse(e))
        return ret
    elif elem.tag == 'dict':
        ret = {}
        e = elem.getchildren()[0]
        while e is not None:
            ret[e.text] = _parse(e.getnext())
            e = e.getnext().getnext()
        return ret
    else:
        return elem.text

def parse(xmlbuffer):
    """Parse the xml formatted output of sytem_profiler,
       return a python data structure."""
    root = etree.fromstring(xmlbuffer)
    if root.tag != 'plist' or root.get('version') != '1.0':
        raise SystemExit('error: unknown plist version')

    if len(root.getchildren()) > 1:
        raise SystemExit('error: malformed plist?  or FIXME here')

    return root.tag, _parse(root.getchildren()[0])

def splitAndWriteChunks(xmlbuffer):
    """Generate a file for each datatype output by system_profiler."""
    root = etree.fromstring(xmlbuffer)
    if root.tag != 'plist' or root.get('version') != '1.0':
        raise SystemExit('error: unknown plist version')

    if len(root.getchildren()) > 1:
        raise SystemExit('error: malformed plist?  or FIXME here')

    # skip plist
    root = root.getchildren()[0]
    for i in root.getchildren():
        #
        #      	<key>_versionInfo</key>
	#	<dict>
	#		<key>com.apple.SystemProfiler.SPParallelATAReporter</key>
	#		<string>2.7</string>
	#	</dict>
        #
        versionInfo = i.xpath('.//key[text()="_versionInfo"]')[0]
        versionName = versionInfo.getnext().getchildren()[0].text
        print(f'>>>>  {versionName}')
        with open(f'/tmp/{versionName}', 'w') as f:
            print(etree.tostring(i).decode('utf-8'), file=f)
    return

def indexByDatatype(spg):
    """Create a dictionary, indexed by Datatype."""
    plist = {}
    for item in spg:
        if '_SPCommandLineArguments' in item:
            plist[item['_SPCommandLineArguments'][3]] = item
        else:
            err1 = f'_SPCommandLineArguments not found for'
            err2 = f'{"".join(item["_versionInfo"].keys())}'
            sys.stderr.write(f"{err1} {err2}\n")
    return plist

def indexByVersionInfo(spg):
    """Create a Dictionary, indexed by _versionInfo key."""
    plist = {}
    for item in spg:
        if '_versionInfo' in item:
            plist[''.join(item['_versionInfo'].keys())] = item
    return plist

def _formatApplicationsReport(name, version, has64bIntelCode,
                              path, lastModified):
    s = '{:<20} {:<10}'.format(name, version)
    if has64bIntelCode == 'yes':
        s += ' Y '
    elif has64bIntelCode == 'no':
        s += ' N '
    else:
        s += has64bIntelCode
    s += '  {:<50} {:^20}'.format(path, lastModified)
    return s

def printApplicationsReport(sp):
    """Print the 64b status of every application on the device."""
    print(_formatApplicationsReport('Name', 'Version', '64b',
                                    'Path', 'Last Modified'))
    for i in sp['_items']:
        print(_formatApplicationsReport(i['_name'],
                                        i.get('version',
                                              i.get('info', '')),
                                        i['has64BitIntelCode'],
                                        i['path'], i['lastModified']))
    return


# A mishmash of functions.
# source the data into a string.
if len(sys.argv) > 1:
    with open(sys.argv[1], 'r') as f:    # system_profiler -xml > foo
        sysprofile = f.read().encode('utf-8')
else:
    sysprofile = system_profile()

# Write out a file per datatype object.
splitAndWriteChunks(sysprofile)

# convert to python data structures
tag, sp = parse(sysprofile)

# Not all objects are identified as searchable by datatype.
# This may fail on some objects.
plist = indexByDatatype(sp)

# this is a more reliable index.
plist = indexByVersionInfo(sp)

# Dump the 64b status of all applications, please.
applicationsTag = 'com.apple.SystemProfiler.SPApplicationsReporter'
printApplicationsReport(plist[applicationsTag])

