module Imap::Backup
  class Configuration; end

  class Configuration::List
    attr_reader :required_accounts

    def initialize(required_accounts = [])
      @required_accounts = required_accounts
    end

    def each_connection
      accounts.each do |account|
        connection = Account::Connection.new(account)
        yield connection
        connection.disconnect
      end
    end

    def accounts
      @accounts ||=
        if required_accounts.empty?
          config.accounts
        else
          config.accounts.select do |account|
            required_accounts.include?(account.username)
          end
        end
    end

    private

    def config
      @config ||= begin
        exists = Configuration.exist?
        if !exists
          path = Configuration.default_pathname
          raise ConfigurationNotFound, "Configuration file '#{path}' not found"
        end
        Configuration.new
      end
    end
  end
end
