# Debugging Ansible

-   Ansible keep environment variable
    ```
    export ANSIBLE_KEEP_REMOTE_FILES=1
    ```
    This variable tells anisble to preserve all the script it runs on the host it runs on.  We can get into the remote host that the failure occurred on, track the specific script that failed.
    
    We can "explode" that script, examine and modify it in place, "execute" the modified script, and diagnose, possibly fix.
    
-   Dumping Ansible command line arguments:
    Look at dump_argv.
    
- The above script also shows how to use the ansible debug plugin, more details of which are here:  https://docs.ansible.com/ansible/latest/modules/debug_module.html

- Finally, this
  https://stackoverflow.com/questions/42417079/how-to-debug-ansible-issues
  is a good resource for ansible debug tips.
