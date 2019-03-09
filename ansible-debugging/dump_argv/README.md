# Dump ansible calling arguments

use the following python action_plugin (`action_plugin/dump_argv.py`)::

```
#! /usr/bin/env python

from ansible.plugins.action import ActionBase
import sys

class ActionModule(ActionBase):

    TRANSFERS_FILES = False

    def run(self, tmp=None, task_vars=None):
        return { 'changed': False,
                 'ansible_facts': { 'argv' : sys.argv } }
```

and in `library/dump_argv.py`, an empty file.

Now the following tasks can dump your argv file, as:

```
---
- hosts: all
  tasks:
    - name: store the called arguments
      dump_argv:

    - name: now dump it
      debug:
        var: argv
```
% ansible-playbook  -i localhost, -k main.yaml
SSH password:
 ____________
< PLAY [all] >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

 ________________________
< TASK [Gathering Facts] >
 ------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

ok: [localhost]
 ___________________________________
< TASK [store the called arguments] >
 -----------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

ok: [localhost]
 ____________________
< TASK [now dump it] >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

ok: [localhost] => {
    "argv": [
        "/usr/local/bin/ansible-playbook",
        "-i",
        "localhost,",
        "-k",
        "main.yaml"
    ]
}
 ____________
< PLAY RECAP >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

localhost                  : ok=3    changed=0    unreachable=0    failed=0
```
