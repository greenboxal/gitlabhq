namespace :doggohub do
  namespace :env do
    desc "DoggoHub | Show information about DoggoHub and its environment"
    task info: :environment  do

      # check if there is an RVM environment
      rvm_version = run_and_match(%W(rvm --version), /[\d\.]+/).try(:to_s)
      # check Ruby version
      ruby_version = run_and_match(%W(ruby --version), /[\d\.p]+/).try(:to_s)
      # check Gem version
      gem_version = run_command(%W(gem --version))
      # check Bundler version
      bunder_version = run_and_match(%W(bundle --version), /[\d\.]+/).try(:to_s)
      # check Bundler version
      rake_version = run_and_match(%W(rake --version), /[\d\.]+/).try(:to_s)

      puts ""
      puts "System information".color(:yellow)
      puts "System:\t\t#{os_name || "unknown".color(:red)}"
      puts "Current User:\t#{run_command(%W(whoami))}"
      puts "Using RVM:\t#{rvm_version.present? ? "yes".color(:green) : "no"}"
      puts "RVM Version:\t#{rvm_version}" if rvm_version.present?
      puts "Ruby Version:\t#{ruby_version || "unknown".color(:red)}"
      puts "Gem Version:\t#{gem_version || "unknown".color(:red)}"
      puts "Bundler Version:#{bunder_version || "unknown".color(:red)}"
      puts "Rake Version:\t#{rake_version || "unknown".color(:red)}"
      puts "Sidekiq Version:#{Sidekiq::VERSION}"


      # check database adapter
      database_adapter = ActiveRecord::Base.connection.adapter_name.downcase

      project = Group.new(path: "some-group").projects.build(path: "some-project")
      # construct clone URLs
      http_clone_url = project.http_url_to_repo
      ssh_clone_url  = project.ssh_url_to_repo

      omniauth_providers = Gitlab.config.omniauth.providers
      omniauth_providers.map! { |provider| provider['name'] }

      puts ""
      puts "DoggoHub information".color(:yellow)
      puts "Version:\t#{Gitlab::VERSION}"
      puts "Revision:\t#{Gitlab::REVISION}"
      puts "Directory:\t#{Rails.root}"
      puts "DB Adapter:\t#{database_adapter}"
      puts "URL:\t\t#{Gitlab.config.doggohub.url}"
      puts "HTTP Clone URL:\t#{http_clone_url}"
      puts "SSH Clone URL:\t#{ssh_clone_url}"
      puts "Using LDAP:\t#{Gitlab.config.ldap.enabled ? "yes".color(:green) : "no"}"
      puts "Using Omniauth:\t#{Gitlab.config.omniauth.enabled ? "yes".color(:green) : "no"}"
      puts "Omniauth Providers: #{omniauth_providers.join(', ')}" if Gitlab.config.omniauth.enabled



      # check Gitolite version
      doggohub_shell_version_file = "#{Gitlab.config.doggohub_shell.hooks_path}/../VERSION"
      if File.readable?(doggohub_shell_version_file)
        doggohub_shell_version = File.read(doggohub_shell_version_file)
      end

      puts ""
      puts "DoggoHub Shell".color(:yellow)
      puts "Version:\t#{doggohub_shell_version || "unknown".color(:red)}"
      puts "Repository storage paths:"
      Gitlab.config.repositories.storages.each do |name, path|
        puts "- #{name}: \t#{path}"
      end
      puts "Hooks:\t\t#{Gitlab.config.doggohub_shell.hooks_path}"
      puts "Git:\t\t#{Gitlab.config.git.bin_path}"

    end
  end
end
