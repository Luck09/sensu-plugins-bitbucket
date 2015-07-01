#! /usr/bin/env ruby
#
#   check-bitbucket-private
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#   gem: uri
#
# USAGE: -r reponame
#
# NOTES:
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'uri'
require 'net/http'

API_URL="https://bitbucket.org/api/2.0"
REPO_URL="#{API_URL}/repositories"

#
# Check for public bitbucket repos
#
class CheckBitbucketPrivate < Sensu::Plugin::Check::CLI
  option :account,
         description: 'The name of the account to check',
         short: '-a ACCOUNT',
         long: '--account'

  option :exclude,
         description: 'Comma delimited list of repos to ignore',
         short: '-e REPO1,REPO2...',
         long: '--exclude'
 
  def run
    #Argument setup/parsing/checking
    cli = CheckBitbucketPrivate.new
    cli.parse_options
    account = cli.config[:account]
    exclude = cli.config[:exclude]
    
    if not account
      warning 'No account specified'
    end

    if exclude
      exclude_list = exclude.split(',')
    else
      exclude_list = ['']
    end
    
    #Get the json data via API call and parse
    uri = URI.parse("#{REPO_URL}/#{account}")
    response = Net::HTTP.get_response(uri)
    if response.code.include?('429') #HTTP 429 too many requests 
      warning 'Bitbucket rate limit has been exceeded'
    end
    data=JSON.parse(response.body)

    #Iterate/process data
    found_public = false
    repos=""
    data['values'].each  do |child|
      if  not child['is_private'] and not exclude_list.include?(child['name'])
        found_public = true
        repos += child['name'] + " "
      end
    end

    #Report results
    if not found_public
      ok "No public repos found"
    else 
      critical "Found public repo(s): #{repos}"
    end
  end

end
