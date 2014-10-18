# author : @gntics
# description : jekyll plugins that exposes
#               github api datas through
#               site.data variable
# WARNING : this plugin uses unauthenticated requests to
#           access Github API so you are limited up to 60
#           requests per hour. Then it returns 403!
#           Authenticated requests get a higher rate limit,
#           you can make up to 5,000 requests per hour.

require 'octokit'

module Jekyll
  class GithubApiV3 < Jekyll::Generator

    def generate site
      # print_message "Jekyll Github Api plugin fetching datas..."

      @github_login = nil
      @github_user = nil
      @github_user_public_repos = nil

      begin
        # check presence of github.yml
        raise GithubConfigFileNotFound if !site.data.has_key? "github"
        github_hash = site.data["github"]
        # check presence of login
        raise GithubLoginNotFound if !github_hash.has_key? "login"
        @github_login = github_hash["login"]

        @github_user = get_github_user_infos @github_login
        site.data["github"]["user"] = @github_user.convert_key_to_s

        @github_user_public_repos = @github_user.rels[:repos].get.data.map { |elt| elt.convert_key_to_s }
        site.data["github"]["user_projects"] = @github_user_public_repos

        # print_message "Jekyll Github Api plugin done."

      rescue GithubConfigFileNotFound, GithubLoginNotFound => e
        print_message e.message
        exit -1
      rescue Octokit::NotFound => e
        print_message e.message
        exit -1
      end

    end

    private

    def print_message msg
      puts msg
    end

    def get_github_user_infos login
      # Octokit.user(login).class => Sawyer::Resource
      # WARNING: do not convert into hash with string keys yet, otherwise
      #          we loose access to the API through Sawyer::Resource
      #          and Sawyer::Relation.get
      #          X Octokit.user(login).convert_key_to_s
      Octokit.user(login)
    end

  end

  # Custom Error
  class GithubConfigFileNotFound < StandardError
    def message
      "Abort.\nGithubConfigFileNotFound: github.yml file not found in _data directory"
    end
  end

  # Custom Error
  class GithubLoginNotFound < StandardError
    def message
      "Abort.\nGithubLoginNotFound: no login found in _data/github.yml"
    end
  end

  # Extends existing class to provide convert method
  class Sawyer::Resource
    def convert_key_to_s
      hash = Hash.new
      self.attrs.each do |k,v|
        if v.is_a?(Sawyer::Resource)
          hash.store k.to_s, v.convert_key_to_s
        elsif v.is_a?(Array)
          hash.store k.to_s, v.map { |e| e.convert_key_to_s }
        else
          hash.store k.to_s, v
        end
      end
      return hash
    end
  end

end
