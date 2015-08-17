Sensu-Plugins-Bitbucket
=============================

Functionality
-------------------------

Queries the [Bitbucket Api v2](https://confluence.atlassian.com/display/BITBUCKET/Version+2) for various metrics.  
Currently will check a user/group for private repositories.  
Additionally, if an api key is provided, will check private repositories to
verify that public forks aren't allowed.  

Files
---------------------
* bin/check-bitbucket-private.rb

Usage
---------------------
Flags:  
-a accountame - The account/group to check. Required.  
-e exclude_list - The list of repos you wish to exclude from being checked. Optional.  
-p api_password - The api password for the account to check. This can be found in your accounts settings page.
Flag is optional but required for using the -f flag when checking forks.  
-f true - Specify to check for public forks on private repos. Optional. When using, you must provide the -p flag.  
  
```
check-bitbucket-private.rb -a accountname [-e] comma-delimited,list-of,repos-to,exclude [-p] api_password [-f true]
```

License
---------------------
Released under the same terms as Sensu (the MIT license); see LICENSE
for details.
