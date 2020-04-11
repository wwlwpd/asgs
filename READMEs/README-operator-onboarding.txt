Operator Onboarding Checklist

1. obtain access to computing platform (e.g., TACC, LSU/LONI, RENCI, etc)

1a. get account
1b. get added to proper allocations
1c. get added to proper unix groups

2. on each platform, generate an SSH private/public key pair (no passphrase)

  ssh-keygen -b 4096 -f $HOME/.ssh/asgs-operator

3. determine which THREDDS resources you need access to and whom to contact, provide 
them your public key ($HOME/.ssh/asgs-operator.pub) to them; current list of
THREDDS servers and admin contact.

3a. LSU/LONI
3b. RENCI 
3c. TACC

4. obtain credentials for ASGS mail server (SMTP)

5. request access to ASGS Slack channel

6. request access to asgs-operator email list

7. checkout ASGS' latest stable branch

8. obtain ADCIRC source code from POC

9. install ASGS using asgs/init-asgs.sh script

10. install ADCIRC via asgsh (initadcirc command)

11. configure and verify email sending using credential provided in Step 4

12. manually add entries fomr asgs/ssh-config.txt (Note: we need to find this and verify it's working)

* ensure all THREDDS resources are listed
* ensure your username on these servers are correct
* ensure IdentifyFile points to $HOME/.ssh/asgs-operator

13. initiate trial run (Note: we need to create steps for this) 

14. verify that emails and data are sent as expected
