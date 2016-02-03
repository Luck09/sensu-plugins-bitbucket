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
         long: '--account ACCOUNT',
         required: true

  option :exclude,
         description: 'Comma delimited list of repos to ignore',
         short: '-e REPO1,REPO2...',
         long: '--exclude REPO1,REPO2'

  option :password,
          description: 'The password of the account you are checking',
          short: '-p PASSWORD',
          long: '--password PASSWORD',
          default: ''

  option :checkforks,
          description: "Check if repos allow public forks",
          short: '-f',
          long: '--forks',
          default: false

  def run
    #Argument setup/parsing/checking
    cli = CheckBitbucketPrivate.new
    cli.parse_options
    account = cli.config[:account]
    exclude = cli.config[:exclude]

    if cli.config[:password]
      password = cli.config[:password]
    end

    check_forks = cli.config[:checkforks]

    if exclude and exclude.include?(',')
      exclude_list = exclude.split(',')
    elsif exclude
        exclude_list = [ exclude ]
    else
      exclude_list = ['']
    end

    #Repos are paginated so grab the data from each and put into a single array
    response=fetch_page("#{REPO_URL}/#{account}",account,password)
    data=JSON.parse(response)
    repo_data = data['values']
    while data['next']
      response=fetch_page(data['next'],account,password)
      data=JSON.parse(response)
      repo_data = repo_data + data['values']
    end

    #Iterate/process data
    found_public = false
    repos=""
    forks=""
    repo_data.each  do |repo|
      if repo['is_private'] == false and not exclude_list.include?(repo['name'])
        found_public = true
        repos += repo['name'] + " "
      end
      if repo['is_private'] and check_forks and repo['fork_policy'].include?('allow_forks')
        found_public = true
        forks += repo['name'] + " "
      end
    end

    #Report results
    if not found_public
      ok "No public repos found"
    elsif forks.length == 0
      critical "Found public repo(s): #{repos}"
    elsif repos.length == 0
      critical "Found public forks enabled on: #{forks}"
    else
      critical "Found public repo(s): #{repos} , Found public forks enabled on #{forks}"
    end
  end


  def fetch_page(request_url,account,password)
    uri = URI(request_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    if password.length > 1
      request.basic_auth(account, password)
    end

    response = http.request(request)
    if response.code.include?('429') #HTTP 429 too many requests
      warning 'Bitbucket rate limit has been exceeded'
    elsif response.code.include?('400') #HTTP 400 Bad request
      unknown 'Bad Request'
    elsif response.code.include?('401') #HTTP 401 Unathorized
      warning 'Unauthorized - Check your credentials'
    end

    return response.body
  end

end
